"""
Alembic migration environment for HuiYuYuan backend.

Reads DATABASE_URL from config.py. Supports both:
  - Online mode (connected to real DB)
  - Offline mode (generates SQL scripts)
"""

import sys
import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool, text

# Ensure backend root is importable
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from config import DATABASE_URL

# Alembic Config object
config = context.config

# Setup logging from alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# We don't use declarative Base (raw SQL), so target_metadata = None
# If you add SQLAlchemy ORM models later, import Base.metadata here
target_metadata = None


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    Generates SQL script without connecting to DB.
    Useful for review before applying.

    Usage: alembic upgrade head --sql > migration.sql
    """
    url = DATABASE_URL or "postgresql://huyy_user:password@localhost:5432/huiyuyuan"
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    Connects to DB and applies migrations directly.
    """
    url = DATABASE_URL
    if not url:
        raise RuntimeError(
            "DATABASE_URL is not set. Cannot run online migrations.\n"
            "Set it in .env or environment: DATABASE_URL=postgresql://user:pass@host/db"
        )

    # Build engine config from alembic.ini [alembic] section
    cfg = config.get_section(config.config_ini_section, {})
    cfg["sqlalchemy.url"] = url

    connectable = engine_from_config(
        cfg,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
