"""Create payment records and audit logs tables.

Revision ID: 20260405_0007_payment_records_and_audit
Revises: 20260402_0006_bind_orders_to_payment_accounts
Create Date: 2026-04-05
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260405_0007_payment_records_and_audit"
down_revision: Union[str, None] = "20260402_0006_bind_orders_to_payment_accounts"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 支付记录表
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS payment_records (
            payment_id VARCHAR(32) PRIMARY KEY,
            order_id VARCHAR(64) NOT NULL,
            user_id VARCHAR(64) NOT NULL,
            amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
            payment_account_id VARCHAR(64) REFERENCES payment_accounts(id),
            payment_method VARCHAR(32) NOT NULL DEFAULT 'wechat',
            status VARCHAR(32) NOT NULL DEFAULT 'pending',
            remark TEXT DEFAULT '',
            voucher_url TEXT,
            admin_note TEXT,
            confirmed_by VARCHAR(64),
            confirmed_at TIMESTAMP,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS idx_pr_order ON payment_records(order_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_pr_user ON payment_records(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_pr_status ON payment_records(status)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_pr_created ON payment_records(created_at DESC)")

    # 支付审计日志表
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS payment_audit_logs (
            log_id VARCHAR(20) PRIMARY KEY,
            user_id VARCHAR(64) NOT NULL,
            payment_id VARCHAR(32) NOT NULL,
            order_id VARCHAR(64) NOT NULL,
            action VARCHAR(64) NOT NULL,
            detail TEXT,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    op.execute("CREATE INDEX IF NOT EXISTS idx_audit_user ON payment_audit_logs(user_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_audit_payment ON payment_audit_logs(payment_id)")
    op.execute("CREATE INDEX IF NOT EXISTS idx_audit_created ON payment_audit_logs(created_at DESC)")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS payment_audit_logs")
    op.execute("DROP TABLE IF EXISTS payment_records")
