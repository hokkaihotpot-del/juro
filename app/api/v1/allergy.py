from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models.allergy import AllergyItem
from app.models.user import User
from app.schemas.allergy import AllergyItemCreate, AllergyItemRead, AllergyListResponse

router = APIRouter(prefix="/allergy", tags=["allergy"])


@router.get("", response_model=AllergyListResponse)
async def list_allergies(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(AllergyItem).where(AllergyItem.user_id == current_user.id)
    )
    items = result.scalars().all()
    return AllergyListResponse(
        items=[AllergyItemRead.model_validate(i) for i in items],
        total=len(items),
    )


@router.post("", response_model=AllergyItemRead, status_code=201)
async def add_allergy(
    body: AllergyItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    item = AllergyItem(
        user_id=current_user.id,
        ingredient_name=body.ingredient_name,
        ingredient_name_normalized=body.ingredient_name.lower().strip(),
        is_preset=body.is_preset,
    )
    db.add(item)
    await db.flush()
    return AllergyItemRead.model_validate(item)


@router.delete("/{item_id}", status_code=204)
async def delete_allergy(
    item_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(AllergyItem).where(
            AllergyItem.id == item_id,
            AllergyItem.user_id == current_user.id,
        )
    )
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Allergy item not found")
    await db.delete(item)
    return Response(status_code=204)
