"""baseline from init_db.sql v4.1

Revision ID: 0001
Revises: None
Create Date: 2026-02-27

This is a BASELINE migration. It does NOT create tables.
It only stamps the alembic_version table so subsequent migrations
can build on top of the existing init_db.sql schema.

For fresh installs:
  1. Run init_db.sql first
  2. Then: alembic stamp 0001

For existing databases:
  - Just run: alembic stamp 0001
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Baseline migration ¡ª schema already exists via init_db.sql
    # Tables covered:
    #   users, products, addresses, cart_items,
    #   orders, order_items, payments, sms_logs, reviews,
    #   shops, devices, notifications, favorites
    # Plus: updated_at triggers, pg_trgm extension, GIN indexes
    pass


def downgrade() -> None:
    # Cannot downgrade from baseline
    raise RuntimeError(
        "Cannot downgrade baseline migration. "
        "Use init_db.sql to recreate from scratch."
    )
