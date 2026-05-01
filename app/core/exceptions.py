from __future__ import annotations

from fastapi import HTTPException, status


class AllergyConflictError(HTTPException):
    def __init__(self, allergens: list[str]):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "ALLERGY_CONFLICT", "allergens": allergens},
        )


class NutritionLimitExceededError(HTTPException):
    def __init__(self, nutrients: list[str]):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "NUTRITION_LIMIT_EXCEEDED", "nutrients": nutrients},
        )


class MenuCandidateExhaustedError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": "MENU_CANDIDATE_EXHAUSTED"},
        )


class RecipeNotFoundError(HTTPException):
    def __init__(self, dish_name: str):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RECIPE_NOT_FOUND", "dish_name": dish_name},
        )
