# -*- coding: utf-8 -*-
"""Auth endpoint tests (10 cases)"""
import pytest
from httpx import AsyncClient


class FakeRedis:
    def __init__(self):
        self.values: dict[str, str] = {}
        self.expiry: dict[str, int] = {}

    def exists(self, key: str) -> bool:
        return key in self.values

    def ttl(self, key: str) -> int:
        return self.expiry.get(key, 60)

    def get(self, key: str):
        return self.values.get(key)

    def setex(self, key: str, seconds: int, value: str):
        self.values[key] = str(value)
        self.expiry[key] = seconds

    def incr(self, key: str) -> int:
        next_value = int(self.values.get(key, "0")) + 1
        self.values[key] = str(next_value)
        return next_value

    def expire(self, key: str, seconds: int):
        self.expiry[key] = seconds

    def delete(self, key: str):
        self.values.pop(key, None)
        self.expiry.pop(key, None)


# ---- Admin Login ----

@pytest.mark.asyncio
async def test_admin_login_success(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "username": "18937766669",
        "password": "admin123",
        "type": "admin",
        "captcha": "8888",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert "token" in data
    assert data["user"]["is_admin"] is True
    assert data["user"]["user_type"] == "admin"


@pytest.mark.asyncio
async def test_admin_login_wrong_password(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "username": "18937766669",
        "password": "wrong_password",
        "type": "admin",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_admin_login_wrong_captcha(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "username": "18937766669",
        "password": "admin123",
        "type": "admin",
        "captcha": "1234",
    })
    assert resp.status_code == 400


# ---- Operator Login ----

@pytest.mark.asyncio
async def test_operator_login_success(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "username": "1",
        "password": "op123456",
        "type": "operator",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["user"]["is_admin"] is False
    assert data["user"]["user_type"] == "operator"


@pytest.mark.asyncio
async def test_operator_login_wrong_password(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "username": "1",
        "password": "wrongpwd",
        "type": "operator",
    })
    assert resp.status_code == 401


# ---- Customer SMS Login ----

@pytest.mark.asyncio
async def test_customer_sms_login_success(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "phone": "13800009876",
        "code": "888888",
        "type": "customer_sms",
        "login_type": "customer_sms",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["user"]["user_type"] == "customer"


@pytest.mark.asyncio
async def test_customer_sms_login_wrong_code(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={
        "phone": "13800009876",
        "code": "1111",
        "type": "customer_sms",
        "login_type": "customer_sms",
    })
    assert resp.status_code == 400


# ---- Logout ----

@pytest.mark.asyncio
async def test_logout(client: AsyncClient, admin_auth: str):
    # Verify profile works
    resp1 = await client.get("/api/users/profile",
                             params={"authorization": admin_auth})
    assert resp1.status_code == 200

    # Logout
    resp2 = await client.post("/api/auth/logout",
                              params={"authorization": admin_auth})
    assert resp2.status_code == 200
    assert resp2.json()["success"] is True

    # With JWT enabled, the token is still decodable via JWT (stateless).
    # So the response may still be 200. We just verify logout succeeded.


@pytest.mark.asyncio
async def test_profile_accepts_authorization_header(client: AsyncClient, admin_auth: str):
    resp = await client.get(
        "/api/users/profile",
        headers={"Authorization": admin_auth},
    )
    assert resp.status_code == 200
    assert resp.json()["user_type"] == "admin"


# ---- Token Refresh ----

@pytest.mark.asyncio
async def test_refresh_token(client: AsyncClient, admin_auth: str):
    login_resp = await client.post("/api/auth/login", json={
        "username": "18937766669",
        "password": "admin123",
        "type": "admin",
        "captcha": "8888",
    })
    assert login_resp.status_code == 200
    refresh_token = login_resp.json()["refresh_token"]

    resp = await client.post("/api/auth/refresh",
                             headers={"Authorization": f"Bearer {refresh_token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert "token" in data
    assert "refresh_token" in data

    # New token should work
    new_auth = f"Bearer {data['token']}"
    resp3 = await client.get("/api/users/profile",
                             params={"authorization": new_auth})
    assert resp3.status_code == 200


@pytest.mark.asyncio
async def test_refresh_rejects_access_token(client: AsyncClient, admin_auth: str):
    resp = await client.post("/api/auth/refresh",
                             params={"authorization": admin_auth})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_sms_verify_requires_matching_action(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
):
    from services import sms_service

    fake_redis = FakeRedis()
    monkeypatch.setattr(sms_service, "REDIS_AVAILABLE", True)
    monkeypatch.setattr(sms_service, "redis_client", fake_redis)

    send_resp = await client.post("/api/auth/send-sms", json={
        "phone": "13800001234",
        "action": "register",
    })
    assert send_resp.status_code == 200
    code = send_resp.json()["message"].split("：")[-1]

    wrong_action_resp = await client.post("/api/auth/verify-sms", json={
        "phone": "13800001234",
        "code": code,
        "action": "login",
    })
    assert wrong_action_resp.status_code == 400

    correct_action_resp = await client.post("/api/auth/verify-sms", json={
        "phone": "13800001234",
        "code": code,
        "action": "register",
    })
    assert correct_action_resp.status_code == 200


# ---- Unauthenticated ----

@pytest.mark.asyncio
async def test_unauthenticated_access(client: AsyncClient):
    resp = await client.get("/api/users/profile")
    assert resp.status_code == 401

    resp2 = await client.get("/api/orders")
    assert resp2.status_code == 401
