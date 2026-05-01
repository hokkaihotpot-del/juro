from __future__ import annotations

import hashlib
import itertools
import random
from dataclasses import dataclass, field
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.menu import MenuMaster
from app.models.menu_history import MenuHistory
from app.models.food import RecipeIngredient, FoodMaster
from app.models.user import NutritionLimit
from app.schemas.signal import DishCategory, MealType, TrafficLight
from app.services.correction import IngredientNutrient, calc_meal_nutrients
from app.services.signal import get_signal, get_daily_signals
from app.config import settings


@dataclass
class MenuCandidate:
    dish_id: str
    dish_name: str
    dish_category: str
    meal_type: str
    recipe_id: str | None
    ingredients: list[IngredientNutrient] = field(default_factory=list)
    phosphorus_mg: float = 0.0
    potassium_corrected_mg: float = 0.0
    sodium_g: float = 0.0
    water_ml: float = 0.0


@dataclass
class MealSet:
    """1食分（主食+主菜+副菜+汁物）"""
    meal_type: str
    dishes: list[MenuCandidate]
    phosphorus_mg: float = 0.0
    potassium_corrected_mg: float = 0.0
    sodium_g: float = 0.0
    water_ml: float = 0.0
    combination_hash: str = ""


def _build_combination_hash(dishes: list[MenuCandidate]) -> str:
    ids = sorted(d.dish_id for d in dishes)
    key = "|".join(ids)
    return hashlib.sha256(key.encode()).hexdigest()


def _sum_meal(dishes: list[MenuCandidate]) -> tuple[float, float, float, float]:
    p = sum(d.phosphorus_mg for d in dishes)
    k = sum(d.potassium_corrected_mg for d in dishes)
    na = sum(d.sodium_g for d in dishes)
    w = sum(d.water_ml for d in dishes)
    return p, k, na, w


