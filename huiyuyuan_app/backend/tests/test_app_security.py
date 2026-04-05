# -*- coding: utf-8 -*-
"""Application security regression tests."""

import pytest
from httpx import AsyncClient

from services import login_guard_service


class FakeRedis:
    def __init__(self):
        self.values: dict[str, str] = {}
        self.expiry: dict[str, int] = {}

    def get(self, key: str):
        return self.values.get(key)

    def incr(self, key: str) -> int:
        next_value = int(self.values.get(key, "0")) + 1
        self.values[key] = str(next_value)
        return next_value

    def expire(self, key: str, seconds: int):
        self.expiry[key] = seconds

    def delete(self, key: str):
        self.values.pop(key, None)
        self.expiry.pop(key, None)


@pytest.mark.asyncio
async def test_health_endpoint_includes_security_headers(client: AsyncClient):
    resp = await client.get("/api/health")

    assert resp.status_code == 200
    assert resp.headers["x-frame-options"] == "DENY"
    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["referrer-policy"] == "strict-origin-when-cross-origin"
    assert resp.headers["permissions-policy"] == "camera=(), microphone=(), geolocation=()"


@pytest.mark.asyncio
async def test_auth_login_responses_disable_caching(client: AsyncClient):
    resp = await client.post(
        "/api/auth/login",
        json={
            "username": "18937766669",
            "password": "admin123",
            "type": "admin",
            "captcha": "8888",
        },
    )

    assert resp.status_code == 200
    assert resp.headers["cache-control"] == "no-store"
    assert resp.headers["pragma"] == "no-cache"


@pytest.mark.asyncio
async def test_password_login_is_throttled_after_repeated_failures(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
):
    fake_redis = FakeRedis()
    monkeypatch.setattr(login_guard_service, "REDIS_AVAILABLE", True)
    monkeypatch.setattr(login_guard_service, "redis_client", fake_redis)

    payload = {
        "username": "18937766669",
        "password": "wrong_password",
        "type": "admin",
    }

    for _ in range(8):
        resp = await client.post("/api/auth/login", json=payload)
        assert resp.status_code == 401

    throttled = await client.post("/api/auth/login", json=payload)
    assert throttled.status_code == 429
    assert "15" in throttled.json()["detail"]


@pytest.mark.asyncio
async def test_successful_password_login_clears_credential_throttle(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
):
    fake_redis = FakeRedis()
    monkeypatch.setattr(login_guard_service, "REDIS_AVAILABLE", True)
    monkeypatch.setattr(login_guard_service, "redis_client", fake_redis)

    failed_payload = {
        "username": "18937766669",
        "password": "wrong_password",
        "type": "admin",
    }

    for _ in range(3):
        resp = await client.post("/api/auth/login", json=failed_payload)
        assert resp.status_code == 401

    success = await client.post(
        "/api/auth/login",
        json={
            "username": "18937766669",
            "password": "admin123",
            "type": "admin",
            "captcha": "8888",
        },
    )
    assert success.status_code == 200

    another_failure = await client.post("/api/auth/login", json=failed_payload)
    assert another_failure.status_code == 401
