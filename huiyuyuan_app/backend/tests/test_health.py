# -*- coding: utf-8 -*-
"""Health check endpoint tests (2 cases)"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_root_endpoint(client: AsyncClient):
    resp = await client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert "version" in data


@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data


@pytest.mark.asyncio
async def test_app_version_endpoint(client: AsyncClient):
    resp = await client.get("/api/app/version", params={"platform": "android"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["platform"] == "android"
    assert "latest_version" in data
    assert "latest_build_number" in data
    assert "download_url" in data
    assert "download_urls" in data
    assert isinstance(data["download_urls"], list)
    assert "download_content_type" in data
    assert "download_sha256" in data
    assert "download_size_bytes" in data
