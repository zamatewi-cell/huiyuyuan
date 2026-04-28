# -*- coding: utf-8 -*-
"""AI route tests."""

import io

import httpx
import pytest
from httpx import AsyncClient

from services import ai_service as ai_service_module


def _make_image(name: str = "test.jpg", content_type: str = "image/jpeg") -> dict:
    return {
        "file": (name, io.BytesIO(b"\xff\xd8\xff\xe0" + b"\x00" * 100), content_type),
    }


@pytest.mark.asyncio
async def test_ai_image_analysis_rejects_openrouter_style_key(
    client: AsyncClient,
    operator_auth: str,
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(ai_service_module, "DASHSCOPE_API_KEY", "")
    monkeypatch.setattr(
        ai_service_module,
        "DASHSCOPE_API_KEY_ISSUE",
        "DASHSCOPE_API_KEY appears to be an OpenRouter key. Provide a DashScope key that starts with sk-.",
    )

    resp = await client.post(
        "/api/ai/analyze-image",
        files=_make_image(),
        params={"authorization": operator_auth},
    )

    assert resp.status_code == 503
    assert "OpenRouter key" in resp.json()["detail"]


class _FakeResponse:
    def __init__(self, status_code: int, payload: dict, text: str = ""):
        self.status_code = status_code
        self._payload = payload
        self.text = text

    def json(self) -> dict:
        return self._payload


class _FakeAsyncClient:
    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return False

    async def post(self, url: str, headers: dict, json: dict):
        assert url.endswith("/chat/completions")
        assert headers["Authorization"] == "Bearer sk-valid-dashscope-key"
        assert json["model"] == "qwen-vl-plus-latest"
        return _FakeResponse(
            200,
            {
                "choices": [
                    {
                        "message": {
                            "content": '{"description":"jade bracelet","material":"jade","category":"手链","tags":["green"],"quality_score":0.9,"suggestion":"keep"}'
                        }
                    }
                ]
            },
        )


@pytest.mark.asyncio
async def test_ai_image_analysis_returns_parsed_json(
    client: AsyncClient,
    operator_auth: str,
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setattr(ai_service_module, "DASHSCOPE_API_KEY", "sk-valid-dashscope-key")
    monkeypatch.setattr(ai_service_module, "DASHSCOPE_API_KEY_ISSUE", None)
    monkeypatch.setattr(httpx, "AsyncClient", _FakeAsyncClient)

    resp = await client.post(
        "/api/ai/analyze-image",
        files=_make_image(),
        params={"authorization": operator_auth},
    )

    assert resp.status_code == 200
    payload = resp.json()
    assert payload["success"] is True
    assert payload["analysis"]["material"] == "jade"
    assert payload["analysis"]["quality_score"] == 0.9


@pytest.mark.asyncio
async def test_ai_chat_forbidden_without_operator_permission(
    client: AsyncClient,
    admin_auth: str,
):
    await client.put(
        "/api/admin/operators/operator_1",
        json={"permissions": ["shop_radar"]},
        params={"authorization": admin_auth},
    )
    login = await client.post(
        "/api/auth/login",
        json={
            "username": "1",
            "password": "op123456",
            "type": "operator",
        },
    )
    assert login.status_code == 200
    operator_auth = f"Bearer {login.json()['token']}"

    resp = await client.post(
        "/api/ai/chat",
        json={
            "messages": [
                {"role": "user", "content": "你好"},
            ],
        },
        params={"authorization": operator_auth},
    )

    assert resp.status_code == 403
