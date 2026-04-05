"""Bind orders to payment accounts.

Revision ID: 20260402_0006_bind_orders_to_payment_accounts
Revises: 20260328_0005_create_inventory_transactions
Create Date: 2026-04-02
"""

from typing import Sequence, Union

from alembic import op


revision: str = "20260402_0006_bind_orders_to_payment_accounts"
down_revision: Union[str, None] = "20260328_0005_create_inventory_transactions"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS payment_account_id VARCHAR(64)
        REFERENCES payment_accounts(id)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_orders_payment_account_id
            ON orders(payment_account_id)
        """
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_orders_payment_account_id")
    op.execute("ALTER TABLE orders DROP COLUMN IF EXISTS payment_account_id")
