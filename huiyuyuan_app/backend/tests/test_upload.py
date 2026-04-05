# -*- coding: utf-8 -*-
"""Upload endpoint tests (4 cases)"""
import io
import pytest
from httpx import AsyncClient


def _make_image(name: str = "test.jpg", content_type: str = "image/jpeg") -> dict:
    """Create a fake image file for upload."""
    return {
        "file": (name, io.BytesIO(b"\xff\xd8\xff\xe0" + b"\x00" * 100), content_type),
    }


@pytest.mark.asyncio
async def test_upload_image_success(client: AsyncClient):
    resp = await client.post("/api/upload/image",
                             files=_make_image(),
                             data={"folder": "test_uploads"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["url"].startswith("/uploads/test_uploads/")
    assert data["url"].endswith(".jpg")
    assert "filename" in data


@pytest.mark.asyncio
async def test_upload_image_png(client: AsyncClient):
    resp = await client.post("/api/upload/image",
                             files=_make_image("logo.png", "image/png"))
    assert resp.status_code == 200
    assert resp.json()["url"].endswith(".png")


@pytest.mark.asyncio
async def test_upload_image_invalid_type(client: AsyncClient):
    files = {"file": ("doc.pdf", io.BytesIO(b"%PDF-1.4"), "application/pdf")}
    resp = await client.post("/api/upload/image", files=files)
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_oss_sts_token_not_implemented(client: AsyncClient, customer_auth: str):
    """OSS STS should return 501 when not configured."""
    resp = await client.get("/api/oss/sts-token",
                            params={"authorization": customer_auth})
    assert resp.status_code == 501
