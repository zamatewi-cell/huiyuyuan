"""add extended product dossier fields

Adds nullable fields for the remaining "one product, one dossier" data:
audience fit tags, origin story, visible flaw notes, certificate evidence,
and supplementary gallery images.

Revision ID: 20260505_0011_product_dossier_fields
Revises: 20260501_0010_product_appraisal_fields
Create Date: 2026-05-05
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20260505_0011_product_dossier_fields"
down_revision: Union[str, None] = "20260501_0010_product_appraisal_fields"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("products", sa.Column("audience_tags", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("audience_tags_en", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("audience_tags_zh_tw", postgresql.JSONB(), nullable=True))

    op.add_column("products", sa.Column("origin_story", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("origin_story_en", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("origin_story_zh_tw", sa.Text(), nullable=True))

    op.add_column("products", sa.Column("flaw_notes", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("flaw_notes_en", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("flaw_notes_zh_tw", postgresql.JSONB(), nullable=True))

    op.add_column("products", sa.Column("certificate_authority", sa.String(length=128), nullable=True))
    op.add_column("products", sa.Column("certificate_authority_en", sa.String(length=128), nullable=True))
    op.add_column("products", sa.Column("certificate_authority_zh_tw", sa.String(length=128), nullable=True))
    op.add_column("products", sa.Column("certificate_image_url", sa.String(length=512), nullable=True))
    op.add_column("products", sa.Column("certificate_verify_url", sa.String(length=512), nullable=True))

    op.add_column("products", sa.Column("gallery_detail", postgresql.JSONB(), nullable=True))
    op.add_column("products", sa.Column("gallery_hand", postgresql.JSONB(), nullable=True))


def downgrade() -> None:
    op.drop_column("products", "gallery_hand")
    op.drop_column("products", "gallery_detail")
    op.drop_column("products", "certificate_verify_url")
    op.drop_column("products", "certificate_image_url")
    op.drop_column("products", "certificate_authority_zh_tw")
    op.drop_column("products", "certificate_authority_en")
    op.drop_column("products", "certificate_authority")
    op.drop_column("products", "flaw_notes_zh_tw")
    op.drop_column("products", "flaw_notes_en")
    op.drop_column("products", "flaw_notes")
    op.drop_column("products", "origin_story_zh_tw")
    op.drop_column("products", "origin_story_en")
    op.drop_column("products", "origin_story")
    op.drop_column("products", "audience_tags_zh_tw")
    op.drop_column("products", "audience_tags_en")
    op.drop_column("products", "audience_tags")
