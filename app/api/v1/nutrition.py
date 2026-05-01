from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.nutrition import IngredientAdvice, NutritionAnalyzeRequest, NutritionAnalyzeResponse
from app.services.nutrition_calc import NutritionCalculator

router = APIRouter(prefix="/nutrition", tags=["nutrition"])


@router.post("/analyze", response_model=NutritionAnalyzeResponse)
async def analyze_dish(
    body: NutritionAnalyzeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = UserRepository(db)
    limits = await repo.get_nutrition_limit(current_user.id)

    calc = NutritionCalculator(
        db=db,
        user_id=current_user.id,
        limits=limits,
        correction_enabled=current_user.preprocessing_correction_enabled,
    )
    return await calc.analyze(body.dish_name, body.meal_type)


@router.get("/ingredient/{food_id}/advice", response_model=IngredientAdvice)
async def get_ingredient_advice(
    food_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = UserRepository(db)
    limits = await repo.get_nutrition_limit(current_user.id)

    calc = NutritionCalculator(
        db=db,
        user_id=current_user.id,
        limits=limits,
        correction_enabled=current_user.preprocessing_correction_enabled,
    )
    return await calc.get_ingredient_advice(food_id)
