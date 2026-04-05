"""seed operator accounts

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-18
"""

from typing import Sequence, Union

from alembic import op


revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


OPERATOR_PASSWORD_HASH = "$2b$12$lcDpRgmnfPfHiI9lFCAyZOjP58bNolFdiBYammoIBNHGTsqg2PQl."


def upgrade() -> None:
    values = ",\n".join(
        "    ("
        f"'operator_{i}', "
        f"'1380000000{i}', "
        f"'operator{i}', "
        f"'{OPERATOR_PASSWORD_HASH}', "
        "'operator', "
        f"{i}, "
        "0.00, "
        "100, "
        "TRUE"
        ")"
        for i in range(1, 10)
    )
    values += ",\n"
    values += (
        "    ('operator_10', '13800000010', 'operator10', "
        f"'{OPERATOR_PASSWORD_HASH}', 'operator', 10, 0.00, 100, TRUE)"
    )

    op.execute(
        f"""
        INSERT INTO users (
            id,
            phone,
            username,
            password_hash,
            user_type,
            operator_num,
            balance,
            points,
            is_active
        )
        VALUES
        {values}
        ON CONFLICT (id) DO NOTHING
        """
    )


def downgrade() -> None:
    op.execute("DELETE FROM users WHERE id LIKE 'operator_%'")
