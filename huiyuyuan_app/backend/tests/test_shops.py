# -*- coding: utf-8 -*-
"""Shop endpoint tests (5 cases)"""
import pytest
from httpx import AsyncClient

from store import SHOPS_DB
from schemas.shop import Shop


def _seed_shop():
    """Insert a test shop into in-memory DB."""
    shop = Shop(
        id="SHOP_TEST_001",
        name="Test Jade Shop",
        platform="taobao",
        rating=4.8,
        conversion_rate=3.5,
        followers=12000,
        category="jade",
        contact_status="contacted",
        shop_url="https://example.com/shop1",
        monthly_sales=500,
        negative_rate=0.5,
        is_influencer=False,
        operator_id=None,
        ai_priority=80,
    )
    SHOPS_DB[shop.id] = shop
    return shop


@pytest.mark.asyncio
async def test_get_shops_empty(client: AsyncClient, admin_auth: str):
    """No shops seeded -> return empty list."""
    resp = await client.get("/api/shops", params={"authorization": admin_auth})
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_get_shops_with_data(client: AsyncClient, admin_auth: str):
    _seed_shop()
    resp = await client.get("/api/shops", params={"authorization": admin_auth})
    assert resp.status_code == 200
    shops = resp.json()
    assert len(shops) == 1
    assert shops[0]["id"] == "SHOP_TEST_001"
    assert shops[0]["platform"] == "taobao"


@pytest.mark.asyncio
async def test_get_shops_filter_platform(client: AsyncClient, admin_auth: str):
    _seed_shop()
    # Add another shop with different platform
    SHOPS_DB["SHOP_TEST_002"] = Shop(
        id="SHOP_TEST_002", name="Douyin Shop", platform="douyin",
        rating=4.5, conversion_rate=2.0, followers=5000,
        category="jade", contact_status="new", is_influencer=True,
    )

    resp = await client.get(
        "/api/shops",
        params={"platform": "douyin", "authorization": admin_auth},
    )
    assert resp.status_code == 200
    shops = resp.json()
    assert len(shops) == 1
    assert shops[0]["platform"] == "douyin"


@pytest.mark.asyncio
async def test_get_shop_detail(client: AsyncClient, admin_auth: str):
    _seed_shop()
    resp = await client.get(
        "/api/shops/SHOP_TEST_001",
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Test Jade Shop"
    assert data["rating"] == 4.8


@pytest.mark.asyncio
async def test_get_shop_detail_not_found(client: AsyncClient, admin_auth: str):
    resp = await client.get(
        "/api/shops/NONEXISTENT",
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_operator_without_shop_radar_permission_is_forbidden(
    client: AsyncClient,
    admin_auth: str,
):
    await client.put(
        "/api/admin/operators/operator_1",
        json={"permissions": ["orders"]},
        params={"authorization": admin_auth},
    )
    login = await client.post(
        "/api/auth/login",
        json={
            "username": "1",
            "password": "op123456",
            "type": "operator",
        },
    )
    assert login.status_code == 200
    operator_auth = f"Bearer {login.json()['token']}"

    resp = await client.get("/api/shops", params={"authorization": operator_auth})

    assert resp.status_code == 403
