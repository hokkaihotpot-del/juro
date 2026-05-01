"""add water fields

Revision ID: 0002
Revises: 0001
Create Date: 2026-05-01

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # food_master: 水分含有量と重量変化率を追加
    op.add_column(
        "food_master",
        sa.Column("water_per100g", sa.Float(), nullable=False, server_default="0.0"),
    )
    op.add_column(
        "food_master",
        sa.Column("cooking_yield_rate", sa.Float(), nullable=False, server_default="1.0"),
    )

    # nutrition_limits: 水分上限を追加（透析患者の標準値 1500mL/日）
    op.add_column(
        "nutrition_limits",
        sa.Column("water_limit_ml", sa.Float(), nullable=False, server_default="1500.0"),
    )

    # nutrition_logs: 水分量ログを追加
    op.add_column(
        "nutrition_logs",
        sa.Column("water_ml", sa.Float(), nullable=False, server_default="0.0"),
    )

    # menu_history: 水分量合計を追加
    op.add_column(
        "menu_history",
        sa.Column("total_water_ml", sa.Float(), nullable=False, server_default="0.0"),
    )


def downgrade() -> None:
    op.drop_column("menu_history", "total_water_ml")
    op.drop_column("nutrition_logs", "water_ml")
    op.drop_column("nutrition_limits", "water_limit_ml")
    op.drop_column("food_master", "cooking_yield_rate")
    op.drop_column("food_master", "water_per100g")
