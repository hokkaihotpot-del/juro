from __future__ import annotations

from sqlalchemy import Boolean, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, new_uuid


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    region: Mapped[str] = mapped_column(String(10), nullable=False, default="jp")
    preprocessing_correction_enabled: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    nutrition_limits: Mapped[list["NutritionLimit"]] = relationship(
        "NutritionLimit", back_populates="user", cascade="all, delete-orphan"
    )
    allergy_items: Mapped[list["AllergyItem"]] = relationship(
        "AllergyItem", back_populates="user", cascade="all, delete-orphan"
    )
    doctor_info: Mapped[list["DoctorInfo"]] = relationship(
        "DoctorInfo", back_populates="user", cascade="all, delete-orphan"
    )
    nutrition_logs: Mapped[list["NutritionLog"]] = relationship(
        "NutritionLog", back_populates="user", cascade="all, delete-orphan"
    )
    menu_histories: Mapped[list["MenuHistory"]] = relationship(
        "MenuHistory", back_populates="user", cascade="all, delete-orphan"
    )
    consent_logs: Mapped[list["ConsentLog"]] = relationship(
        "ConsentLog", back_populates="user", cascade="all, delete-orphan"
    )


class NutritionLimit(Base, TimestampMixin):
    __tablename__ = "nutrition_limits"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    phosphorus_limit_mg: Mapped[int] = mapped_column(Integer, nullable=False, default=800)
    potassium_limit_mg: Mapped[int] = mapped_column(Integer, nullable=False, default=2000)
    sodium_limit_g: Mapped[float] = mapped_column(Float, nullable=False, default=6.0)
    water_limit_ml: Mapped[float] = mapped_column(Float, nullable=False, default=1500.0)

    user: Mapped["User"] = relationship("User", back_populates="nutrition_limits")
