# -*- coding: utf-8 -*-
"""Product endpoint tests (12 cases)"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_products_list(client: AsyncClient):
    resp = await client.get("/api/products")
    assert resp.status_code == 200
    products = resp.json()
    assert isinstance(products, list)
    assert len(products) > 0
    first = products[0]
    assert "id" in first
    assert "name" in first
    assert "price" in first


@pytest.mark.asyncio
async def test_get_products_by_category(client: AsyncClient):
    resp = await client.get("/api/products", params={"category": "\u624b\u94fe"})
    assert resp.status_code == 200
    products = resp.json()
    assert all(p["category"] == "\u624b\u94fe" for p in products)


@pytest.mark.asyncio
async def test_get_products_by_price_range(client: AsyncClient):
    resp = await client.get("/api/products",
                            params={"min_price": 500, "max_price": 2000})
    assert resp.status_code == 200
    for p in resp.json():
        assert 500 <= p["price"] <= 2000


@pytest.mark.asyncio
async def test_get_products_search(client: AsyncClient):
    resp = await client.get("/api/products",
                            params={"search": "\u548c\u7530\u7389"})
    assert resp.status_code == 200
    products = resp.json()
    assert len(products) > 0


@pytest.mark.asyncio
async def test_get_product_detail(client: AsyncClient):
    resp = await client.get("/api/products/HYY-HT001")
    assert resp.status_code == 200
    p = resp.json()
    assert p["id"] == "HYY-HT001"
    assert "images" in p


@pytest.mark.asyncio
async def test_get_product_not_found(client: AsyncClient):
    resp = await client.get("/api/products/NONEXISTENT")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_create_product_as_admin(client: AsyncClient, admin_auth: str):
    resp = await client.post("/api/products", json={
        "name": "Test Product",
        "description": "pytest auto test",
        "price": 888.0,
        "category": "\u624b\u94fe",
        "material": "\u548c\u7530\u7389",
        "stock": 100,
    }, params={"authorization": admin_auth})
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Test Product"
    assert data["price"] == 888.0
    # verify retrievable
    resp2 = await client.get(f"/api/products/{data['id']}")
    assert resp2.status_code == 200


@pytest.mark.asyncio
async def test_create_product_forbidden_for_operator(client: AsyncClient,
                                                      operator_auth: str):
    resp = await client.post("/api/products", json={
        "name": "Illegal",
        "description": "should fail",
        "price": 100.0,
        "category": "test",
        "material": "test",
    }, params={"authorization": operator_auth})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_update_product(client: AsyncClient, admin_auth: str):
    resp = await client.put("/api/products/HYY-HT001", json={
        "name": "Updated Name",
        "description": "updated",
        "price": 399.0,
        "category": "\u624b\u94fe",
        "material": "\u548c\u7530\u7389",
        "stock": 200,
    }, params={"authorization": admin_auth})
    assert resp.status_code == 200
    assert resp.json()["name"] == "Updated Name"


@pytest.mark.asyncio
async def test_delete_product(client: AsyncClient, admin_auth: str):
    resp = await client.delete("/api/products/HYY-HT001",
                               params={"authorization": admin_auth})
    assert resp.status_code == 200
    resp2 = await client.get("/api/products/HYY-HT001")
    assert resp2.status_code == 404


@pytest.mark.asyncio
async def test_products_pagination(client: AsyncClient):
    r1 = await client.get("/api/products", params={"page": 1, "page_size": 3})
    r2 = await client.get("/api/products", params={"page": 2, "page_size": 3})
    assert r1.status_code == 200
    assert r2.status_code == 200
    p1, p2 = r1.json(), r2.json()
    assert len(p1) <= 3
    if len(p1) == 3 and len(p2) > 0:
        assert p1[0]["id"] != p2[0]["id"]


@pytest.mark.asyncio
async def test_products_sort_by_price(client: AsyncClient):
    resp = await client.get("/api/products", params={"sort_by": "price_asc"})
    assert resp.status_code == 200
    prices = [p["price"] for p in resp.json()]
    assert prices == sorted(prices)
