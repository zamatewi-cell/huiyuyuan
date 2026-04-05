"""create payment_accounts table

Revision ID: 0003
Revises: 0002
Create Date: 2026-03-18
"""

from typing import Sequence, Union

from alembic import op


revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS payment_accounts (
            id             VARCHAR(64) PRIMARY KEY,
            user_id        VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            account_type   VARCHAR(20) NOT NULL
                           CHECK (account_type IN ('bank','alipay','wechat','cash','other')),
            account_name   VARCHAR(64) NOT NULL,
            account_number VARCHAR(128),
            bank_name      VARCHAR(128),
            qr_code_url    TEXT,
            is_active      BOOLEAN NOT NULL DEFAULT TRUE,
            is_default     BOOLEAN NOT NULL DEFAULT FALSE,
            created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_payment_accounts_user_id
            ON payment_accounts(user_id)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_payment_accounts_user_active
            ON payment_accounts(user_id, is_active)
        """
    )
    op.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_accounts_user_default
            ON payment_accounts(user_id) WHERE is_default = TRUE
        """
    )
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_trigger
                WHERE tgname = 'trg_payment_accounts_updated_at'
            ) THEN
                CREATE TRIGGER trg_payment_accounts_updated_at
                BEFORE UPDATE ON payment_accounts
                FOR EACH ROW EXECUTE FUNCTION set_updated_at();
            END IF;
        END;
        $$;
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS payment_accounts CASCADE")
