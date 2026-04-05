"""
WebSocket router for real-time notification delivery.

Connection URL:
    ws://host/ws/notifications?token=<jwt_or_bearer_token>
"""

import json
import logging
from typing import Dict, List, Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import text

from security import get_user_id_from_token

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSocket"])


def _ws_message(
    event_type: str,
    message: str,
    *,
    message_key: Optional[str] = None,
    message_args: Optional[dict] = None,
    **extra,
) -> dict:
    payload = {
        "type": event_type,
        "message": message,
    }
    if message_key:
        payload["message_key"] = message_key
    if message_args is not None:
        payload["message_args"] = message_args
    payload.update(extra)
    return payload


def _normalize_topics(value) -> List[str]:
    if not isinstance(value, list):
        return []
    topics = []
    for item in value:
        if item is None:
            continue
        topic = str(item).strip()
        if topic:
            topics.append(topic)
    return topics


def persist_notification(
    user_id: str,
    title: str,
    body: str,
    ntype: str = "system",
    ref_id: str = None,
):
    """Persist a notification record as a best-effort side effect."""
    try:
        from database import DB_AVAILABLE, SessionLocal

        if not DB_AVAILABLE or not SessionLocal:
            return

        db = SessionLocal()
        try:
            db.execute(
                text(
                    "INSERT INTO notifications (user_id, title, body, type, ref_id) "
                    "VALUES (:uid, :title, :body, :ntype, :ref)"
                ),
                {
                    "uid": user_id,
                    "title": title,
                    "body": body,
                    "ntype": ntype,
                    "ref": ref_id,
                },
            )
            db.commit()
        finally:
            db.close()
    except Exception as error:
        logger.debug("persist_notification failed (non-critical): %s", error)


class ConnectionManager:
    """Tracks websocket connections by user id."""

    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info("WS connected: user=%s, total=%s", user_id, self.count)

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            try:
                self.active_connections[user_id].remove(websocket)
            except ValueError:
                pass
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info("WS disconnected: user=%s, total=%s", user_id, self.count)

    async def send_to_user(self, user_id: str, message: dict):
        """Send a JSON payload to all active connections for one user."""
        if user_id not in self.active_connections:
            return
        dead: List[WebSocket] = []
        for websocket in self.active_connections[user_id]:
            try:
                await websocket.send_json(message)
            except Exception:
                dead.append(websocket)
        for websocket in dead:
            try:
                self.active_connections[user_id].remove(websocket)
            except ValueError:
                pass

    async def broadcast(self, message: dict):
        """Broadcast a JSON payload to every active websocket user."""
        for user_id in list(self.active_connections.keys()):
            await self.send_to_user(user_id, message)

    @property
    def count(self) -> int:
        return sum(len(connections) for connections in self.active_connections.values())


manager = ConnectionManager()


@router.websocket("/ws/notifications")
async def notification_ws(websocket: WebSocket, token: str = None):
    """
    Real-time notification endpoint.

    Supported client messages:
    - "ping" -> "pong"
    - {"type": "subscribe", "topics": [...]} -> subscribed acknowledgement
    """
    user_id = get_user_id_from_token(token or "")
    if not user_id:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    await manager.connect(user_id, websocket)
    try:
        await websocket.send_json(
            _ws_message(
                "connected",
                "通知服务已连接",
                message_key="ws_connected_message",
                user_id=user_id,
            )
        )

        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
                continue

            try:
                payload = json.loads(data)
            except json.JSONDecodeError:
                continue

            if payload.get("type") == "subscribe":
                topics = _normalize_topics(payload.get("topics"))
                await websocket.send_json(
                    _ws_message(
                        "subscribed",
                        "订阅已更新",
                        message_key="ws_subscribed_message",
                        message_args={"count": len(topics)},
                        topics=topics,
                    )
                )
    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
    except Exception as error:
        logger.warning("WS error for user %s: %s", user_id, error)
        manager.disconnect(user_id, websocket)
