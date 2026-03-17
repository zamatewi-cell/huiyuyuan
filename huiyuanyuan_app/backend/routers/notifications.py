"""
通知路由 — 设备注册 + 通知列表 + 标记已读
DB-first with in-memory fallback
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.common import NotificationRegister
from security import require_user
from database import get_db
from store import DEVICES_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/notifications", tags=["通知"])


@router.post("/register")
async def register_device(data: NotificationRegister, authorization: str = None,
                          db: Optional[Session] = Depends(get_db)):
    """注册设备Token"""
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO devices (user_id, device_token, platform, settings) "
                    "VALUES (:uid, :token, :platform, :settings::jsonb) "
                    "ON CONFLICT (device_token) DO UPDATE SET "
                    "user_id = :uid, platform = :platform, settings = :settings::jsonb, "
                    "is_active = true, updated_at = NOW()"
                ),
                {
                    "uid": user_id, "token": data.device_token,
                    "platform": data.platform,
                    "settings": json.dumps(data.settings or {}),
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB register_device: {e}")

    # memory write-through
    DEVICES_DB[data.device_token] = {
        "user_id": user_id,
        "platform": data.platform,
        "settings": data.settings or {},
        "registered_at": datetime.now().isoformat(),
    }

    return {"success": True, "message": "设备已注册"}


@router.get("")
async def get_notifications(
    page: int = 1,
    page_size: int = 20,
    authorization: str = None,
    db: Optional[Session] = Depends(get_db),
):
    """获取通知列表"""
    user_id = require_user(authorization)

    if db is not None:
        try:
            offset = (page - 1) * page_size
            rows = db.execute(
                text(
                    "SELECT id, title, body, type, ref_id, is_read, created_at "
                    "FROM notifications WHERE user_id = :uid "
                    "ORDER BY created_at DESC LIMIT :lim OFFSET :off"
                ),
                {"uid": user_id, "lim": page_size, "off": offset},
            ).fetchall()

            items = []
            for r in rows:
                m = r._mapping
                items.append({
                    "id": m["id"],
                    "title": m["title"],
                    "body": m["body"],
                    "type": m["type"],
                    "ref_id": m.get("ref_id"),
                    "is_read": m["is_read"],
                    "created_at": m["created_at"].isoformat() if hasattr(m["created_at"], "isoformat") else str(m["created_at"]),
                })

            count_row = db.execute(
                text("SELECT count(*) as total, "
                     "count(*) FILTER (WHERE is_read = false) as unread "
                     "FROM notifications WHERE user_id = :uid"),
                {"uid": user_id},
            ).fetchone()
            cm = count_row._mapping

            return {"items": items, "total": cm["total"], "unread": cm["unread"]}
        except Exception as e:
            logger.error(f"DB get_notifications: {e}")

    # memory fallback — return demo notifications
    notifications = [
        {
            "id": "n001",
            "title": "订单发货通知",
            "body": "您的订单已发货，请注意查收",
            "type": "logistics",
            "created_at": datetime.now().isoformat(),
            "is_read": False,
        },
        {
            "id": "n002",
            "title": "新品上架",
            "body": "和田玉新品已上架，快来看看吧",
            "type": "promotion",
            "created_at": (datetime.now() - timedelta(hours=2)).isoformat(),
            "is_read": True,
        },
    ]
    return {"items": notifications, "total": len(notifications), "unread": 1}


@router.post("/{notification_id}/read")
async def mark_notification_read(notification_id: str, authorization: str = None,
                                 db: Optional[Session] = Depends(get_db)):
    """标记通知为已读"""
    user_id = require_user(authorization)

    if db is not None:
        try:
            result = db.execute(
                text("UPDATE notifications SET is_read = true "
                     "WHERE id = :nid AND user_id = :uid"),
                {"nid": notification_id, "uid": user_id},
            )
            db.commit()
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="通知不存在")
            return {"success": True, "message": "已标记为已读"}
        except HTTPException:
            raise
        except Exception as e:
            db.rollback()
            logger.error(f"DB mark_notification_read: {e}")

    return {"success": True, "message": "已标记为已读"}


@router.post("/read-all")
async def mark_all_read(authorization: str = None, db: Optional[Session] = Depends(get_db)):
    """标记所有通知为已读"""
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("UPDATE notifications SET is_read = true "
                     "WHERE user_id = :uid AND is_read = false"),
                {"uid": user_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB mark_all_read: {e}")

    return {"success": True, "message": "全部已读"}
