from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, NutritionLimit
from app.core.security import hash_password


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: str) -> User | None:
        result = await self.db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, email: str, password: str, region: str = "jp") -> User:
        user = User(
            email=email,
            hashed_password=hash_password(password),
            region=region,
        )
        self.db.add(user)
        await self.db.flush()
        limit = NutritionLimit(user_id=user.id)
        self.db.add(limit)
        await self.db.flush()
        return user

    async def get_nutrition_limit(self, user_id: str) -> NutritionLimit | None:
        result = await self.db.execute(
            select(NutritionLimit).where(NutritionLimit.user_id == user_id)
        )
        return result.scalar_one_or_none()
