from __future__ import annotations

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, new_uuid


class ConsentLog(Base):
    """同意ログ - INSERT ONLY（UPDATE/DELETE 禁止）"""

    __tablename__ = "consent_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    consent_type: Mapped[str] = mapped_column(String(100), nullable=False)
    consented_at: Mapped[str] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    target_period: Mapped[str | None] = mapped_column(String(50), nullable=True)
    doctor_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("doctor_info.id", ondelete="SET NULL"), nullable=True
    )
    send_status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")

    user: Mapped["User"] = relationship("User", back_populates="consent_logs")
