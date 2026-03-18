# -*- coding: utf-8 -*-
"""Notification endpoint tests (6 cases)"""
import pytest
from httpx import AsyncClient


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
