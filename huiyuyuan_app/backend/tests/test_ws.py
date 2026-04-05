# -*- coding: utf-8 -*-
"""WebSocket notification protocol tests."""

from fastapi.testclient import TestClient

from main import app
from routers.ws import _normalize_topics, _ws_message


def _login_admin_token(client: TestClient) -> str:
    response = client.post(
        "/api/auth/login",
        json={
            "username": "18937766669",
            "password": "admin123",
            "type": "admin",
            "captcha": "8888",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["token"]


def test_ws_message_helper_keeps_structured_fields():
    payload = _ws_message(
        "subscribed",
        "订阅已更新",
        message_key="ws_subscribed_message",
        message_args={"count": 2},
        topics=["orders", "system"],
    )

    assert payload["type"] == "subscribed"
    assert payload["message"] == "订阅已更新"
    assert payload["message_key"] == "ws_subscribed_message"
    assert payload["message_args"] == {"count": 2}
    assert payload["topics"] == ["orders", "system"]


def test_normalize_topics_filters_empty_values():
    assert _normalize_topics(["orders", "", "  ", 42, None]) == [
        "orders",
        "42",
    ]


def test_notification_ws_connected_and_subscribed():
    with TestClient(app) as client:
        token = _login_admin_token(client)

        with client.websocket_connect(f"/ws/notifications?token={token}") as websocket:
            connected = websocket.receive_json()
            assert connected["type"] == "connected"
            assert connected["message_key"] == "ws_connected_message"
            assert connected["user_id"]

            websocket.send_json(
                {
                    "type": "subscribe",
                    "topics": ["orders", "", "system"],
                }
            )
            subscribed = websocket.receive_json()
            assert subscribed["type"] == "subscribed"
            assert subscribed["message_key"] == "ws_subscribed_message"
            assert subscribed["message_args"] == {"count": 2}
            assert subscribed["topics"] == ["orders", "system"]


def test_notification_ws_ping_pong():
    with TestClient(app) as client:
        token = _login_admin_token(client)

        with client.websocket_connect(f"/ws/notifications?token={token}") as websocket:
            websocket.receive_json()
            websocket.send_text("ping")
            assert websocket.receive_text() == "pong"
