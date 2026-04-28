"""expand address tag field length

Revision ID: 20260406_0008
Revises: 20260405_0007_payment_records_and_audit
Create Date: 2026-04-06
"""
from alembic import op
import sqlalchemy as sa

revision = "20260406_0008"
down_revision = "20260405_0007_payment_records_and_audit"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column("addresses", "tag", type_=sa.String(32))


def downgrade() -> None:
    op.alter_column("addresses", "tag", type_=sa.String(16))
