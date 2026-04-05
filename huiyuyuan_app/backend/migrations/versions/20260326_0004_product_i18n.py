"""添加商品多语言翻译字段

Revision ID: 20260326_0004_product_i18n
Revises: 0003
Create Date: 2026-03-26
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '20260326_0004_product_i18n'
down_revision = '0003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 英文翻译字段
    op.add_column('products', sa.Column('name_en', sa.Text(), nullable=True))
    op.add_column('products', sa.Column('description_en', sa.Text(), nullable=True))
    op.add_column('products', sa.Column('category_en', sa.String(64), nullable=True))
    op.add_column('products', sa.Column('material_en', sa.String(128), nullable=True))
    op.add_column('products', sa.Column('origin_en', sa.String(128), nullable=True))
    op.add_column('products', sa.Column('material_verify_en', sa.String(64), nullable=True))

    # 繁体中文翻译字段
    op.add_column('products', sa.Column('name_zh_tw', sa.Text(), nullable=True))
    op.add_column('products', sa.Column('description_zh_tw', sa.Text(), nullable=True))
    op.add_column('products', sa.Column('category_zh_tw', sa.String(64), nullable=True))
    op.add_column('products', sa.Column('material_zh_tw', sa.String(128), nullable=True))
    op.add_column('products', sa.Column('origin_zh_tw', sa.String(128), nullable=True))
    op.add_column('products', sa.Column('material_verify_zh_tw', sa.String(64), nullable=True))


def downgrade() -> None:
    op.drop_column('products', 'material_verify_zh_tw')
    op.drop_column('products', 'origin_zh_tw')
    op.drop_column('products', 'material_zh_tw')
    op.drop_column('products', 'category_zh_tw')
    op.drop_column('products', 'description_zh_tw')
    op.drop_column('products', 'name_zh_tw')
    op.drop_column('products', 'material_verify_en')
    op.drop_column('products', 'origin_en')
    op.drop_column('products', 'material_en')
    op.drop_column('products', 'category_en')
    op.drop_column('products', 'description_en')
    op.drop_column('products', 'name_en')
