"""add product appraisal and craft fields

Adds structured connoisseurship fields for the "one product, one dossier"
feature: appraisal notes (trilingual), craft highlights (trilingual),
weight in grams, and dimensions string.

Revision ID: 20260501_0010_product_appraisal_fields
Revises: 20260415_0009_operator_permissions
Create Date: 2026-05-01
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20260501_0010_product_appraisal_fields"
down_revision: Union[str, None] = "20260415_0009_operator_permissions"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # -- appraisal_note: expert authentication description (trilingual) ------
    op.add_column("products", sa.Column("appraisal_note", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("appraisal_note_en", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("appraisal_note_zh_tw", sa.Text(), nullable=True))

    # -- craft_highlights: key craftsmanship points (trilingual) -------------
    op.add_column("products", sa.Column("craft_highlights", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("craft_highlights_en", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("craft_highlights_zh_tw", postgresql.JSONB(), nullable=True))

    # -- physical specifications (language-independent) ----------------------
    op.add_column("products", sa.Column("weight_g", sa.Float(), nullable=True))
    op.add_column("products", sa.Column("dimensions", sa.String(length=120), nullable=True))


def downgrade() -> None:
    op.drop_column("products", "dimensions")
    op.drop_column("products", "weight_g")
    op.drop_column("products", "craft_highlights_zh_tw")
    op.drop_column("products", "craft_highlights_en")
    op.drop_column("products", "craft_highlights")
    op.drop_column("products", "appraisal_note_zh_tw")
    op.drop_column("products", "appraisal_note_en")
    op.drop_column("products", "appraisal_note")
