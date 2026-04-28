"""add operator permissions

Revision ID: 20260415_0009_operator_permissions
Revises: 20260406_0008
Create Date: 2026-04-15
"""

from typing import Sequence, Union

from alembic import op


revision: str = "20260415_0009_operator_permissions"
down_revision: Union[str, None] = "20260406_0008"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


DEFAULT_OPERATOR_PERMISSIONS = (
    '["shop_radar", "ai_assistant", "orders", "inventory_read"]'
)


def upgrade() -> None:
    op.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions JSONB")
    op.execute(
        "UPDATE users SET permissions = "
        f"'{DEFAULT_OPERATOR_PERMISSIONS}'::jsonb "
        "WHERE user_type = 'operator' "
        "AND (permissions IS NULL OR permissions = '[]'::jsonb)"
    )
    op.execute(
        "UPDATE users SET permissions = '[]'::jsonb "
        "WHERE user_type != 'operator' AND permissions IS NULL"
    )
    op.execute("ALTER TABLE users ALTER COLUMN permissions SET DEFAULT '[]'::jsonb")
    op.execute("ALTER TABLE users ALTER COLUMN permissions SET NOT NULL")


def downgrade() -> None:
    op.drop_column("users", "permissions")
