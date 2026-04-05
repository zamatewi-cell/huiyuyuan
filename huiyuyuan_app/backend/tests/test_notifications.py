# -*- coding: utf-8 -*-
"""Notification endpoint tests."""
import pytest
from httpx import AsyncClient

from routers.notifications import _derive_notification_localization


@pytest.mark.asyncio
async def test_register_device(client: AsyncClient, customer_auth: str):
    resp = await client.post("/api/notifications/register", json={
        "device_token": "test_token_abc123",
        "platform": "android",
        "settings": {"push_enabled": True},
    }, params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["success"] is True


@pytest.mark.asyncio
async def test_register_device_unauthorized(client: AsyncClient):
    resp = await client.post("/api/notifications/register", json={
        "device_token": "test_token_xyz",
        "platform": "ios",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_get_notifications(client: AsyncClient, customer_auth: str):
    """Memory fallback returns demo notifications."""
    resp = await client.get("/api/notifications",
                            params={"authorization": customer_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert "total" in data
    assert "unread" in data
    assert isinstance(data["items"], list)
    assert data["items"][0]["title_key"]
    assert data["items"][0]["body_key"]


@pytest.mark.asyncio
async def test_mark_notification_read(client: AsyncClient, customer_auth: str):
    """Memory fallback always returns success for mark-read."""
    resp = await client.post("/api/notifications/n001/read",
                             params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["success"] is True


@pytest.mark.asyncio
async def test_mark_all_read(client: AsyncClient, customer_auth: str):
    resp = await client.post("/api/notifications/read-all",
                             params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["success"] is True


@pytest.mark.asyncio
async def test_get_notifications_unauthorized(client: AsyncClient):
    resp = await client.get("/api/notifications")
    assert resp.status_code == 401


def test_derive_notification_localization_for_order_created():
    localized = _derive_notification_localization(
        ntype="order_created",
        title="订单 ORD20260404001 已创建",
        body="订单 ORD20260404001 已创建",
        ref_id="ORD20260404001",
    )

    assert localized["title_key"] == "notification_order_created_title"
    assert localized["body_key"] == "notification_order_created_body"
    assert localized["title_args"] is None
    assert localized["body_args"] == {"order_id": "ORD20260404001"}


def test_derive_notification_localization_for_order_shipped_tracking():
    localized = _derive_notification_localization(
        ntype="order_shipped",
        title="订单已发货",
        body="您的订单已发货，顺丰 运单号 SF12345678",
        ref_id="ORD20260404002",
    )

    assert localized["title_key"] == "notification_order_shipped_title"
    assert localized["body_key"] == "notification_order_shipped_body_with_tracking"
    assert localized["body_args"] == {
        "carrier": "顺丰",
        "tracking": "SF12345678",
    }


def test_derive_notification_localization_for_payment_success():
    localized = _derive_notification_localization(
        ntype="payment_success",
        title="支付已确认",
        body="订单 ORD20260404003 已确认到账",
        ref_id="ORD20260404003",
    )

    assert localized["title_key"] == "notification_payment_success_title"
    assert localized["body_key"] == "notification_payment_success_body"
    assert localized["body_args"] == {"order_id": "ORD20260404003"}
