"""
Notification router - device registration and notification state.

This endpoint remains DB-first, but it also enriches persisted notifications
with localization keys so the frontend can render stable translations while
keeping raw title/body fallback for older data.
"""

import json
import logging
import re
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.common import NotificationRegister
from security import AuthorizationDep, require_user
from store import DEVICES_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])

_ORDER_SHIPPED_PATTERN = re.compile(
    r"您的订单已发货[，,]\s*(?P<carrier>.+?)\s*运单号\s*(?P<tracking>\S+)"
)


def _derive_notification_localization(
    *,
    ntype: str,
    title: str,
    body: str,
    ref_id: Optional[str],
) -> dict:
    title_key = None
    title_args = None
    body_key = None
    body_args = None

    if ntype == "order_created":
        title_key = "notification_order_created_title"
        body_key = "notification_order_created_body"
        body_args = {"order_id": ref_id} if ref_id else None
    elif ntype == "payment_success":
        title_key = "notification_payment_success_title"
        body_key = "notification_payment_success_body"
        body_args = {"order_id": ref_id} if ref_id else None
    elif ntype == "order_shipped":
        title_key = "notification_order_shipped_title"
        match = _ORDER_SHIPPED_PATTERN.search(body)
        if match:
            body_key = "notification_order_shipped_body_with_tracking"
            body_args = {
                "carrier": match.group("carrier").strip(),
                "tracking": match.group("tracking").strip(),
            }
        else:
            body_key = "notification_order_shipped_body"
    elif ntype == "logistics":
        title_key = "notification_demo_order_shipped_title"
        body_key = "notification_demo_order_shipped_body"
    elif (
        ntype == "promotion"
        and title == "新品上架"
        and "和田玉新品已上架" in body
    ):
        title_key = "notification_demo_new_arrival_title"
        body_key = "notification_demo_new_arrival_body"

    return {
        "title_key": title_key,
        "title_args": title_args,
        "body_key": body_key,
        "body_args": body_args,
    }


def _serialize_notification_item(
    *,
    notification_id,
    title: str,
    body: str,
    ntype: str,
    ref_id,
    is_read,
    created_at,
) -> dict:
    localized = _derive_notification_localization(
        ntype=ntype,
        title=title,
        body=body,
        ref_id=ref_id,
    )
    return {
        "id": notification_id,
        "title": title,
        "title_key": localized["title_key"],
        "title_args": localized["title_args"],
        "body": body,
        "body_key": localized["body_key"],
        "body_args": localized["body_args"],
        "type": ntype,
        "ref_id": ref_id,
        "is_read": is_read,
        "created_at": (
            created_at.isoformat()
            if hasattr(created_at, "isoformat")
            else str(created_at)
        ),
    }


@router.post("/register")
async def register_device(
    data: NotificationRegister,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
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
                    "uid": user_id,
                    "token": data.device_token,
                    "platform": data.platform,
                    "settings": json.dumps(data.settings or {}),
                },
            )
            db.commit()
            return {"success": True, "message": "设备已注册"}
        except Exception as exc:
            handle_database_error(db, "注册设备", exc)

    require_database(db, "注册设备")

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
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
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
            for row in rows:
                mapping = row._mapping
                items.append(
                    _serialize_notification_item(
                        notification_id=mapping["id"],
                        title=mapping["title"],
                        body=mapping["body"],
                        ntype=mapping["type"],
                        ref_id=mapping.get("ref_id"),
                        is_read=mapping["is_read"],
                        created_at=mapping["created_at"],
                    )
                )

            count_row = db.execute(
                text(
                    "SELECT count(*) AS total, "
                    "count(*) FILTER (WHERE is_read = false) AS unread "
                    "FROM notifications WHERE user_id = :uid"
                ),
                {"uid": user_id},
            ).fetchone()
            counts = count_row._mapping if count_row else {"total": 0, "unread": 0}
            return {
                "items": items,
                "total": counts["total"],
                "unread": counts["unread"],
            }
        except Exception as exc:
            handle_database_error(db, "读取通知列表", exc)

    require_database(db, "读取通知列表")

    notifications = [
        _serialize_notification_item(
            notification_id="n001",
            title="订单发货通知",
            body="您的订单已发货，请注意查收。",
            ntype="logistics",
            ref_id=None,
            is_read=False,
            created_at=datetime.now(),
        ),
        _serialize_notification_item(
            notification_id="n002",
            title="新品上架",
            body="和田玉新品已上架，欢迎查看。",
            ntype="promotion",
            ref_id=None,
            is_read=True,
            created_at=datetime.now() - timedelta(hours=2),
        ),
    ]
    return {"items": notifications, "total": len(notifications), "unread": 1}


@router.post("/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            result = db.execute(
                text(
                    "UPDATE notifications SET is_read = true "
                    "WHERE id = :nid AND user_id = :uid"
                ),
                {"nid": notification_id, "uid": user_id},
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="通知不存在")
            db.commit()
            return {"success": True, "message": "已标记为已读"}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "标记通知已读", exc)

    require_database(db, "标记通知已读")
    return {"success": True, "message": "已标记为已读"}


@router.post("/read-all")
async def mark_all_read(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text(
                    "UPDATE notifications SET is_read = true "
                    "WHERE user_id = :uid AND is_read = false"
                ),
                {"uid": user_id},
            )
            db.commit()
            return {"success": True, "message": "全部已读"}
        except Exception as exc:
            handle_database_error(db, "全部通知标记已读", exc)

    require_database(db, "全部通知标记已读")
    return {"success": True, "message": "全部已读"}
