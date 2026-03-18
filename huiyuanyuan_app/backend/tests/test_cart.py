# -*- coding: utf-8 -*-
"""Cart endpoint tests (7 cases)"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_cart_empty_initially(client: AsyncClient, customer_auth: str):
    resp = await client.get("/api/cart",
                            params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["total"] == 0


@pytest.mark.asyncio
async def test_add_to_cart(client: AsyncClient, customer_auth: str):
    resp = await client.post("/api/cart", json={
        "product_id": "HYY-HT001", "quantity": 2,
    }, params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["success"] is True

    r2 = await client.get("/api/cart",
                          params={"authorization": customer_auth})
    assert r2.json()["total"] == 1


@pytest.mark.asyncio
async def test_add_duplicate_increases_quantity(client: AsyncClient,
                                                customer_auth: str):
    auth = {"authorization": customer_auth}
    await client.post("/api/cart",
                      json={"product_id": "HYY-HT001", "quantity": 1},
                      params=auth)
    await client.post("/api/cart",
                      json={"product_id": "HYY-HT001", "quantity": 3},
                      params=auth)

    r = await client.get("/api/cart", params=auth)
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["quantity"] == 4


@pytest.mark.asyncio
async def test_add_nonexistent_product(client: AsyncClient, customer_auth: str):
    resp = await client.post("/api/cart",
                             json={"product_id": "FAKE", "quantity": 1},
                             params={"authorization": customer_auth})
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_update_cart_quantity(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}
    await client.post("/api/cart",
                      json={"product_id": "HYY-HT001", "quantity": 1},
                      params=auth)

    resp = await client.put("/api/cart/HYY-HT001",
                            params={**auth, "quantity": 5})
    assert resp.status_code == 200

    r = await client.get("/api/cart", params=auth)
    assert r.json()["items"][0]["quantity"] == 5


@pytest.mark.asyncio
async def test_remove_from_cart(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}
    await client.post("/api/cart",
                      json={"product_id": "HYY-HT001", "quantity": 1},
                      params=auth)

    resp = await client.delete("/api/cart/HYY-HT001", params=auth)
    assert resp.status_code == 200

    r = await client.get("/api/cart", params=auth)
    assert r.json()["total"] == 0


@pytest.mark.asyncio
async def test_clear_cart(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}
    await client.post("/api/cart",
                      json={"product_id": "HYY-HT001", "quantity": 1},
                      params=auth)
    await client.post("/api/cart",
                      json={"product_id": "HYY-FC001", "quantity": 2},
                      params=auth)

    resp = await client.delete("/api/cart", params=auth)
    assert resp.status_code == 200

    r = await client.get("/api/cart", params=auth)
    assert r.json()["total"] == 0
