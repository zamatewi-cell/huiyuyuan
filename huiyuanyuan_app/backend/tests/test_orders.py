# -*- coding: utf-8 -*-
"""Order endpoint tests (14 cases)"""
import asyncio
import pytest
from httpx import AsyncClient


async def _create_order(client, auth, address_id, product_id="HYY-HT001",
                        qty=1):
    resp = await client.post("/api/orders", json={
        "items": [{"product_id": product_id, "quantity": qty}],
        "address_id": address_id,
        "payment_method": "wechat",
    }, params={"authorization": auth})
    assert resp.status_code == 200, resp.text
    return resp.json()


async def _pay_and_wait(client, order_id, auth):
    """Pay an order and wait for the auto-callback (3s)."""
    await client.post(f"/api/orders/{order_id}/pay",
                      json={}, params={"authorization": auth})
    await asyncio.sleep(3.5)
    await client.get(f"/api/orders/{order_id}/pay-status",
                     params={"authorization": auth})


# ---- Create Order ----

@pytest.mark.asyncio
async def test_create_order(client: AsyncClient, customer_auth: str,
                            sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    assert order["status"] == "pending"
    assert order["total_amount"] > 0
    assert len(order["items"]) == 1


@pytest.mark.asyncio
async def test_create_order_stock_deduction(client: AsyncClient,
                                            customer_auth: str,
                                            sample_address_id: str):
    before = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    await _create_order(client, customer_auth, sample_address_id, qty=3)
    after = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert after == before - 3


@pytest.mark.asyncio
async def test_create_order_insufficient_stock(client: AsyncClient,
                                               customer_auth: str,
                                               sample_address_id: str):
    resp = await client.post("/api/orders", json={
        "items": [{"product_id": "HYY-HT001", "quantity": 99999}],
        "address_id": sample_address_id,
    }, params={"authorization": customer_auth})
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_create_order_invalid_product(client: AsyncClient,
                                            customer_auth: str,
                                            sample_address_id: str):
    resp = await client.post("/api/orders", json={
        "items": [{"product_id": "NONEXISTENT", "quantity": 1}],
        "address_id": sample_address_id,
    }, params={"authorization": customer_auth})
    assert resp.status_code == 400


# ---- Order List & Detail ----

@pytest.mark.asyncio
async def test_get_orders_list(client: AsyncClient, customer_auth: str,
                               sample_address_id: str):
    await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get("/api/orders",
                            params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


@pytest.mark.asyncio
async def test_get_order_detail(client: AsyncClient, customer_auth: str,
                                sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get(f"/api/orders/{order['id']}",
                            params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["id"] == order["id"]


@pytest.mark.asyncio
async def test_order_isolation(client: AsyncClient, customer_auth: str,
                               operator_auth: str, sample_address_id: str):
    """Operator should not see customer's order."""
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get(f"/api/orders/{order['id']}",
                            params={"authorization": operator_auth})
    assert resp.status_code == 403


# ---- Payment ----

@pytest.mark.asyncio
async def test_pay_order(client: AsyncClient, customer_auth: str,
                         sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.post(f"/api/orders/{order['id']}/pay",
                             json={"method": "wechat"},
                             params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["status"] == "pending"
    assert "payment_id" in resp.json()


@pytest.mark.asyncio
async def test_pay_cancelled_order_fails(client: AsyncClient,
                                         customer_auth: str,
                                         sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    await client.post(f"/api/orders/{order['id']}/cancel",
                      params={"authorization": customer_auth})
    resp = await client.post(f"/api/orders/{order['id']}/pay",
                             json={},
                             params={"authorization": customer_auth})
    assert resp.status_code == 400


# ---- Cancel ----

@pytest.mark.asyncio
async def test_cancel_order_restores_stock(client: AsyncClient,
                                           customer_auth: str,
                                           sample_address_id: str):
    before = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    order = await _create_order(client, customer_auth, sample_address_id, qty=2)
    mid = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert mid == before - 2

    await client.post(f"/api/orders/{order['id']}/cancel",
                      json={"reason": "test cancel"},
                      params={"authorization": customer_auth})
    after = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert after == before


# ---- Ship (admin only) ----

@pytest.mark.asyncio
async def test_ship_order_admin_only(client: AsyncClient, customer_auth: str,
                                     admin_auth: str, sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_wait(client, order["id"], customer_auth)

    # Customer cannot ship
    resp_c = await client.post(f"/api/admin/orders/{order['id']}/ship",
                               json={"carrier": "SF", "tracking_number": "T1"},
                               params={"authorization": customer_auth})
    assert resp_c.status_code == 403

    # Admin can ship
    resp_a = await client.post(f"/api/admin/orders/{order['id']}/ship",
                               json={"carrier": "SF",
                                     "tracking_number": "SF123456789"},
                               params={"authorization": admin_auth})
    assert resp_a.status_code == 200
    assert resp_a.json()["tracking_number"] == "SF123456789"


# ---- Confirm Receipt ----

@pytest.mark.asyncio
async def test_confirm_receipt(client: AsyncClient, customer_auth: str,
                               admin_auth: str, sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_wait(client, order["id"], customer_auth)
    await client.post(f"/api/admin/orders/{order['id']}/ship",
                      json={"carrier": "SF"},
                      params={"authorization": admin_auth})

    resp = await client.post(f"/api/orders/{order['id']}/confirm-receipt",
                             params={"authorization": customer_auth})
    assert resp.status_code == 200

    detail = await client.get(f"/api/orders/{order['id']}",
                              params={"authorization": customer_auth})
    assert detail.json()["status"] == "completed"


# ---- Refund ----

@pytest.mark.asyncio
async def test_refund_paid_order(client: AsyncClient, customer_auth: str,
                                 sample_address_id: str):
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_wait(client, order["id"], customer_auth)

    resp = await client.post(f"/api/orders/{order['id']}/refund",
                             json={"reason": "no longer needed"},
                             params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["refund_amount"] == order["total_amount"]


# ---- Stats ----

@pytest.mark.asyncio
async def test_order_stats(client: AsyncClient, customer_auth: str,
                           sample_address_id: str):
    await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get("/api/orders/stats",
                            params={"authorization": customer_auth})
    assert resp.status_code == 200
    s = resp.json()
    assert s["total"] >= 1
    assert "pending" in s
    assert "paid" in s
