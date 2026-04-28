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


@pytest.mark.asyncio
async def test_admin_can_list_operator_accounts(client: AsyncClient, admin_auth: str):
    resp = await client.get(
        "/api/admin/operators",
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200

    data = resp.json()
    assert data["total"] == 10
    first = data["items"][0]
    assert first["id"] == "operator_1"
    assert first["operator_number"] == 1
    assert "shop_radar" in first["permissions"]
    assert first["report"]["operator_id"] == 1


@pytest.mark.asyncio
async def test_admin_can_update_operator_account(client: AsyncClient, admin_auth: str):
    resp = await client.put(
        "/api/admin/operators/operator_3",
        json={
            "username": "测试操作员3",
            "phone": "13800009993",
            "is_active": True,
            "password": "op998877",
            "permissions": ["ai_assistant", "orders"],
        },
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    operator = resp.json()["operator"]
    assert operator["username"] == "测试操作员3"
    assert operator["phone"] == "13800009993"
    assert operator["permissions"] == ["ai_assistant", "orders"]

    login = await client.post(
        "/api/auth/login",
        json={
            "username": "3",
            "password": "op998877",
            "type": "operator",
        },
    )
    assert login.status_code == 200
    assert login.json()["user"]["permissions"] == ["ai_assistant", "orders"]


@pytest.mark.asyncio
async def test_admin_can_disable_operator_login(client: AsyncClient, admin_auth: str):
    resp = await client.put(
        "/api/admin/operators/operator_4",
        json={"is_active": False},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    assert resp.json()["operator"]["is_active"] is False

    login = await client.post(
        "/api/auth/login",
        json={
            "username": "4",
            "password": "op123456",
            "type": "operator",
        },
    )
    assert login.status_code == 401


@pytest.mark.asyncio
async def test_permission_change_revokes_existing_operator_session(
    client: AsyncClient,
    admin_auth: str,
    operator_auth: str,
):
    resp = await client.put(
        "/api/admin/operators/operator_1",
        json={"permissions": ["orders"]},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    assert resp.json()["operator"]["permissions"] == ["orders"]

    old_session = await client.get(
        "/api/orders",
        params={"authorization": operator_auth},
    )
    assert old_session.status_code == 401


@pytest.mark.asyncio
async def test_operator_cannot_manage_operator_accounts(
    client: AsyncClient,
    operator_auth: str,
):
    resp = await client.put(
        "/api/admin/operators/operator_2",
        json={"permissions": ["orders"]},
        params={"authorization": operator_auth},
    )
    assert resp.status_code == 403
