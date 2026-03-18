# -*- coding: utf-8 -*-
"""
Huiyuanyuan Backend - pytest shared fixtures
Adapted for modular backend architecture (v4.0)
"""
import sys
import os
import pytest
import pytest_asyncio

# Ensure backend root is on sys.path so all imports resolve
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from httpx import AsyncClient, ASGITransport
from main import app
from store import (
    PRODUCTS_DB, ORDERS_DB, CARTS_DB, USERS_DB,
    TOKENS_DB, ADDRESSES_DB, FAVORITES_DB, REVIEWS_DB,
    PAYMENTS_DB, PAYMENT_ACCOUNTS_DB, DEVICES_DB,
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
    PAYMENTS_DB.clear()
    PAYMENT_ACCOUNTS_DB.clear()
    DEVICES_DB.clear()
    USERS_DB.clear()
    # Re-initialize users + products from seed data
    init_store()


@pytest.fixture(autouse=True)
def clean_state():
    _reset_dbs()
    yield
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
        "username": "18937766669",
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
    """Login as customer via SMS, return 'Bearer <token>' string."""
    resp = await client.post("/api/auth/login", json={
        "phone": "13800001234",
        "code": "888888",
        "type": "customer_sms",
        "login_type": "customer_sms",
    })
    assert resp.status_code == 200
    return f"Bearer {resp.json()['token']}"


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
