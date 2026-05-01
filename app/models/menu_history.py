from __future__ import annotations

from datetime import date

from sqlalchemy import Date, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, new_uuid


class MenuHistory(Base, TimestampMixin):
    __tablename__ = "menu_history"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    menu_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    meal_type: Mapped[str] = mapped_column(String(20), nullable=False)
    combination_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    total_phosphorus_mg: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_potassium_corrected_mg: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_sodium_g: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_water_ml: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    user: Mapped["User"] = relationship("User", back_populates="menu_histories")
