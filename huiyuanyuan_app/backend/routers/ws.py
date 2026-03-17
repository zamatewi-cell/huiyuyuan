"""
WebSocket 通知路由 — 实时推送订单状态变更等事件
连接方式: ws://host/ws/notifications?token=<jwt_token>
"""

import json
import logging
from typing import Dict, List

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import text

from security import get_user_id_from_token

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSocket"])


def persist_notification(user_id: str, title: str, body: str,
                         ntype: str = "system", ref_id: str = None):
    """将通知持久化到 DB（best-effort, 不阻塞 WS 推送）"""
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
                {"uid": user_id, "title": title, "body": body,
                 "ntype": ntype, "ref": ref_id},
            )
            db.commit()
        finally:
            db.close()
    except Exception as e:
        logger.debug(f"persist_notification failed (non-critical): {e}")


class ConnectionManager:
    """WebSocket 连接管理器 — 按 user_id 维护多连接"""

    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info(f"WS connected: user={user_id}, total={self.count}")

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            try:
                self.active_connections[user_id].remove(websocket)
            except ValueError:
                pass
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"WS disconnected: user={user_id}, total={self.count}")

    async def send_to_user(self, user_id: str, message: dict):
        """向指定用户的所有连接发送消息"""
        if user_id not in self.active_connections:
            return
        dead = []
        for ws in self.active_connections[user_id]:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            try:
                self.active_connections[user_id].remove(ws)
            except ValueError:
                pass

    async def broadcast(self, message: dict):
        """向所有连接广播"""
        for user_id in list(self.active_connections.keys()):
            await self.send_to_user(user_id, message)

    @property
    def count(self) -> int:
        return sum(len(v) for v in self.active_connections.values())


# 全局实例，其他 router 可 import 使用
manager = ConnectionManager()


@router.websocket("/ws/notifications")
async def notification_ws(websocket: WebSocket, token: str = None):
    """
    WebSocket 通知端点
    - 客户端连接: ws://host/ws/notifications?token=<jwt>
    - 服务端推送: {"type": "order_shipped", "order_id": "...", "message": "..."}
    - 客户端可发送 "ping"，服务端回复 "pong"
    """
    user_id = get_user_id_from_token(token or "")
    if not user_id:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    await manager.connect(user_id, websocket)
    try:
        # 发送欢迎消息
        await websocket.send_json({
            "type": "connected",
            "message": "通知服务已连接",
            "user_id": user_id,
        })

        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
            else:
                # 可扩展: 客户端订阅特定事件类型
                try:
                    payload = json.loads(data)
                    if payload.get("type") == "subscribe":
                        await websocket.send_json({
                            "type": "subscribed",
                            "topics": payload.get("topics", []),
                        })
                except (json.JSONDecodeError, KeyError):
                    pass
    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
    except Exception as e:
        logger.warning(f"WS error for user {user_id}: {e}")
        manager.disconnect(user_id, websocket)
