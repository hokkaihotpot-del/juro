from __future__ import annotations

from sqlalchemy import Boolean, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, new_uuid


class AllergyItem(Base, TimestampMixin):
    __tablename__ = "allergy_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    ingredient_name: Mapped[str] = mapped_column(String(100), nullable=False)
    ingredient_name_normalized: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    is_preset: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    user: Mapped["User"] = relationship("User", back_populates="allergy_items")
