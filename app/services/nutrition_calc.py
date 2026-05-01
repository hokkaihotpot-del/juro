from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.allergy import AllergyItem
from app.models.food import FoodMaster, RecipeIngredient, RecipeMaster
from app.models.nutrition_log import NutritionLog
from app.models.user import NutritionLimit
from app.schemas.nutrition import IngredientAdvice, IngredientSignal, NutritionAnalyzeResponse
from app.schemas.signal import MealType, TrafficLight
from app.services.correction import IngredientNutrient, calc_meal_nutrients
from app.services.signal import get_signal


def _normalize_dish_name(name: str) -> str:
    return name.strip().lower().replace("　", " ")


class NutritionCalculator:
    """音声入力された料理名から信号色を計算するサービス"""

    def __init__(
        self,
        db: AsyncSession,
        user_id: str,
        limits: NutritionLimit,
        correction_enabled: bool,
    ):
        self.db = db
        self.user_id = user_id
        self.limits = limits
        self.correction_enabled = correction_enabled

    async def analyze(self, dish_name: str, meal_type: MealType) -> NutritionAnalyzeResponse:
        normalized = _normalize_dish_name(dish_name)

        recipe = await self._find_cached_recipe(normalized)
        if recipe is None:
            from app.services.recipe_scraper import RecipeScraper
            scraper = RecipeScraper(self.db)
            recipe = await scraper.fetch_and_cache(dish_name)

        if recipe is None:
            return NutritionAnalyzeResponse(
                dish_name=dish_name,
                dish_name_normalized=normalized,
                meal_type=meal_type,
                phosphorus_signal=TrafficLight.GREEN,
                potassium_signal=TrafficLight.GREEN,
                sodium_signal=TrafficLight.GREEN,
                water_signal=TrafficLight.GREEN,
                water_ml=0.0,
                ingredients=[],
                allergy_warnings=[],
            )

        ingredients = await self._load_ingredients(recipe.id)
        meal_nutrients = calc_meal_nutrients(ingredients, self.correction_enabled)

        per_meal_p = self.limits.phosphorus_limit_mg / 3
        per_meal_k = self.limits.potassium_limit_mg / 3
        per_meal_na = self.limits.sodium_limit_g / 3
        per_meal_w = self.limits.water_limit_ml / 3

        allergy_names = await self._get_allergy_names()
        allergy_set = {a.lower() for a in allergy_names}

        ingredient_signals = []
        for detail in meal_nutrients.per_ingredient:
            ing_name = detail["ingredient_name"]
            ing_k = detail["potassium_corrected_mg"]
            ing_p = detail["phosphorus_mg"]
            ing_na = detail["sodium_g"]

            ing_signal = max(
                get_signal(ing_p, per_meal_p),
                get_signal(ing_k, per_meal_k),
                get_signal(ing_na, per_meal_na),
                key=lambda s: {TrafficLight.GREEN: 0, TrafficLight.YELLOW: 1, TrafficLight.RED: 2}[s],
            )
            has_allergy = ing_name.lower() in allergy_set

            preprocessing_note = None
            if self.correction_enabled and detail.get("alpha", 1.0) < 1.0:
                preprocessing_note = "茹でこぼし後の推定値"

            ingredient_signals.append(
                IngredientSignal(
                    ingredient_name=ing_name,
                    weight_g=detail["weight_g"],
                    signal_color=ing_signal,
                    has_allergy_warning=has_allergy,
                    preprocessing_note=preprocessing_note,
                )
            )

        allergy_warnings = [s.ingredient_name for s in ingredient_signals if s.has_allergy_warning]

        p_signal = get_signal(meal_nutrients.phosphorus_mg, per_meal_p)
        k_signal = get_signal(meal_nutrients.potassium_corrected_mg, per_meal_k)
        na_signal = get_signal(meal_nutrients.sodium_g, per_meal_na)
        w_signal = get_signal(meal_nutrients.water_ml, per_meal_w)

        return NutritionAnalyzeResponse(
            dish_name=recipe.dish_name,
            dish_name_normalized=normalized,
            meal_type=meal_type,
            phosphorus_signal=p_signal,
            potassium_signal=k_signal,
            sodium_signal=na_signal,
            water_signal=w_signal,
            water_ml=meal_nutrients.water_ml,
            ingredients=ingredient_signals,
            allergy_warnings=allergy_warnings,
        )

    async def get_ingredient_advice(self, food_id: str) -> IngredientAdvice:
        result = await self.db.execute(select(FoodMaster).where(FoodMaster.id == food_id))
        food = result.scalar_one_or_none()
        if food is None:
            return IngredientAdvice(
                ingredient_name="不明",
                exceeded_nutrients=[],
                alternative_ingredients=[],
                cooking_tips=[],
            )

        per_meal_p = self.limits.phosphorus_limit_mg / 3
        per_meal_k = self.limits.potassium_limit_mg / 3
        per_meal_na = self.limits.sodium_limit_g / 3

        exceeded = []
        if food.phosphorus_per100g > per_meal_p * 0.5:
            exceeded.append("リン")
        if food.potassium_per100g > per_meal_k * 0.5:
            exceeded.append("カリウム")
        if food.sodium_per100g > per_meal_na * 0.3:
            exceeded.append("塩分")

        alternatives = await self._find_alternatives(food)
        tips = _build_cooking_tips(food, exceeded)

        return IngredientAdvice(
            ingredient_name=food.food_name,
            exceeded_nutrients=exceeded,
            alternative_ingredients=alternatives,
            cooking_tips=tips,
            preprocessing_note="茹でこぼし（15分）でカリウムを約55%低減できます"
            if "カリウム" in exceeded and food.vegetable_category in ("leafy", "root")
            else None,
        )

    async def _find_cached_recipe(self, normalized_name: str) -> RecipeMaster | None:
        result = await self.db.execute(
            select(RecipeMaster).where(
                RecipeMaster.dish_name_normalized == normalized_name
            )
        )
        return result.scalar_one_or_none()

    async def _load_ingredients(self, recipe_id: str) -> list[IngredientNutrient]:
        result = await self.db.execute(
            select(RecipeIngredient, FoodMaster)
            .join(FoodMaster, RecipeIngredient.food_id == FoodMaster.id)
            .where(RecipeIngredient.recipe_id == recipe_id)
        )
        return [
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
            for ri, food in result.all()
        ]

    async def _get_allergy_names(self) -> list[str]:
        result = await self.db.execute(
            select(AllergyItem.ingredient_name).where(AllergyItem.user_id == self.user_id)
        )
        return result.scalars().all()

    async def _find_alternatives(self, food: FoodMaster) -> list[str]:
        result = await self.db.execute(
            select(FoodMaster.food_name)
            .where(
                FoodMaster.vegetable_category == food.vegetable_category,
                FoodMaster.id != food.id,
                FoodMaster.potassium_per100g < food.potassium_per100g * 0.7,
                FoodMaster.phosphorus_per100g < food.phosphorus_per100g * 0.7,
            )
            .limit(3)
        )
        return result.scalars().all()


def _build_cooking_tips(food: FoodMaster, exceeded: list[str]) -> list[str]:
    tips = []
    if "カリウム" in exceeded:
        if food.vegetable_category == "leafy":
            tips.append("沸騰したお湯で5分間茹で、湯を捨てるとカリウムが約45%低減します")
        elif food.vegetable_category == "root":
            tips.append("薄切りにして15分間茹で、湯を捨てるとカリウムが約55%低減します")
        tips.append("細かく切って水にさらす時間を長くするほど効果的です")
    if "リン" in exceeded:
        tips.append("使用量を通常の半量に減らすことを検討してください")
        tips.append("リン含有量の少ない代替食材への変更をご検討ください")
    if "塩分" in exceeded:
        tips.append("だし・香辛料を活用して塩分を減らした調理法をお試しください")
    return tips
