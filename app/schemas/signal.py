from __future__ import annotations

from enum import Enum


class TrafficLight(str, Enum):
    GREEN = "green"
    YELLOW = "yellow"
    RED = "red"


class MealType(str, Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"


class DishCategory(str, Enum):
    STAPLE = "staple"
    MAIN = "main"
    SIDE = "side"
    SOUP = "soup"


class VegetableCategory(str, Enum):
    LEAFY = "leafy"
    ROOT = "root"
    OTHER = "other"


class PreprocessingMethod(str, Enum):
    BOIL = "boil"
    SOAK = "soak"
    NONE = "none"
