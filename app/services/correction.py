from __future__ import annotations

from dataclasses import dataclass

from app.schemas.signal import VegetableCategory, PreprocessingMethod

# 要件書 5.1 補正係数テーブル
ALPHA_TABLE: dict[tuple[str, str], float] = {
    (VegetableCategory.LEAFY, PreprocessingMethod.BOIL): 0.55,
    (VegetableCategory.LEAFY, PreprocessingMethod.SOAK): 0.75,
    (VegetableCategory.ROOT, PreprocessingMethod.BOIL): 0.45,
    (VegetableCategory.ROOT, PreprocessingMethod.SOAK): 0.65,
    (VegetableCategory.OTHER, PreprocessingMethod.NONE): 1.00,
}

# デフォルト下処理方法（茹でこぼしを推奨）
DEFAULT_PREPROCESSING: dict[str, str] = {
    VegetableCategory.LEAFY: PreprocessingMethod.BOIL,
    VegetableCategory.ROOT: PreprocessingMethod.BOIL,
    VegetableCategory.OTHER: PreprocessingMethod.NONE,
}


def get_alpha(
    category: str | None,
    method: str | None = None,
) -> float:
    """補正係数 α を取得する。

    category が None / other かつ method が指定されない場合は 1.0 を返す。
    """
    if category is None or category == VegetableCategory.OTHER:
        return 1.0
    effective_method = method or DEFAULT_PREPROCESSING.get(category, PreprocessingMethod.NONE)
    return ALPHA_TABLE.get((category, effective_method), 1.0)


def calc_k_corrected(
    k_raw_per100g: float,
    weight_g: float,
    category: str | None,
    method: str | None = None,
    correction_enabled: bool = True,
) -> float:
    """要件書 5.1 核心計算式:
    K_corrected(i) = K_raw(i) × α(category_i, method_i)
    K_meal_contribution = K_corrected(i) × weight_i / 100
    """
    if not correction_enabled:
        alpha = 1.0
    else:
        alpha = get_alpha(category, method)
    return k_raw_per100g * alpha * weight_g / 100.0


@dataclass
class IngredientNutrient:
    food_id: str
    ingredient_name: str
    weight_g: float
    phosphorus_per100g: float
    potassium_per100g: float
    sodium_per100g: float
    water_per100g: float = 0.0
    cooking_yield_rate: float = 1.0
    vegetable_category: str | None = None
    preprocessing_method: str | None = None


@dataclass
class MealNutrients:
    phosphorus_mg: float
    potassium_raw_mg: float
    potassium_corrected_mg: float
    sodium_g: float
    water_ml: float
    per_ingredient: list[dict]


def calc_water_ml(
    water_per100g: float,
    weight_g: float,
    cooking_yield_rate: float = 1.0,
) -> float:
    """要件書 3.2.7 水分量算出:
    食材 i の水分量 = water_per100g × weight_g / 100 × cooking_yield_rate
    cooking_yield_rate は文部科学省 食品成分表 表15 の重量変化率（加熱で水分蒸発分を差し引く）
    """
    return water_per100g * weight_g / 100.0 * cooking_yield_rate


def calc_meal_nutrients(
    ingredients: list[IngredientNutrient],
    correction_enabled: bool = True,
) -> MealNutrients:
    """食材リストから1食分の P / K(補正済み) / Na / 水分 を合計する。

    要件書 5.1 + 3.2.7:
      P_meal    = Σ [ P_raw(i) × weight_i / 100 ]
      K_meal    = Σ [ K_raw(i) × α(category_i, method_i) × weight_i / 100 ]
      Na_meal   = Σ [ Na_raw(i) × weight_i / 100 ]
      W_meal    = Σ [ water_per100g(i) × weight_i / 100 × yield_rate(i) ]
    """
    p_total = 0.0
    k_raw_total = 0.0
    k_corrected_total = 0.0
    na_total = 0.0
    water_total = 0.0
    per_ingredient = []

    for ing in ingredients:
        p = ing.phosphorus_per100g * ing.weight_g / 100.0
        k_raw = ing.potassium_per100g * ing.weight_g / 100.0
        k_corr = calc_k_corrected(
            ing.potassium_per100g,
            ing.weight_g,
            ing.vegetable_category,
            ing.preprocessing_method,
            correction_enabled,
        )
        na = ing.sodium_per100g * ing.weight_g / 100.0
        water = calc_water_ml(ing.water_per100g, ing.weight_g, ing.cooking_yield_rate)

        p_total += p
        k_raw_total += k_raw
        k_corrected_total += k_corr
        na_total += na
        water_total += water

        per_ingredient.append(
            {
                "food_id": ing.food_id,
                "ingredient_name": ing.ingredient_name,
                "weight_g": ing.weight_g,
                "phosphorus_mg": round(p, 2),
                "potassium_raw_mg": round(k_raw, 2),
                "potassium_corrected_mg": round(k_corr, 2),
                "sodium_g": round(na, 4),
                "water_ml": round(water, 2),
                "alpha": get_alpha(ing.vegetable_category, ing.preprocessing_method)
                if correction_enabled
                else 1.0,
            }
        )

    return MealNutrients(
        phosphorus_mg=round(p_total, 2),
        potassium_raw_mg=round(k_raw_total, 2),
        potassium_corrected_mg=round(k_corrected_total, 2),
        sodium_g=round(na_total, 4),
        water_ml=round(water_total, 2),
        per_ingredient=per_ingredient,
    )
