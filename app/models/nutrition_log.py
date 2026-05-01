from __future__ import annotations

from datetime import date

from sqlalchemy import Boolean, Date, Float, ForeignKey, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, new_uuid


class NutritionLog(Base, TimestampMixin):
    __tablename__ = "nutrition_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    log_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    meal_type: Mapped[str] = mapped_column(String(20), nullable=False)
    recipe_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("recipe_master.id", ondelete="SET NULL"), nullable=True
    )
    phosphorus_mg: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    potassium_raw_mg: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    potassium_corrected_mg: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    sodium_g: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    water_ml: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    correction_applied: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    ingredient_detail: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    user: Mapped["User"] = relationship("User", back_populates="nutrition_logs")
