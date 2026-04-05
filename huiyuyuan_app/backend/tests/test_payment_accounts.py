# -*- coding: utf-8 -*-
"""Payment-account endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_payment_account_crud_flow(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}

    create_resp = await client.post(
        "/api/users/payment-accounts",
        json={
            "name": "Main card",
            "type": "bank",
            "account_number": "622233445566",
            "bank_name": "Test Bank",
            "is_active": True,
            "is_default": True,
        },
        params=auth,
    )
    assert create_resp.status_code == 200
    created = create_resp.json()
    assert created["name"] == "Main card"
    assert created["type"] == "bank"
    assert created["is_default"] is True
    account_id = created["id"]

    list_resp = await client.get("/api/users/payment-accounts", params=auth)
    assert list_resp.status_code == 200
    items = list_resp.json()
    assert len(items) == 1
    assert items[0]["id"] == account_id

    update_resp = await client.put(
        f"/api/users/payment-accounts/{account_id}",
        json={
            "name": "WeChat QR",
            "type": "wechat",
            "account_number": "https://example.com/qr.png",
            "bank_name": None,
            "qr_code_url": "https://example.com/qr.png",
            "is_active": False,
            "is_default": True,
        },
        params=auth,
    )
    assert update_resp.status_code == 200
    updated = update_resp.json()
    assert updated["name"] == "WeChat QR"
    assert updated["type"] == "wechat"
    assert updated["is_active"] is False

    delete_resp = await client.delete(
        f"/api/users/payment-accounts/{account_id}",
        params=auth,
    )
    assert delete_resp.status_code == 200
    assert delete_resp.json()["success"] is True

    final_list = await client.get("/api/users/payment-accounts", params=auth)
    assert final_list.status_code == 200
    assert final_list.json() == []


@pytest.mark.asyncio
async def test_payment_account_default_id_is_exposed_in_profile(
    client: AsyncClient,
    customer_auth: str,
):
    auth = {"authorization": customer_auth}

    create_resp = await client.post(
        "/api/users/payment-accounts",
        json={
            "name": "Default Alipay",
            "type": "alipay",
            "account_number": "alipay_001",
            "is_active": True,
            "is_default": True,
        },
        params=auth,
    )
    assert create_resp.status_code == 200
    account_id = create_resp.json()["id"]

    profile_resp = await client.get("/api/users/profile", params=auth)
    assert profile_resp.status_code == 200
    assert profile_resp.json()["payment_account_id"] == account_id


@pytest.mark.asyncio
async def test_payment_account_forbidden_cross_user_delete(
    client: AsyncClient,
    customer_auth: str,
    operator_auth: str,
):
    create_resp = await client.post(
        "/api/users/payment-accounts",
        json={
            "name": "Customer card",
            "type": "bank",
            "account_number": "123456",
            "is_active": True,
            "is_default": True,
        },
        params={"authorization": customer_auth},
    )
    assert create_resp.status_code == 200
    account_id = create_resp.json()["id"]

    delete_resp = await client.delete(
        f"/api/users/payment-accounts/{account_id}",
        params={"authorization": operator_auth},
    )
    assert delete_resp.status_code == 403


@pytest.mark.asyncio
async def test_payment_accounts_requires_auth(client: AsyncClient):
    resp = await client.get("/api/users/payment-accounts")
    assert resp.status_code == 401
