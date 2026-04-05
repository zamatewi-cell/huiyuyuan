# -*- coding: utf-8 -*-
"""Admin extra tests - ship order + edge cases (6 cases)"""
import pytest
from httpx import AsyncClient

from store import ORDERS_DB
from schemas.order import Order


def _seed_paid_order() -> str:
    """Create a paid order in memory for shipping tests."""
    from datetime import datetime
    order_id = "ORD_SHIP_TEST_001"
    ORDERS_DB[order_id] = Order(
        id=order_id,
        user_id="customer_sms_13800001234",
        items=[{
            "product_id": "HYY-HT001",
            "product_name": "Test Bracelet",
            "price": 1999.0,
            "quantity": 1,
        }],
        total_amount=1999.0,
        status="paid",
        payment_method="wechat",
        created_at=datetime.now().isoformat(),
        paid_at=datetime.now().isoformat(),
    )
    return order_id


@pytest.mark.asyncio
async def test_ship_order_success(client: AsyncClient, admin_auth: str):
    order_id = _seed_paid_order()
    resp = await client.post(
        f"/api/admin/orders/{order_id}/ship",
        json={"carrier": "SF Express", "tracking_number": "SF123456789012"},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["tracking_number"] == "SF123456789012"

    # Verify order status changed
    assert ORDERS_DB[order_id].status == "shipped"
    assert ORDERS_DB[order_id].tracking_number == "SF123456789012"


@pytest.mark.asyncio
async def test_ship_order_not_found(client: AsyncClient, admin_auth: str):
    resp = await client.post(
        "/api/admin/orders/NONEXISTENT/ship",
        json={"carrier": "SF"},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_ship_order_wrong_status(client: AsyncClient, admin_auth: str):
    """Cannot ship a pending (unpaid) order."""
    from datetime import datetime
    ORDERS_DB["ORD_PENDING_001"] = Order(
        id="ORD_PENDING_001",
        user_id="customer_sms_13800001234",
        items=[{"product_id": "HYY-HT001", "product_name": "X", "price": 100, "quantity": 1}],
        total_amount=100.0,
        status="pending",
        payment_method="alipay",
        created_at=datetime.now().isoformat(),
    )
    resp = await client.post(
        "/api/admin/orders/ORD_PENDING_001/ship",
        json={"carrier": "SF"},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_ship_order_forbidden_operator(client: AsyncClient, operator_auth: str):
    """Operators cannot ship orders."""
    order_id = _seed_paid_order()
    resp = await client.post(
        f"/api/admin/orders/{order_id}/ship",
        json={"carrier": "SF"},
        params={"authorization": operator_auth},
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_admin_activities_with_orders(client: AsyncClient, admin_auth: str):
    """Activities should include order-based entries when orders exist."""
    _seed_paid_order()
    resp = await client.get("/api/admin/activities",
                            params={"authorization": admin_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1
    types = [item.get("type") for item in data["items"]]
    tag_keys = [item.get("tag_key") for item in data["items"]]
    assert any(t in ("order_paid", "order_new", "stock_warning") for t in types)
    assert any(tag in ("admin_tag_orders", "product_stock") for tag in tag_keys)
    assert any(item.get("title_key") for item in data["items"])
    assert any(item.get("subtitle_key") for item in data["items"])


@pytest.mark.asyncio
async def test_admin_activities_filter_by_tag_key(client: AsyncClient, admin_auth: str):
    _seed_paid_order()
    resp = await client.get(
        "/api/admin/activities",
        params={"authorization": admin_auth, "filter": "admin_tag_orders"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["items"]
    assert all(item.get("tag_key") == "admin_tag_orders" for item in data["items"])


@pytest.mark.asyncio
async def test_admin_activities_unauthorized(client: AsyncClient):
    resp = await client.get("/api/admin/activities")
    assert resp.status_code == 401
