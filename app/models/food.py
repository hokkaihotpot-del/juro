from __future__ import annotations

from sqlalchemy import Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, new_uuid


class RecipeMaster(Base, TimestampMixin):
    __tablename__ = "recipe_master"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    dish_name: Mapped[str] = mapped_column(String(200), nullable=False)
    dish_name_normalized: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    source_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    ingredients: Mapped[list["RecipeIngredient"]] = relationship(
        back_populates="recipe", cascade="all, delete-orphan"
    )


class RecipeIngredient(Base):
    __tablename__ = "recipe_ingredients"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    recipe_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("recipe_master.id", ondelete="CASCADE"), nullable=False, index=True
    )
    food_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("food_master.id", ondelete="RESTRICT"), nullable=False
    )
    weight_g: Mapped[float] = mapped_column(Float, nullable=False)

    recipe: Mapped["RecipeMaster"] = relationship(back_populates="ingredients")
    food: Mapped["FoodMaster"] = relationship()


class FoodMaster(Base, TimestampMixin):
    __tablename__ = "food_master"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    food_name: Mapped[str] = mapped_column(String(200), nullable=False)
    food_name_normalized: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    region: Mapped[str] = mapped_column(String(10), nullable=False, default="jp")
    external_id: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    phosphorus_per100g: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    potassium_per100g: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    sodium_per100g: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    water_per100g: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    cooking_yield_rate: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    vegetable_category: Mapped[str | None] = mapped_column(
        String(20), nullable=True
    )
