from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models.menu_history import MenuHistory
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.menu import DailyMenuProposal, DishProposal, MealProposal
from app.schemas.signal import TrafficLight
from app.services.csp_engine import CSPMenuEngine
from app.services.signal import get_daily_signals, get_signal

router = APIRouter(prefix="/menu", tags=["menu"])


@router.get("/propose", response_model=DailyMenuProposal)
async def propose_menu(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = UserRepository(db)
    limits = await repo.get_nutrition_limit(current_user.id)

    allergy_names = [a.ingredient_name for a in current_user.allergy_items]

    engine = CSPMenuEngine(
        db=db,
        user_id=current_user.id,
        nutrition_limits=limits,
        allergy_names=allergy_names,
        correction_enabled=current_user.preprocessing_correction_enabled,
    )
    meal_sets, is_fallback = await engine.generate()

    # 信号色を計算
    def meal_to_proposal(meal_type: str, meal_set) -> MealProposal:
        dishes = [
            DishProposal(
                dish_name=d.dish_name,
                dish_category=d.dish_category,
                signal_color=get_signal(
                    d.potassium_corrected_mg, limits.potassium_limit_mg / 3
                ),
                water_ml=d.water_ml,
            )
            for d in meal_set.dishes
        ]
        p_sig = get_signal(meal_set.phosphorus_mg, limits.phosphorus_limit_mg / 3)
        k_sig = get_signal(meal_set.potassium_corrected_mg, limits.potassium_limit_mg / 3)
        na_sig = get_signal(meal_set.sodium_g, limits.sodium_limit_g / 3)
        w_sig = get_signal(meal_set.water_ml, limits.water_limit_ml / 3)
        return MealProposal(
            meal_type=meal_type,
            dishes=dishes,
            phosphorus_signal=p_sig,
            potassium_signal=k_sig,
            sodium_signal=na_sig,
            water_signal=w_sig,
            water_ml=meal_set.water_ml,
        )

    from app.schemas.signal import MealType
    bf = meal_sets.get(MealType.BREAKFAST)
    lu = meal_sets.get(MealType.LUNCH)
    di = meal_sets.get(MealType.DINNER)

    daily_p = sum(m.phosphorus_mg for m in [bf, lu, di] if m)
    daily_k = sum(m.potassium_corrected_mg for m in [bf, lu, di] if m)
    daily_na = sum(m.sodium_g for m in [bf, lu, di] if m)
    daily_w = sum(m.water_ml for m in [bf, lu, di] if m)

    dp, dk, dna = get_daily_signals(
        daily_p, daily_k, daily_na,
        limits.phosphorus_limit_mg,
        limits.potassium_limit_mg,
        limits.sodium_limit_g,
    )
    dw = get_signal(daily_w, limits.water_limit_ml)

    # 献立履歴を記録
    today = date.today()
    for meal_type, meal_set in meal_sets.items():
        if meal_set and meal_set.combination_hash:
            db.add(MenuHistory(
                user_id=current_user.id,
                menu_date=today,
                meal_type=meal_type,
                combination_hash=meal_set.combination_hash,
                total_phosphorus_mg=meal_set.phosphorus_mg,
                total_potassium_corrected_mg=meal_set.potassium_corrected_mg,
                total_sodium_g=meal_set.sodium_g,
                total_water_ml=meal_set.water_ml,
            ))

    return DailyMenuProposal(
        breakfast=meal_to_proposal(MealType.BREAKFAST, bf) if bf else None,
        lunch=meal_to_proposal(MealType.LUNCH, lu) if lu else None,
        dinner=meal_to_proposal(MealType.DINNER, di) if di else None,
        daily_phosphorus_signal=dp,
        daily_potassium_signal=dk,
        daily_sodium_signal=dna,
        daily_water_signal=dw,
        is_fallback=is_fallback,
    )
