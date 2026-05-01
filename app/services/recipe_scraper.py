from __future__ import annotations

import re

import httpx
from bs4 import BeautifulSoup
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.food import FoodMaster, RecipeIngredient, RecipeMaster
from app.models.base import new_uuid


def _normalize_name(name: str) -> str:
    return name.strip().lower().replace("　", " ")


def _parse_weight(text: str) -> float:
    """分量テキストからグラム数を推定する"""
    text = text.strip()
    match = re.search(r"(\d+(?:\.\d+)?)\s*g", text)
    if match:
        return float(match.group(1))
    match = re.search(r"(\d+(?:\.\d+)?)\s*kg", text)
    if match:
        return float(match.group(1)) * 1000
    # 個・枚・本など単位のある場合はデフォルト100g
    return 100.0


class RecipeScraper:
    """デリッシュキッチン レシピ取得・キャッシュ（要件書 3.2.2）"""

    BASE_SEARCH_URL = "https://delishkitchen.tv/search?q={query}"
    HEADERS = {"User-Agent": settings.recipe_scraper_user_agent}

    def __init__(self, db: AsyncSession):
        self.db = db

    async def fetch_and_cache(self, dish_name: str) -> RecipeMaster | None:
        normalized = _normalize_name(dish_name)

        existing = await self.db.execute(
            select(RecipeMaster).where(RecipeMaster.dish_name_normalized == normalized)
        )
        cached = existing.scalar_one_or_none()
        if cached:
            return cached

        try:
            async with httpx.AsyncClient(headers=self.HEADERS, timeout=10.0) as client:
                search_url = self.BASE_SEARCH_URL.format(query=dish_name)
                resp = await client.get(search_url)
                resp.raise_for_status()
                recipe_url = self._extract_first_recipe_url(resp.text, search_url)
                if not recipe_url:
                    return None
                recipe_resp = await client.get(recipe_url)
                recipe_resp.raise_for_status()
                raw_ingredients = self._parse_ingredients(recipe_resp.text)
        except Exception:
            return None

        if not raw_ingredients:
            return None

        recipe = RecipeMaster(
            id=new_uuid(),
            dish_name=dish_name,
            dish_name_normalized=normalized,
            source_url=recipe_url,
        )
        self.db.add(recipe)
        await self.db.flush()

        for ing_name, weight_g in raw_ingredients:
            food = await self._find_food(ing_name)
            if food is None:
                continue
            ri = RecipeIngredient(
                id=new_uuid(),
                recipe_id=recipe.id,
                food_id=food.id,
                weight_g=weight_g,
            )
            self.db.add(ri)

        await self.db.flush()
        return recipe

    def _extract_first_recipe_url(self, html: str, base_url: str) -> str | None:
        soup = BeautifulSoup(html, "html.parser")
        link = soup.select_one("a[href*='/recipes/']")
        if link:
            href = link.get("href", "")
            if href.startswith("http"):
                return href
            return "https://delishkitchen.tv" + href
        return None

    def _parse_ingredients(self, html: str) -> list[tuple[str, float]]:
        soup = BeautifulSoup(html, "html.parser")
        results = []
        ingredient_items = soup.select(".ingredient-name, .recipe-ingredient-item, li.ingredient")
        for item in ingredient_items:
            name_el = item.select_one(".name, .ingredient-name")
            qty_el = item.select_one(".quantity, .ingredient-quantity")
            if name_el:
                name = name_el.get_text(strip=True)
                qty_text = qty_el.get_text(strip=True) if qty_el else "100g"
                weight = _parse_weight(qty_text)
                if name:
                    results.append((name, weight))
        return results

    async def _find_food(self, ingredient_name: str) -> FoodMaster | None:
        normalized = _normalize_name(ingredient_name)
        result = await self.db.execute(
            select(FoodMaster).where(FoodMaster.food_name_normalized == normalized)
        )
        food = result.scalar_one_or_none()
        if food:
            return food
        # ファジーマッチング（部分一致）
        result = await self.db.execute(
            select(FoodMaster).where(FoodMaster.food_name_normalized.contains(normalized[:4]))
        )
        return result.scalars().first()
