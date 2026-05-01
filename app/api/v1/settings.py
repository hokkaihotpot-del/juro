from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models.doctor import DoctorInfo
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.allergy import DoctorInfoCreate, DoctorInfoRead
from app.schemas.user import NutritionLimitRead, NutritionLimitUpdate, SettingsRead, SettingsUpdate

router = APIRouter(prefix="/settings", tags=["settings"])


@router.get("", response_model=SettingsRead)
async def get_settings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = UserRepository(db)
    limits = await repo.get_nutrition_limit(current_user.id)
    return SettingsRead(
        region=current_user.region,
        preprocessing_correction_enabled=current_user.preprocessing_correction_enabled,
        nutrition_limits=NutritionLimitRead.model_validate(limits) if limits else None,
    )


@router.patch("", response_model=SettingsRead)
async def update_settings(
    body: SettingsUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if body.preprocessing_correction_enabled is not None:
        current_user.preprocessing_correction_enabled = body.preprocessing_correction_enabled
    if body.region is not None:
        current_user.region = body.region
    await db.flush()
    return await get_settings(db=db, current_user=current_user)


@router.patch("/nutrition-limits", response_model=NutritionLimitRead)
async def update_nutrition_limits(
    body: NutritionLimitUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = UserRepository(db)
    limits = await repo.get_nutrition_limit(current_user.id)
    limits.phosphorus_limit_mg = body.phosphorus_limit_mg
    limits.potassium_limit_mg = body.potassium_limit_mg
    limits.sodium_limit_g = body.sodium_limit_g
    await db.flush()
    return NutritionLimitRead.model_validate(limits)


@router.get("/doctor", response_model=list[DoctorInfoRead])
async def list_doctors(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(DoctorInfo).where(DoctorInfo.user_id == current_user.id)
    )
    return [DoctorInfoRead.model_validate(d) for d in result.scalars().all()]


@router.post("/doctor", response_model=DoctorInfoRead, status_code=201)
async def add_doctor(
    body: DoctorInfoCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    doctor = DoctorInfo(
        user_id=current_user.id,
        doctor_name=body.doctor_name,
        email=body.email,
        system_id=body.system_id,
    )
    db.add(doctor)
    await db.flush()
    return DoctorInfoRead.model_validate(doctor)
