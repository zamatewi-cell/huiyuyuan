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
async def test_get_shops_empty(client: AsyncClient):
    """No shops seeded -> return empty list."""
    resp = await client.get("/api/shops")
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_get_shops_with_data(client: AsyncClient):
    _seed_shop()
    resp = await client.get("/api/shops")
    assert resp.status_code == 200
    shops = resp.json()
    assert len(shops) == 1
    assert shops[0]["id"] == "SHOP_TEST_001"
    assert shops[0]["platform"] == "taobao"


@pytest.mark.asyncio
async def test_get_shops_filter_platform(client: AsyncClient):
    _seed_shop()
    # Add another shop with different platform
    SHOPS_DB["SHOP_TEST_002"] = Shop(
        id="SHOP_TEST_002", name="Douyin Shop", platform="douyin",
        rating=4.5, conversion_rate=2.0, followers=5000,
        category="jade", contact_status="new", is_influencer=True,
    )

    resp = await client.get("/api/shops", params={"platform": "douyin"})
    assert resp.status_code == 200
    shops = resp.json()
    assert len(shops) == 1
    assert shops[0]["platform"] == "douyin"


@pytest.mark.asyncio
async def test_get_shop_detail(client: AsyncClient):
    _seed_shop()
    resp = await client.get("/api/shops/SHOP_TEST_001")
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Test Jade Shop"
    assert data["rating"] == 4.8


@pytest.mark.asyncio
async def test_get_shop_detail_not_found(client: AsyncClient):
    resp = await client.get("/api/shops/NONEXISTENT")
    assert resp.status_code == 404
