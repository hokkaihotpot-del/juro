from __future__ import annotations

from pydantic import BaseModel

from app.schemas.signal import TrafficLight, MealType, DishCategory


class DishProposal(BaseModel):
    """1品の提案"""
    dish_name: str
    dish_category: DishCategory
    signal_color: TrafficLight
    water_ml: float = 0.0


class MealProposal(BaseModel):
    """1食の提案（4品構成）"""
    meal_type: MealType
    dishes: list[DishProposal]
    phosphorus_signal: TrafficLight
    potassium_signal: TrafficLight
    sodium_signal: TrafficLight
    water_signal: TrafficLight
    water_ml: float = 0.0


class DailyMenuProposal(BaseModel):
    """1日の献立提案"""
    breakfast: MealProposal
    lunch: MealProposal
    dinner: MealProposal
    daily_phosphorus_signal: TrafficLight
    daily_potassium_signal: TrafficLight
    daily_sodium_signal: TrafficLight
    daily_water_signal: TrafficLight
    is_fallback: bool = False
