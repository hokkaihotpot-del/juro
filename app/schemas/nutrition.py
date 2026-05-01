from __future__ import annotations

from pydantic import BaseModel

from app.schemas.signal import TrafficLight, DishCategory, MealType


class IngredientSignal(BaseModel):
    """食材カード（クライアント向け）- 生値・補正係数は含めない"""
    ingredient_name: str
    weight_g: float
    signal_color: TrafficLight
    has_allergy_warning: bool = False
    preprocessing_note: str | None = None


class DishSignal(BaseModel):
    """1品の情報（クライアント向け）"""
    dish_name: str
    dish_category: DishCategory
    overall_signal: TrafficLight
    ingredients: list[IngredientSignal]
    allergy_warning: str | None = None


class MealSignal(BaseModel):
    """1食分のシグナル集計"""
    meal_type: MealType
    dishes: list[DishSignal]
    phosphorus_signal: TrafficLight
    potassium_signal: TrafficLight
    sodium_signal: TrafficLight


class NutritionAnalyzeRequest(BaseModel):
    """音声認識後のテキストを受け取るリクエスト"""
    dish_name: str
    meal_type: MealType = MealType.LUNCH


class NutritionAnalyzeResponse(BaseModel):
    """栄養素計算結果（信号色のみ返す）"""
    dish_name: str
    dish_name_normalized: str
    meal_type: MealType
    phosphorus_signal: TrafficLight
    potassium_signal: TrafficLight
    sodium_signal: TrafficLight
    water_signal: TrafficLight
    water_ml: float = 0.0
    ingredients: list[IngredientSignal]
    allergy_warnings: list[str] = []


class IngredientAdvice(BaseModel):
    """赤食材タップ時の助言"""
    ingredient_name: str
    exceeded_nutrients: list[str]
    alternative_ingredients: list[str]
    cooking_tips: list[str]
    preprocessing_note: str | None = None
