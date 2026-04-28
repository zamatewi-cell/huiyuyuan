# -*- coding: utf-8 -*-
"""
huiyuyuan Backend - pytest shared fixtures
Adapted for modular backend architecture (v4.0)
"""
import sys
import os
import re
import time
import pytest
import pytest_asyncio

# Ensure backend root is on sys.path so all imports resolve
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from httpx import AsyncClient, ASGITransport
from main import app
from services import login_guard_service, sms_service
from store import (
    PRODUCTS_DB, ORDERS_DB, CARTS_DB, USERS_DB,
    TOKENS_DB, ADDRESSES_DB, FAVORITES_DB, REVIEWS_DB,
    PAYMENTS_DB, PAYMENT_ACCOUNTS_DB, DEVICES_DB,
    ACTIVE_SESSIONS_DB, REVOKED_SESSIONS_DB,
    INVENTORY_META_DB, INVENTORY_TRANSACTIONS_DB,
    init_store,
)


def _reset_dbs():
    """Reset all in-memory databases to initial state."""
    PRODUCTS_DB.clear()
    ORDERS_DB.clear()
    CARTS_DB.clear()
    ADDRESSES_DB.clear()
    FAVORITES_DB.clear()
    REVIEWS_DB.clear()
    TOKENS_DB.clear()
    ACTIVE_SESSIONS_DB.clear()
    REVOKED_SESSIONS_DB.clear()
    PAYMENTS_DB.clear()
    PAYMENT_ACCOUNTS_DB.clear()
    DEVICES_DB.clear()
    INVENTORY_META_DB.clear()
    INVENTORY_TRANSACTIONS_DB.clear()
    USERS_DB.clear()
    # Re-initialize users + products from seed data
    init_store()


@pytest.fixture(autouse=True)
def clean_state(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setattr(sms_service, "REDIS_AVAILABLE", False)
    monkeypatch.setattr(sms_service, "redis_client", None)
    monkeypatch.setattr(login_guard_service, "REDIS_AVAILABLE", False)
    monkeypatch.setattr(login_guard_service, "redis_client", None)
    login_guard_service._MEMORY_FAILURES.clear()
    _reset_dbs()
    yield
    login_guard_service._MEMORY_FAILURES.clear()
    # Revert per-test monkeypatches before rebuilding the in-memory store.
    # Some tests temporarily point the seed payload path at a missing file and
    # the reset path should always use the default repository seed source.
    monkeypatch.undo()
    _reset_dbs()


@pytest_asyncio.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest_asyncio.fixture
async def admin_auth(client: AsyncClient) -> str:
    """Login as admin, return 'Bearer <token>' string for authorization param."""
    resp = await client.post("/api/auth/login", json={
        "username": "18925816362",
        "password": "admin123",
        "type": "admin",
        "captcha": "8888",
    })
    assert resp.status_code == 200
    return f"Bearer {resp.json()['token']}"


@pytest_asyncio.fixture
async def operator_auth(client: AsyncClient) -> str:
    """Login as operator, return 'Bearer <token>' string."""
    resp = await client.post("/api/auth/login", json={
        "username": "1",
        "password": "op123456",
        "type": "operator",
    })
    assert resp.status_code == 200
    return f"Bearer {resp.json()['token']}"


@pytest_asyncio.fixture
async def customer_auth(client: AsyncClient) -> str:
    """Register and login as customer via the real auth flow."""
    phone = f"138{int(time.time_ns()) % 100000000:08d}"
    send_resp = await client.post(
        "/api/auth/send-sms",
        json={
            "phone": phone,
            "action": "register",
        },
    )
    assert send_resp.status_code == 200

    message = send_resp.json().get("message", "")
    match = re.search(r"(\d{6})", message)
    assert match, message

    register_resp = await client.post(
        "/api/auth/register",
        json={
            "phone": phone,
            "code": match.group(1),
            "password": "Test12345",
            "confirm_password": "Test12345",
            "accept_terms": True,
        },
    )
    assert register_resp.status_code == 200
    return f"Bearer {register_resp.json()['token']}"


@pytest_asyncio.fixture
async def sample_address_id(client: AsyncClient, customer_auth: str) -> str:
    """Create a sample address for customer and return its id."""
    resp = await client.post(
        "/api/users/addresses",
        json={
            "recipient_name": "Test User",
            "phone_number": "13800001234",
            "province": "Zhejiang",
            "city": "Hangzhou",
            "district": "Xihu",
            "detail_address": "Wensan Road 200",
            "is_default": True,
        },
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200
    return resp.json()["id"]