class CSPMenuEngine:
    """制約充足型・重複回避付き献立生成エンジン（要件書 5.2）"""

    REQUIRED_CATEGORIES = [
        DishCategory.STAPLE,
        DishCategory.MAIN,
        DishCategory.SIDE,
        DishCategory.SOUP,
    ]
    MEAL_RATIOS = {
        MealType.BREAKFAST: 0.30,
        MealType.LUNCH: 0.35,
        MealType.DINNER: 0.35,
    }

    def __init__(
        self,
        db: AsyncSession,
        user_id: str,
        nutrition_limits: NutritionLimit,
        allergy_names: list[str],
        correction_enabled: bool,
    ):
        self.db = db
        self.user_id = user_id
        self.limits = nutrition_limits
        self.allergy_names_normalized = [n.lower() for n in allergy_names]
        self.correction_enabled = correction_enabled

    async def generate(self) -> dict[str, MealSet]:
        """朝・昼・夕の献立を生成して返す。フォールバック時は is_fallback=True"""
        avoid_days = settings.menu_duplicate_avoid_days
        recent_hashes = await self._get_recent_hashes(avoid_days)

        all_candidates = await self._load_candidates()
        filtered = self._apply_allergy_filter(all_candidates)

        result = {}
        is_fallback = False

        for meal_type in [MealType.BREAKFAST, MealType.LUNCH, MealType.DINNER]:
            ratio = self.MEAL_RATIOS[meal_type]
            p_limit = self.limits.phosphorus_limit_mg * ratio
            k_limit = self.limits.potassium_limit_mg * ratio
            na_limit = self.limits.sodium_limit_g * ratio
            w_limit = self.limits.water_limit_ml * ratio

            meal_candidates = [c for c in filtered if c.meal_type == meal_type]
            meal_set = self._find_valid_meal(
                meal_candidates, p_limit, k_limit, na_limit, w_limit, recent_hashes
            )

            if meal_set is None:
                is_fallback = True
                meal_set = self._find_valid_meal(
                    meal_candidates, p_limit, k_limit, na_limit, w_limit, set()
                )

            if meal_set is None:
                meal_set = self._fallback_meal(meal_candidates, meal_type)

            result[meal_type] = meal_set

        return result, is_fallback

    def _apply_allergy_filter(self, candidates: list[MenuCandidate]) -> list[MenuCandidate]:
        """アレルギー除外（ハード制約・最優先）"""
        if not self.allergy_names_normalized:
            return candidates
        safe = []
        for c in candidates:
            ing_names = [i.ingredient_name.lower() for i in c.ingredients]
            if not any(a in n for a in self.allergy_names_normalized for n in ing_names):
                safe.append(c)
        return safe

    def _find_valid_meal(
        self,
        candidates: list[MenuCandidate],
        p_limit: float,
        k_limit: float,
        na_limit: float,
        w_limit: float,
        avoid_hashes: set[str],
    ) -> MealSet | None:
        by_cat: dict[str, list[MenuCandidate]] = {c: [] for c in self.REQUIRED_CATEGORIES}
        for cand in candidates:
            if cand.dish_category in by_cat:
                by_cat[cand.dish_category].append(cand)

        if any(len(v) == 0 for v in by_cat.values()):
            return None

        for cat in by_cat:
            random.shuffle(by_cat[cat])

        for combo in itertools.product(*by_cat.values()):
            combo_list = list(combo)
            p, k, na, w = _sum_meal(combo_list)
            if p > p_limit or k > k_limit or na > na_limit or w > w_limit:
                continue
            h = _build_combination_hash(combo_list)
            if h in avoid_hashes:
                continue
            return self._make_meal_set(combo_list, h)

        return None

    def _fallback_meal(
        self, candidates: list[MenuCandidate], meal_type: str
    ) -> MealSet:
        by_cat: dict[str, list[MenuCandidate]] = {c: [] for c in self.REQUIRED_CATEGORIES}
        for cand in candidates:
            if cand.dish_category in by_cat:
                by_cat[cand.dish_category].append(cand)
        best = [random.choice(v) if v else None for v in by_cat.values()]
        dishes = [d for d in best if d is not None]
        h = _build_combination_hash(dishes)
        return self._make_meal_set(dishes, h)

    def _make_meal_set(self, dishes: list[MenuCandidate], hash_: str) -> MealSet:
        p, k, na, w = _sum_meal(dishes)
        return MealSet(
            meal_type=dishes[0].meal_type if dishes else "",
            dishes=dishes,
            phosphorus_mg=p,
            potassium_corrected_mg=k,
            sodium_g=na,
            water_ml=w,
            combination_hash=hash_,
        )

    async def _get_recent_hashes(self, days: int) -> set[str]:
        cutoff = date.today() - timedelta(days=days)
        result = await self.db.execute(
            select(MenuHistory.combination_hash).where(
                MenuHistory.user_id == self.user_id,
                MenuHistory.menu_date >= cutoff,
            )
        )
        return set(result.scalars().all())

    async def _load_candidates(self) -> list[MenuCandidate]:
        result = await self.db.execute(
            select(MenuMaster).where(MenuMaster.is_active.is_(True))
        )
        menu_masters = result.scalars().all()

        candidates = []
        for mm in menu_masters:
            ingredients: list[IngredientNutrient] = []
            if mm.recipe_id:
                ri_result = await self.db.execute(
                    select(RecipeIngredient, FoodMaster)
                    .join(FoodMaster, RecipeIngredient.food_id == FoodMaster.id)
                    .where(RecipeIngredient.recipe_id == mm.recipe_id)
                )
                for ri, food in ri_result.all():
                    ingredients.append(
                        IngredientNutrient(
                            food_id=food.id,
                            ingredient_name=food.food_name,
                            weight_g=ri.weight_g,
                            phosphorus_per100g=food.phosphorus_per100g,
                            potassium_per100g=food.potassium_per100g,
                            sodium_per100g=food.sodium_per100g,
                            water_per100g=food.water_per100g,
                            cooking_yield_rate=food.cooking_yield_rate,
                            vegetable_category=food.vegetable_category,
                        )
                    )

            meal_nutrients = calc_meal_nutrients(ingredients, self.correction_enabled)
            candidates.append(
                MenuCandidate(
                    dish_id=mm.id,
                    dish_name=mm.dish_name,
                    dish_category=mm.dish_category,
                    meal_type=mm.meal_type,
                    recipe_id=mm.recipe_id,
                    ingredients=ingredients,
                    phosphorus_mg=meal_nutrients.phosphorus_mg,
                    potassium_corrected_mg=meal_nutrients.potassium_corrected_mg,
                    sodium_g=meal_nutrients.sodium_g,
                    water_ml=meal_nutrients.water_ml,
                )
            )
        return candidates
