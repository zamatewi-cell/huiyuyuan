# -*- coding: utf-8 -*-
"""Inventory endpoint tests."""

from datetime import datetime, timezone

import pytest
from httpx import AsyncClient

from store import INVENTORY_TRANSACTIONS_DB, PRODUCTS_DB


@pytest.mark.asyncio
async def test_get_inventory_list_as_admin(client: AsyncClient, admin_auth: str):
    resp = await client.get("/api/inventory", params={"authorization": admin_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) > 0
    first = data[0]
    assert "product_id" in first
    assert "current_stock" in first
    assert "cost_price" in first


@pytest.mark.asyncio
async def test_get_inventory_forbidden_for_operator(client: AsyncClient, operator_auth: str):
    resp = await client.get("/api/inventory", params={"authorization": operator_auth})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_get_inventory_item(client: AsyncClient, admin_auth: str):
    resp = await client.get("/api/inventory/HYY-HT001", params={"authorization": admin_auth})
    assert resp.status_code == 200
    item = resp.json()
    assert item["product_id"] == "HYY-HT001"
    assert item["product_name"]


@pytest.mark.asyncio
async def test_update_inventory_stock(client: AsyncClient, admin_auth: str):
    resp = await client.put(
        "/api/inventory/HYY-HT001/stock",
        json={"current_stock": 321},
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    payload = resp.json()
    assert payload["current_stock"] == 321
    assert PRODUCTS_DB["HYY-HT001"].stock == 321


@pytest.mark.asyncio
async def test_create_inventory_transaction_updates_stock_and_log(
    client: AsyncClient,
    admin_auth: str,
):
    created_at = datetime.now(timezone.utc).isoformat()
    resp = await client.post(
        "/api/inventory/transactions",
        json={
            "id": "TX-TEST-001",
            "product_id": "HYY-HT001",
            "product_name": PRODUCTS_DB["HYY-HT001"].name,
            "type": "stockOut",
            "quantity": 2,
            "stock_before": PRODUCTS_DB["HYY-HT001"].stock,
            "stock_after": PRODUCTS_DB["HYY-HT001"].stock - 2,
            "note": "pytest",
            "operator_name": "QA",
            "created_at": created_at,
        },
        params={"authorization": admin_auth},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == "TX-TEST-001"
    assert data["type"] == "stockOut"
    assert PRODUCTS_DB["HYY-HT001"].stock == data["stock_after"]
    assert INVENTORY_TRANSACTIONS_DB[0]["id"] == "TX-TEST-001"

    list_resp = await client.get(
        "/api/inventory/transactions",
        params={"authorization": admin_auth},
    )
    assert list_resp.status_code == 200
    ids = [item["id"] for item in list_resp.json()]
    assert "TX-TEST-001" in ids


@pytest.mark.asyncio
async def test_inventory_requires_auth(client: AsyncClient):
    resp = await client.get("/api/inventory")
    assert resp.status_code == 401
