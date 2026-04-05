"""Create inventory transaction log table.

Revision ID: 20260328_0005_create_inventory_transactions
Revises: 20260326_0004_product_i18n
Create Date: 2026-03-28
"""

from alembic import op
import sqlalchemy as sa


revision = "20260328_0005_create_inventory_transactions"
down_revision = "20260326_0004_product_i18n"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "inventory_transactions",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("product_id", sa.String(length=64), nullable=False),
        sa.Column("product_name", sa.Text(), nullable=False),
        sa.Column("type", sa.String(length=32), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("stock_before", sa.Integer(), nullable=False),
        sa.Column("stock_after", sa.Integer(), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("operator_name", sa.String(length=128), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_inventory_transactions_product_id",
        "inventory_transactions",
        ["product_id"],
        unique=False,
    )
    op.create_index(
        "ix_inventory_transactions_created_at",
        "inventory_transactions",
        ["created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_inventory_transactions_created_at", table_name="inventory_transactions")
    op.drop_index("ix_inventory_transactions_product_id", table_name="inventory_transactions")
    op.drop_table("inventory_transactions")
