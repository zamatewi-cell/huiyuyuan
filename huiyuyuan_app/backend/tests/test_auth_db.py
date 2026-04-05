# -*- coding: utf-8 -*-
"""DB-backed auth query tests."""

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from routers.auth import _db_find_user


def _build_session():
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    with engine.begin() as conn:
        conn.execute(
            text(
                """
                CREATE TABLE users (
                    id TEXT PRIMARY KEY,
                    phone TEXT,
                    username TEXT NOT NULL,
                    password_hash TEXT,
                    avatar_url TEXT,
                    user_type TEXT NOT NULL,
                    operator_num INTEGER,
                    balance REAL NOT NULL DEFAULT 0,
                    points INTEGER NOT NULL DEFAULT 0,
                    is_active BOOLEAN NOT NULL DEFAULT 1
                )
                """
            )
        )
        conn.execute(
            text(
                """
                INSERT INTO users (
                    id, phone, username, password_hash, user_type,
                    operator_num, balance, points, avatar_url, is_active
                ) VALUES (
                    'admin_001', '18937766669', 'admin',
                    'hash', 'admin', NULL, 999999.0, 99999, NULL, 1
                )
                """
            )
        )
        conn.execute(
            text(
                """
                INSERT INTO users (
                    id, phone, username, password_hash, user_type,
                    operator_num, balance, points, avatar_url, is_active
                ) VALUES (
                    'operator_1', '13800000001', 'operator1',
                    'hash', 'operator', 1, 0.0, 100, NULL, 1
                )
                """
            )
        )

    return sessionmaker(bind=engine, future=True)()


def test_db_find_user_admin_matches_schema_without_is_admin_column():
    db = _build_session()
    try:
        user = _db_find_user(db, phone="18937766669", user_type="admin")
    finally:
        db.close()

    assert user is not None
    assert user["id"] == "admin_001"
    assert user["is_admin"] is True


def test_db_find_user_operator_by_number_matches_schema_without_is_admin_column():
    db = _build_session()
    try:
        user = _db_find_user(db, operator_num=1, user_type="operator")
    finally:
        db.close()

    assert user is not None
    assert user["id"] == "operator_1"
    assert user["operator_number"] == 1
    assert user["is_admin"] is False
