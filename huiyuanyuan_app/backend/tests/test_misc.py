# -*- coding: utf-8 -*-
"""Miscellaneous endpoint tests — Favorites, Reviews, Profile, Admin, Address (13 cases)"""
import pytest
from httpx import AsyncClient


# ===================== Favorites =====================

@pytest.mark.asyncio
async def test_favorites_empty(client: AsyncClient, customer_auth: str):
    resp = await client.get("/api/favorites",
                            params={"authorization": customer_auth})
    assert resp.status_code == 200
    assert resp.json()["total"] == 0


@pytest.mark.asyncio
async def test_add_and_list_favorite(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}
    resp = await client.post("/api/favorites/HYY-HT001", params=auth)
    assert resp.status_code == 200
    assert resp.json()["success"] is True

    r = await client.get("/api/favorites", params=auth)
    assert r.json()["total"] == 1
    assert r.json()["items"][0]["id"] == "HYY-HT001"


@pytest.mark.asyncio
async def test_remove_favorite(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}
    await client.post("/api/favorites/HYY-HT001", params=auth)

    resp = await client.delete("/api/favorites/HYY-HT001", params=auth)
    assert resp.status_code == 200

    r = await client.get("/api/favorites", params=auth)
    assert r.json()["total"] == 0


@pytest.mark.asyncio
async def test_favorite_nonexistent_product(client: AsyncClient, customer_auth: str):
    resp = await client.post("/api/favorites/NONEXISTENT",
                             params={"authorization": customer_auth})
    assert resp.status_code == 404


# ===================== Reviews =====================

@pytest.mark.asyncio
async def test_create_review(client: AsyncClient, customer_auth: str):
    resp = await client.post("/api/reviews", json={
        "product_id": "HYY-HT001",
        "order_id": "ORD_FAKE_001",
        "rating": 5,
        "content": "Very good jade bracelet!",
        "images": [],
    }, params={"authorization": customer_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert data["rating"] == 5
    assert data["product_id"] == "HYY-HT001"


@pytest.mark.asyncio
async def test_get_product_reviews(client: AsyncClient, customer_auth: str):
    # Create a review first
    await client.post("/api/reviews", json={
        "product_id": "HYY-HT001",
        "order_id": "ORD_FAKE_001",
        "rating": 4,
        "content": "Nice quality",
    }, params={"authorization": customer_auth})

    resp = await client.get("/api/products/HYY-HT001/reviews")
    assert resp.status_code == 200
    reviews = resp.json()
    assert len(reviews) >= 1
    assert reviews[0]["product_id"] == "HYY-HT001"


# ===================== User Profile =====================

@pytest.mark.asyncio
async def test_get_profile(client: AsyncClient, admin_auth: str):
    resp = await client.get("/api/users/profile",
                            params={"authorization": admin_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == "admin_001"
    assert data["is_admin"] is True


@pytest.mark.asyncio
async def test_update_profile(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}
    resp = await client.put("/api/users/profile",
                            json={"username": "NewName"},
                            params=auth)
    assert resp.status_code == 200
    assert resp.json()["user"]["username"] == "NewName"


# ===================== Admin Dashboard =====================

@pytest.mark.asyncio
async def test_admin_dashboard(client: AsyncClient, admin_auth: str):
    resp = await client.get("/api/admin/dashboard",
                            params={"authorization": admin_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert "total_orders" in data
    assert "total_products" in data
    assert data["total_products"] > 0
    assert "operator_count" in data


@pytest.mark.asyncio
async def test_admin_dashboard_forbidden(client: AsyncClient, operator_auth: str):
    resp = await client.get("/api/admin/dashboard",
                            params={"authorization": operator_auth})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_admin_activities(client: AsyncClient, admin_auth: str):
    resp = await client.get("/api/admin/activities",
                            params={"authorization": admin_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert "total" in data


# ===================== Address CRUD =====================

@pytest.mark.asyncio
async def test_address_crud(client: AsyncClient, customer_auth: str):
    auth = {"authorization": customer_auth}

    # Create
    resp = await client.post("/api/users/addresses", json={
        "recipient_name": "Zhang San",
        "phone_number": "13800001234",
        "province": "Zhejiang",
        "city": "Hangzhou",
        "district": "Xihu",
        "detail_address": "No.100 Test Road",
        "is_default": True,
    }, params=auth)
    assert resp.status_code == 200
    addr = resp.json()
    addr_id = addr["id"]
    assert addr["recipient_name"] == "Zhang San"

    # List
    resp_list = await client.get("/api/users/addresses", params=auth)
    assert resp_list.status_code == 200
    assert len(resp_list.json()) >= 1

    # Update
    resp_update = await client.put(f"/api/users/addresses/{addr_id}", json={
        "recipient_name": "Li Si",
        "phone_number": "13800005678",
        "province": "Beijing",
        "city": "Beijing",
        "district": "Haidian",
        "detail_address": "No.200 New Road",
    }, params=auth)
    assert resp_update.status_code == 200
    assert resp_update.json()["recipient_name"] == "Li Si"

    # Delete
    resp_del = await client.delete(f"/api/users/addresses/{addr_id}", params=auth)
    assert resp_del.status_code == 200

    # Verify deleted
    resp_final = await client.get("/api/users/addresses", params=auth)
    ids = [a["id"] for a in resp_final.json()]
    assert addr_id not in ids
