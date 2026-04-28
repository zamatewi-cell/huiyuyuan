# -*- coding: utf-8 -*-
"""Order endpoint tests."""

import asyncio

import pytest
from httpx import AsyncClient
from routers.orders import _build_notification_payload


async def _create_admin_payment_account(
    client: AsyncClient,
    auth: str,
    account_type: str = "wechat",
):
    payload = {
        "name": f"平台{account_type}收款",
        "type": account_type,
        "account_number": "platform-account",
        "bank_name": "HYY Bank" if account_type == "bank" else None,
        "qr_code_url": f"https://example.com/{account_type}.png",
        "is_active": True,
        "is_default": True,
    }
    resp = await client.post(
        "/api/users/payment-accounts",
        json=payload,
        params={"authorization": auth},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()


async def _create_order(
    client,
    auth,
    address_id,
    product_id="HYY-HT001",
    qty=1,
):
    resp = await client.post(
        "/api/orders",
        json={
            "items": [{"product_id": product_id, "quantity": qty}],
            "address_id": address_id,
            "payment_method": "wechat",
        },
        params={"authorization": auth},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()


async def _pay_and_confirm(client, order_id, auth, admin_auth):
    await client.post(
        f"/api/orders/{order_id}/pay",
        json={"method": "wechat"},
        params={"authorization": auth},
    )
    await asyncio.sleep(0.1)
    await client.post(
        f"/api/admin/orders/{order_id}/confirm-payment",
        json={},
        params={"authorization": admin_auth},
    )


async def _upload_voucher(
    client: AsyncClient,
    payment_id: str,
    auth: str,
    voucher_url: str = "https://example.com/voucher.png",
):
    resp = await client.post(
        f"/api/payments/{payment_id}/upload-voucher",
        params={
            "authorization": auth,
            "voucher_url": voucher_url,
        },
    )
    assert resp.status_code == 200, resp.text
    return resp.json()


async def _login_operator_with_permissions(
    client: AsyncClient,
    admin_auth: str,
    permissions: list[str],
) -> str:
    resp = await client.put(
        "/api/admin/operators/operator_1",
        json={"permissions": permissions},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200

    login = await client.post(
        "/api/auth/login",
        json={
            "username": "1",
            "password": "op123456",
            "type": "operator",
        },
    )
    assert login.status_code == 200
    return f"Bearer {login.json()['token']}"


def test_build_notification_payload_for_order_created():
    payload = _build_notification_payload(
        {
            "type": "order_created",
            "order_id": "ORD20260404001",
            "message": "订单 ORD20260404001 已创建",
        }
    )

    assert payload["title"] == "订单已创建"
    assert payload["body"] == "订单 ORD20260404001 已创建"
    assert payload["title_key"] == "notification_order_created_title"
    assert payload["body_key"] == "notification_order_created_body"
    assert payload["body_args"] == {"order_id": "ORD20260404001"}


def test_build_notification_payload_for_order_shipped():
    payload = _build_notification_payload(
        {
            "type": "order_shipped",
            "order_id": "ORD20260404002",
            "carrier": "顺丰",
            "tracking_number": "SF12345678",
            "message": "您的订单已发货，顺丰 运单号 SF12345678",
        }
    )

    assert payload["title"] == "订单已发货"
    assert payload["title_key"] == "notification_order_shipped_title"
    assert payload["body_key"] == "notification_order_shipped_body_with_tracking"
    assert payload["body_args"] == {
        "carrier": "顺丰",
        "tracking": "SF12345678",
    }


def test_build_notification_payload_for_payment_success():
    payload = _build_notification_payload(
        {
            "type": "payment_success",
            "order_id": "ORD20260404003",
            "message": "订单 ORD20260404003 已确认到账",
        }
    )

    assert payload["title"] == "支付已确认"
    assert payload["body"] == "订单 ORD20260404003 已确认到账"
    assert payload["title_key"] == "notification_payment_success_title"
    assert payload["body_key"] == "notification_payment_success_body"
    assert payload["body_args"] == {"order_id": "ORD20260404003"}


# ---- Create Order ----


@pytest.mark.asyncio
async def test_create_order(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    order = await _create_order(client, customer_auth, sample_address_id)
    assert order["status"] == "pending"
    assert order["total_amount"] > 0
    assert len(order["items"]) == 1


@pytest.mark.asyncio
async def test_create_order_stock_deduction(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    before = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    await _create_order(client, customer_auth, sample_address_id, qty=3)
    after = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert after == before - 3


@pytest.mark.asyncio
async def test_create_order_rejects_non_positive_quantity(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    before = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    resp = await client.post(
        "/api/orders",
        json={
            "items": [{"product_id": "HYY-HT001", "quantity": -1}],
            "address_id": sample_address_id,
        },
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 422
    after = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert after == before


@pytest.mark.asyncio
async def test_create_order_insufficient_stock(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    resp = await client.post(
        "/api/orders",
        json={
            "items": [{"product_id": "HYY-HT001", "quantity": 99999}],
            "address_id": sample_address_id,
        },
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_create_order_invalid_product(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    resp = await client.post(
        "/api/orders",
        json={
            "items": [{"product_id": "NONEXISTENT", "quantity": 1}],
            "address_id": sample_address_id,
        },
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 400


# ---- Order List & Detail ----


@pytest.mark.asyncio
async def test_get_orders_list(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get(
        "/api/orders",
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


@pytest.mark.asyncio
async def test_get_order_detail(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200
    assert resp.json()["id"] == order["id"]


@pytest.mark.asyncio
async def test_order_isolation(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    order = await _create_order(client, customer_auth, sample_address_id)
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["shop_radar"],
    )
    resp = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": operator_auth},
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_admin_can_list_all_orders(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get("/api/orders", params={"authorization": admin_auth})
    assert resp.status_code == 200
    order_ids = {item["id"] for item in resp.json()}
    assert order["id"] in order_ids


@pytest.mark.asyncio
async def test_operator_without_order_permission_is_forbidden(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_order(client, customer_auth, sample_address_id)
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["shop_radar"],
    )

    resp = await client.get("/api/orders", params={"authorization": operator_auth})

    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_operator_with_order_view_can_list_and_read_orders(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    order = await _create_order(client, customer_auth, sample_address_id)
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["orders"],
    )

    list_resp = await client.get("/api/orders", params={"authorization": operator_auth})
    assert list_resp.status_code == 200
    assert order["id"] in {item["id"] for item in list_resp.json()}

    detail_resp = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": operator_auth},
    )
    assert detail_resp.status_code == 200

    forbidden = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": operator_auth},
    )
    assert forbidden.status_code == 403


# ---- Payment ----


@pytest.mark.asyncio
async def test_pay_order(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "pending"
    assert "payment_id" in data
    assert data["payment_account"]["type"] == "wechat"


@pytest.mark.asyncio
async def test_pay_status_stays_pending_until_admin_confirms(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)

    pay_resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert pay_resp.status_code == 200

    await asyncio.sleep(3.5)
    status_resp = await client.get(
        f"/api/orders/{order['id']}/pay-status",
        params={"authorization": customer_auth},
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "pending"

    confirm_resp = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": admin_auth},
    )
    assert confirm_resp.status_code == 200

    confirmed_status = await client.get(
        f"/api/orders/{order['id']}/pay-status",
        params={"authorization": customer_auth},
    )
    assert confirmed_status.status_code == 200
    assert confirmed_status.json()["status"] == "confirmed"

    detail = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": customer_auth},
    )
    assert detail.json()["status"] == "paid"


@pytest.mark.asyncio
async def test_confirm_payment_admin_only(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )

    forbidden = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": customer_auth},
    )
    assert forbidden.status_code == 403

    allowed = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": admin_auth},
    )
    assert allowed.status_code == 200


@pytest.mark.asyncio
async def test_operator_with_order_manage_can_ship_after_payment_confirmed(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["order_manage"],
    )

    confirm_resp = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": operator_auth},
    )
    assert confirm_resp.status_code == 403

    admin_confirm_resp = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": admin_auth},
    )
    assert admin_confirm_resp.status_code == 200

    ship_resp = await client.post(
        f"/api/admin/orders/{order['id']}/ship",
        json={"carrier": "SF", "tracking_number": "SF220000000001"},
        params={"authorization": operator_auth},
    )
    assert ship_resp.status_code == 200


@pytest.mark.asyncio
async def test_operator_with_payment_reconcile_can_confirm_but_not_ship(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["payment_reconcile"],
    )

    review_resp = await client.get(
        "/api/payments/admin/reconciliation",
        params={"authorization": operator_auth},
    )
    assert review_resp.status_code == 200
    assert any(item["order_id"] == order["id"] for item in review_resp.json()["payments"])

    confirm_resp = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": operator_auth},
    )
    assert confirm_resp.status_code == 200

    ship_resp = await client.post(
        f"/api/admin/orders/{order['id']}/ship",
        json={"carrier": "SF", "tracking_number": "SF220000000002"},
        params={"authorization": operator_auth},
    )
    assert ship_resp.status_code == 403


@pytest.mark.asyncio
async def test_operator_with_payment_exception_permission_can_mark_dispute(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    pay_resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert pay_resp.status_code == 200
    payment_id = pay_resp.json()["payment_id"]
    await _upload_voucher(client, payment_id, customer_auth)
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["payment_exception_mark"],
    )

    review_resp = await client.get(
        "/api/payments/admin/reconciliation",
        params={"authorization": operator_auth},
    )
    assert review_resp.status_code == 200
    assert any(item["payment_id"] == payment_id for item in review_resp.json()["payments"])

    dispute_resp = await client.post(
        f"/api/payments/admin/{payment_id}/dispute",
        params={"authorization": operator_auth, "reason": "voucher mismatch"},
    )
    assert dispute_resp.status_code == 200
    assert dispute_resp.json()["payment"]["status"] == "disputed"

    detail = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": customer_auth},
    )
    assert detail.status_code == 200
    assert detail.json()["payment_record_status"] == "disputed"
    assert "voucher mismatch" in detail.json()["payment_admin_note"]


@pytest.mark.asyncio
async def test_operator_without_payment_permissions_cannot_review_or_mark_dispute(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    pay_resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert pay_resp.status_code == 200
    payment_id = pay_resp.json()["payment_id"]
    await _upload_voucher(client, payment_id, customer_auth)
    operator_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["orders"],
    )

    review_resp = await client.get(
        "/api/payments/admin/reconciliation",
        params={"authorization": operator_auth},
    )
    assert review_resp.status_code == 403

    dispute_resp = await client.post(
        f"/api/payments/admin/{payment_id}/dispute",
        params={"authorization": operator_auth, "reason": "not allowed"},
    )
    assert dispute_resp.status_code == 403


@pytest.mark.asyncio
async def test_operator_with_payment_reconcile_can_confirm_disputed_payment(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    pay_resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert pay_resp.status_code == 200
    payment_id = pay_resp.json()["payment_id"]
    await _upload_voucher(client, payment_id, customer_auth)

    exception_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["payment_exception_mark"],
    )
    dispute_resp = await client.post(
        f"/api/payments/admin/{payment_id}/dispute",
        params={"authorization": exception_auth, "reason": "manual review"},
    )
    assert dispute_resp.status_code == 200

    reconcile_auth = await _login_operator_with_permissions(
        client,
        admin_auth,
        ["payment_reconcile"],
    )
    confirm_resp = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": reconcile_auth},
    )
    assert confirm_resp.status_code == 200

    detail = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": customer_auth},
    )
    assert detail.status_code == 200
    assert detail.json()["status"] == "paid"
    assert detail.json()["payment_record_status"] == "confirmed"


@pytest.mark.asyncio
async def test_confirm_payment_rejects_cancelled_payment_record(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    pay_resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert pay_resp.status_code == 200
    payment_id = pay_resp.json()["payment_id"]

    cancel_resp = await client.post(
        f"/api/payments/{payment_id}/cancel",
        params={"authorization": customer_auth},
    )
    assert cancel_resp.status_code == 200

    confirm_resp = await client.post(
        f"/api/admin/orders/{order['id']}/confirm-payment",
        json={},
        params={"authorization": admin_auth},
    )
    assert confirm_resp.status_code == 400

    detail = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": customer_auth},
    )
    assert detail.status_code == 200
    assert detail.json()["status"] == "pending"


@pytest.mark.asyncio
async def test_pay_without_platform_account_fails(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    order = await _create_order(client, customer_auth, sample_address_id)
    resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={"method": "wechat"},
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_pay_cancelled_order_fails(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await client.post(
        f"/api/orders/{order['id']}/cancel",
        params={"authorization": customer_auth},
    )
    resp = await client.post(
        f"/api/orders/{order['id']}/pay",
        json={},
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 400


# ---- Cancel ----


@pytest.mark.asyncio
async def test_cancel_order_restores_stock(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    before = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    order = await _create_order(client, customer_auth, sample_address_id, qty=2)
    mid = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert mid == before - 2

    await client.post(
        f"/api/orders/{order['id']}/cancel",
        json={"reason": "test cancel"},
        params={"authorization": customer_auth},
    )
    after = (await client.get("/api/products/HYY-HT001")).json()["stock"]
    assert after == before


# ---- Ship (admin only) ----


@pytest.mark.asyncio
async def test_ship_order_admin_only(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_confirm(client, order["id"], customer_auth, admin_auth)

    resp_c = await client.post(
        f"/api/admin/orders/{order['id']}/ship",
        json={"carrier": "SF", "tracking_number": "T1"},
        params={"authorization": customer_auth},
    )
    assert resp_c.status_code == 403

    resp_a = await client.post(
        f"/api/admin/orders/{order['id']}/ship",
        json={"carrier": "SF", "tracking_number": "SF123456789"},
        params={"authorization": admin_auth},
    )
    assert resp_a.status_code == 200
    assert resp_a.json()["tracking_number"] == "SF123456789"


# ---- Confirm Receipt ----


@pytest.mark.asyncio
async def test_confirm_receipt(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_confirm(client, order["id"], customer_auth, admin_auth)
    await client.post(
        f"/api/admin/orders/{order['id']}/ship",
        json={"carrier": "SF"},
        params={"authorization": admin_auth},
    )

    resp = await client.post(
        f"/api/orders/{order['id']}/confirm-receipt",
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200

    detail = await client.get(
        f"/api/orders/{order['id']}",
        params={"authorization": customer_auth},
    )
    assert detail.json()["status"] == "completed"


# ---- Refund ----


@pytest.mark.asyncio
async def test_refund_paid_order(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_confirm(client, order["id"], customer_auth, admin_auth)

    resp = await client.post(
        f"/api/orders/{order['id']}/refund",
        json={"reason": "no longer needed"},
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200
    assert resp.json()["refund_amount"] == order["total_amount"]


@pytest.mark.asyncio
async def test_payment_status_change_is_written_to_customer_audit_log(
    client: AsyncClient,
    customer_auth: str,
    admin_auth: str,
    sample_address_id: str,
):
    await _create_admin_payment_account(client, admin_auth, "wechat")
    order = await _create_order(client, customer_auth, sample_address_id)
    await _pay_and_confirm(client, order["id"], customer_auth, admin_auth)

    audit_resp = await client.get(
        f"/api/payments/admin/audit/{order['user_id']}",
        params={"authorization": admin_auth},
    )
    assert audit_resp.status_code == 200
    actions = [item["action"] for item in audit_resp.json()["logs"]]
    assert "payment_created" in actions
    assert "payment_status_confirmed" in actions


# ---- Stats ----


@pytest.mark.asyncio
async def test_order_stats(
    client: AsyncClient,
    customer_auth: str,
    sample_address_id: str,
):
    await _create_order(client, customer_auth, sample_address_id)
    resp = await client.get(
        "/api/orders/stats",
        params={"authorization": customer_auth},
    )
    assert resp.status_code == 200
    stats = resp.json()
    assert stats["total"] >= 1
    assert "pending" in stats
    assert "paid" in stats
