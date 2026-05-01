"""initial schema

Revision ID: 0001
Revises: 
Create Date: 2026-05-01

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("region", sa.String(10), nullable=False, server_default="jp"),
        sa.Column("preprocessing_correction_enabled", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "nutrition_limits",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("phosphorus_limit_mg", sa.Integer(), nullable=False, server_default="800"),
        sa.Column("potassium_limit_mg", sa.Integer(), nullable=False, server_default="2000"),
        sa.Column("sodium_limit_g", sa.Float(), nullable=False, server_default="6.0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_nutrition_limits_user_id", "nutrition_limits", ["user_id"])

    op.create_table(
        "allergy_items",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("ingredient_name", sa.String(100), nullable=False),
        sa.Column("ingredient_name_normalized", sa.String(100), nullable=False),
        sa.Column("is_preset", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_allergy_items_user_id", "allergy_items", ["user_id"])
    op.create_index("ix_allergy_items_normalized", "allergy_items", ["ingredient_name_normalized"])

    op.create_table(
        "doctor_info",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("doctor_name", sa.String(200), nullable=False),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("system_id", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_doctor_info_user_id", "doctor_info", ["user_id"])

    op.create_table(
        "food_master",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("food_name", sa.String(200), nullable=False),
        sa.Column("food_name_normalized", sa.String(200), nullable=False),
        sa.Column("region", sa.String(10), nullable=False, server_default="jp"),
        sa.Column("external_id", sa.String(100), nullable=True),
        sa.Column("phosphorus_per100g", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("potassium_per100g", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("sodium_per100g", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("vegetable_category", sa.String(20), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_food_master_normalized", "food_master", ["food_name_normalized"])
    op.create_index("ix_food_master_external_id", "food_master", ["external_id"])

    op.create_table(
        "recipe_master",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("dish_name", sa.String(200), nullable=False),
        sa.Column("dish_name_normalized", sa.String(200), nullable=False),
        sa.Column("source_url", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_recipe_master_normalized", "recipe_master", ["dish_name_normalized"])

    op.create_table(
        "recipe_ingredients",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("recipe_id", sa.String(36), sa.ForeignKey("recipe_master.id", ondelete="CASCADE"), nullable=False),
        sa.Column("food_id", sa.String(36), sa.ForeignKey("food_master.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("weight_g", sa.Float(), nullable=False),
    )
    op.create_index("ix_recipe_ingredients_recipe_id", "recipe_ingredients", ["recipe_id"])

    op.create_table(
        "menu_master",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("meal_type", sa.String(20), nullable=False),
        sa.Column("dish_category", sa.String(20), nullable=False),
        sa.Column("dish_name", sa.String(200), nullable=False),
        sa.Column("recipe_id", sa.String(36), sa.ForeignKey("recipe_master.id", ondelete="SET NULL"), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_menu_master_meal_type", "menu_master", ["meal_type"])
    op.create_index("ix_menu_master_dish_category", "menu_master", ["dish_category"])

    op.create_table(
        "nutrition_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("meal_type", sa.String(20), nullable=False),
        sa.Column("recipe_id", sa.String(36), sa.ForeignKey("recipe_master.id", ondelete="SET NULL"), nullable=True),
        sa.Column("phosphorus_mg", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("potassium_raw_mg", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("potassium_corrected_mg", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("sodium_g", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("correction_applied", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("ingredient_detail", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_nutrition_logs_user_id", "nutrition_logs", ["user_id"])
    op.create_index("ix_nutrition_logs_log_date", "nutrition_logs", ["log_date"])

    op.create_table(
        "menu_history",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("menu_date", sa.Date(), nullable=False),
        sa.Column("meal_type", sa.String(20), nullable=False),
        sa.Column("combination_hash", sa.String(64), nullable=False),
        sa.Column("total_phosphorus_mg", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("total_potassium_corrected_mg", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("total_sodium_g", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_menu_history_user_id", "menu_history", ["user_id"])
    op.create_index("ix_menu_history_menu_date", "menu_history", ["menu_date"])
    op.create_index("ix_menu_history_combination_hash", "menu_history", ["combination_hash"])

    op.create_table(
        "consent_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("consent_type", sa.String(100), nullable=False),
        sa.Column("consented_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("target_period", sa.String(50), nullable=True),
        sa.Column("doctor_id", sa.String(36), sa.ForeignKey("doctor_info.id", ondelete="SET NULL"), nullable=True),
        sa.Column("send_status", sa.String(20), nullable=False, server_default="pending"),
    )
    op.create_index("ix_consent_logs_user_id", "consent_logs", ["user_id"])


def downgrade() -> None:
    op.drop_table("consent_logs")
    op.drop_table("menu_history")
    op.drop_table("nutrition_logs")
    op.drop_table("menu_master")
    op.drop_table("recipe_ingredients")
    op.drop_table("recipe_master")
    op.drop_table("food_master")
    op.drop_table("doctor_info")
    op.drop_table("allergy_items")
    op.drop_table("nutrition_limits")
    op.drop_table("users")
