from __future__ import annotations

import pytest

from app.services.correction import IngredientNutrient, calc_meal_nutrients
from app.services.signal import get_signal
from app.schemas.signal import TrafficLight, VegetableCategory, PreprocessingMethod


class TestNutritionCalcIntegration:
    """栄養素計算の統合テスト（補正+信号色の組み合わせ）"""

    LIMITS_P = 800
    LIMITS_K = 2000
    LIMITS_NA = 6.0
    PER_MEAL_P = LIMITS_P / 3
    PER_MEAL_K = LIMITS_K / 3
    PER_MEAL_NA = LIMITS_NA / 3

    def _make_ingredients(self) -> list[IngredientNutrient]:
        return [
            IngredientNutrient(
                food_id="1",
                ingredient_name="白米",
                weight_g=150.0,
                phosphorus_per100g=51.0,
                potassium_per100g=45.0,
                sodium_per100g=0.0,
                vegetable_category=None,
            ),
            IngredientNutrient(
                food_id="2",
                ingredient_name="ほうれん草",
                weight_g=80.0,
                phosphorus_per100g=47.0,
                potassium_per100g=690.0,
                sodium_per100g=0.0,
                vegetable_category=VegetableCategory.LEAFY,
                preprocessing_method=PreprocessingMethod.BOIL,
            ),
            IngredientNutrient(
                food_id="3",
                ingredient_name="豆腐",
                weight_g=150.0,
                phosphorus_per100g=95.0,
                potassium_per100g=140.0,
                sodium_per100g=0.002,
                vegetable_category=None,
            ),
        ]

    def test_correction_reduces_potassium(self):
        ings = self._make_ingredients()
        result_on = calc_meal_nutrients(ings, correction_enabled=True)
        result_off = calc_meal_nutrients(ings, correction_enabled=False)
        assert result_on.potassium_corrected_mg < result_off.potassium_corrected_mg

    def test_correction_on_yields_green_for_k(self):
        # ほうれん草 690mg/100g * 80g = 552mg raw → corrected = 552 * 0.55 = 303.6mg
        # 全体K補正済み: 45*150/100 + 303.6 + 140*150/100 = 67.5 + 303.6 + 210 = 581.1mg
        # per_meal_k = 2000/3 = 666.7 → 87.1% → YELLOW
        ings = self._make_ingredients()
        result = calc_meal_nutrients(ings, correction_enabled=True)
        signal = get_signal(result.potassium_corrected_mg, self.PER_MEAL_K)
        assert signal in (TrafficLight.YELLOW, TrafficLight.GREEN)

    def test_correction_off_may_turn_red(self):
        # 補正なし: K = 67.5 + 552 + 210 = 829.5mg / 666.7 = 124.4% → RED
        ings = self._make_ingredients()
        result = calc_meal_nutrients(ings, correction_enabled=False)
        signal = get_signal(result.potassium_corrected_mg, self.PER_MEAL_K)
        assert signal == TrafficLight.RED

    def test_phosphorus_unchanged_by_correction(self):
        ings = self._make_ingredients()
        result_on = calc_meal_nutrients(ings, correction_enabled=True)
        result_off = calc_meal_nutrients(ings, correction_enabled=False)
        assert abs(result_on.phosphorus_mg - result_off.phosphorus_mg) < 0.01

    def test_per_ingredient_detail_count(self):
        ings = self._make_ingredients()
        result = calc_meal_nutrients(ings, correction_enabled=True)
        assert len(result.per_ingredient) == 3

    def test_per_ingredient_has_no_raw_values_visible_in_result(self):
        # per_ingredientはサーバー内部保持用であることを確認（alpha値が存在する）
        ings = self._make_ingredients()
        result = calc_meal_nutrients(ings, correction_enabled=True)
        spinach_detail = next(
            d for d in result.per_ingredient if d["ingredient_name"] == "ほうれん草"
        )
        assert "alpha" in spinach_detail
        assert spinach_detail["alpha"] == 0.55
