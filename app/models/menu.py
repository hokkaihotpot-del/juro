from __future__ import annotations

from sqlalchemy import Boolean, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, new_uuid


class MenuMaster(Base, TimestampMixin):
    """献立マスター - 献立候補の定義"""

    __tablename__ = "menu_master"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    meal_type: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    dish_category: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    dish_name: Mapped[str] = mapped_column(String(200), nullable=False)
    recipe_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("recipe_master.id", ondelete="SET NULL"), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    recipe: Mapped["RecipeMaster | None"] = relationship()


from app.models.food import RecipeMaster  # noqa: E402
