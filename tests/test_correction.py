from __future__ import annotations

import pytest

from app.services.correction import (
    ALPHA_TABLE,
    calc_k_corrected,
    calc_meal_nutrients,
    get_alpha,
    IngredientNutrient,
)
from app.schemas.signal import PreprocessingMethod, VegetableCategory


class TestAlphaTable:
    def test_leafy_boil(self):
        assert get_alpha(VegetableCategory.LEAFY, PreprocessingMethod.BOIL) == 0.55

    def test_leafy_soak(self):
        assert get_alpha(VegetableCategory.LEAFY, PreprocessingMethod.SOAK) == 0.75

    def test_root_boil(self):
        assert get_alpha(VegetableCategory.ROOT, PreprocessingMethod.BOIL) == 0.45

    def test_root_soak(self):
        assert get_alpha(VegetableCategory.ROOT, PreprocessingMethod.SOAK) == 0.65

    def test_other_none(self):
        assert get_alpha(VegetableCategory.OTHER, PreprocessingMethod.NONE) == 1.0

    def test_none_category(self):
        assert get_alpha(None) == 1.0

    def test_unknown_combination_defaults_to_1(self):
        assert get_alpha("leafy", "unknown_method") == 1.0


class TestCalcKCorrected:
    def test_leafy_boil_correction(self):
        # K_raw=500mg/100g, weight=80g, leafy, boil → 500 * 0.55 * 80/100 = 220
        result = calc_k_corrected(500.0, 80.0, VegetableCategory.LEAFY, PreprocessingMethod.BOIL, True)
        assert abs(result - 220.0) < 0.01

    def test_root_boil_correction(self):
        # K_raw=400mg/100g, weight=100g, root, boil → 400 * 0.45 * 100/100 = 180
        result = calc_k_corrected(400.0, 100.0, VegetableCategory.ROOT, PreprocessingMethod.BOIL, True)
        assert abs(result - 180.0) < 0.01

    def test_correction_disabled(self):
        # correction_enabled=False → α=1.0, K_raw=500 * 1.0 * 80/100 = 400
        result = calc_k_corrected(500.0, 80.0, VegetableCategory.LEAFY, PreprocessingMethod.BOIL, False)
        assert abs(result - 400.0) < 0.01

    def test_zero_weight(self):
        result = calc_k_corrected(500.0, 0.0, VegetableCategory.LEAFY, PreprocessingMethod.BOIL, True)
        assert result == 0.0

    def test_non_vegetable(self):
        # 野菜でない食材 → α=1.0
        result = calc_k_corrected(300.0, 150.0, None, None, True)
        assert abs(result - 450.0) < 0.01


class TestCalcMealNutrients:
    def _make_ingredient(
        self,
        name: str = "test",
        weight: float = 100.0,
        p: float = 0.0,
        k: float = 0.0,
        na: float = 0.0,
        category=None,
        method=None,
    ) -> IngredientNutrient:
        return IngredientNutrient(
            food_id="test-id",
            ingredient_name=name,
            weight_g=weight,
            phosphorus_per100g=p,
            potassium_per100g=k,
            sodium_per100g=na,
            vegetable_category=category,
            preprocessing_method=method,
        )

    def test_single_leafy_with_correction(self):
        # ほうれん草：K=690mg/100g, 100g, leafy, boil → K_corrected = 690 * 0.55 = 379.5
        ing = self._make_ingredient(
            name="ほうれん草", weight=100.0, k=690.0,
            category=VegetableCategory.LEAFY, method=PreprocessingMethod.BOIL,
        )
        result = calc_meal_nutrients([ing], correction_enabled=True)
        assert abs(result.potassium_corrected_mg - 379.5) < 0.1
        assert abs(result.potassium_raw_mg - 690.0) < 0.1

    def test_phosphorus_no_correction(self):
        # P は補正なし
        ing = self._make_ingredient(name="ほうれん草", weight=100.0, p=47.0, k=690.0,
                                    category=VegetableCategory.LEAFY)
        result = calc_meal_nutrients([ing], correction_enabled=True)
        assert abs(result.phosphorus_mg - 47.0) < 0.1

    def test_multiple_ingredients(self):
        ings = [
            self._make_ingredient("白米", weight=150.0, p=51.0, k=45.0, na=0.0),
            self._make_ingredient("ほうれん草", weight=80.0, k=690.0, p=47.0,
                                  category=VegetableCategory.LEAFY, method=PreprocessingMethod.BOIL),
        ]
        result = calc_meal_nutrients(ings, correction_enabled=True)
        expected_p = 51.0 * 150.0 / 100 + 47.0 * 80.0 / 100
        expected_k_corr = 45.0 * 150.0 / 100 + 690.0 * 0.55 * 80.0 / 100
        assert abs(result.phosphorus_mg - expected_p) < 0.1
        assert abs(result.potassium_corrected_mg - expected_k_corr) < 0.1

    def test_empty_ingredients(self):
        result = calc_meal_nutrients([], correction_enabled=True)
        assert result.phosphorus_mg == 0.0
        assert result.potassium_corrected_mg == 0.0
        assert result.sodium_g == 0.0

    def test_correction_disabled_uses_raw(self):
        ing = self._make_ingredient(
            name="にんじん", weight=100.0, k=300.0,
            category=VegetableCategory.ROOT, method=PreprocessingMethod.BOIL,
        )
        result_on = calc_meal_nutrients([ing], correction_enabled=True)
        result_off = calc_meal_nutrients([ing], correction_enabled=False)
        assert result_off.potassium_corrected_mg > result_on.potassium_corrected_mg
        assert abs(result_off.potassium_corrected_mg - 300.0) < 0.1
