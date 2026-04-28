"""Admin router - dashboard / activities / operator management / orders."""

import json
import logging
import random
import re
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.order import Order
from security import (
    AuthorizationDep,
    has_permission,
    hash_password,
    is_admin_user,
    require_user,
    require_admin,
    revoke_all_user_sessions,
)
from store import ORDERS_DB, PRODUCTS_DB, SHOPS_DB, USERS_DB

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/admin", tags=["Admin"])

TAG_ALL = "order_all"
TAG_ORDERS = "admin_tag_orders"
TAG_STOCK = "product_stock"
TAG_SYSTEM = "admin_tag_system"
TAG_AI = "admin_tag_ai"
DEFAULT_OPERATOR_PERMISSIONS = [
    "shop_radar",
    "ai_assistant",
    "orders",
    "inventory_read",
]
ALLOWED_OPERATOR_PERMISSIONS = {
    *DEFAULT_OPERATOR_PERMISSIONS,
    "payment_reconcile",
    "payment_exception_mark",
    "order_manage",
    "inventory_write",
}
PASSWORD_PATTERN = re.compile(r"^(?=.*[A-Za-z])(?=.*\d).{8,}$")


class OperatorUpdateRequest(BaseModel):
    username: str | None = None
    phone: str | None = None
    is_active: bool | None = None
    password: str | None = None
    permissions: list[str] | None = None


def _normalize_operator_permissions(value) -> list[str]:
    if value is None or value == "":
        return list(DEFAULT_OPERATOR_PERMISSIONS)

    raw = value
    if isinstance(value, str):
        try:
            raw = json.loads(value)
        except json.JSONDecodeError:
            raw = [item.strip() for item in value.split(",")]

    if not isinstance(raw, list):
        return list(DEFAULT_OPERATOR_PERMISSIONS)

    normalized: list[str] = []
    for item in raw:
        key = str(item).strip()
        if key in ALLOWED_OPERATOR_PERMISSIONS and key not in normalized:
            normalized.append(key)

    return normalized


def _validate_operator_permissions(value: list[str] | None) -> list[str] | None:
    if value is None:
        return None
    normalized = _normalize_operator_permissions(value)
    unknown = sorted({str(item).strip() for item in value} - ALLOWED_OPERATOR_PERMISSIONS)
    if unknown:
        raise HTTPException(status_code=400, detail=f"未知权限: {', '.join(unknown)}")
    return normalized


def _validate_operator_update(payload: OperatorUpdateRequest) -> None:
    if payload.username is not None and not payload.username.strip():
        raise HTTPException(status_code=400, detail="操作员名称不能为空")
    if payload.phone is not None and payload.phone.strip() == "":
        raise HTTPException(status_code=400, detail="手机号不能为空")
    if payload.password is not None and payload.password:
        if not PASSWORD_PATTERN.match(payload.password):
            raise HTTPException(
                status_code=400,
                detail="密码需至少8位，且同时包含字母和数字",
            )


def _require_order_manage_access(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = None,
) -> str:
    user_id = require_user(authorization)
    if is_admin_user(user_id, db) or has_permission(
        user_id,
        "order_manage",
        db,
        allow_non_operator=False,
    ):
        return user_id
    raise HTTPException(status_code=403, detail="Order management requires permission")


def _require_payment_reconcile_access(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = None,
) -> str:
    user_id = require_user(authorization)
    if is_admin_user(user_id, db) or has_permission(
        user_id,
        "payment_reconcile",
        db,
        allow_non_operator=False,
    ):
        return user_id
    raise HTTPException(
        status_code=403,
        detail="Payment reconciliation requires permission",
    )


def _require_payment_exception_access(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = None,
) -> str:
    user_id = require_user(authorization)
    if is_admin_user(user_id, db) or has_permission(
        user_id,
        "payment_exception_mark",
        db,
        allow_non_operator=False,
    ):
        return user_id
    raise HTTPException(
        status_code=403,
        detail="Payment exception handling requires permission",
    )


def _operator_report_payload(
    *,
    operator_id: str,
    operator_name: str,
    operator_number: int | None,
    contact_shops: int = 0,
    intention_count: int = 0,
    success_count: int = 0,
    ai_usage_count: int = 0,
    order_amount: float = 0.0,
) -> dict:
    return {
        "operator_id": operator_number or 0,
        "operator_user_id": operator_id,
        "operator_name": operator_name,
        "contact_shops": contact_shops,
        "intention_count": intention_count,
        "success_count": success_count,
        "ai_usage_count": ai_usage_count,
        "order_amount": round(float(order_amount), 2),
    }


def _memory_operator_report(user: dict) -> dict:
    operator_id = user["id"]
    shops = [shop for shop in SHOPS_DB.values() if shop.operator_id == operator_id]
    intention_statuses = {"interested", "following", "negotiating"}
    success_statuses = {"cooperated", "contracted"}
    return _operator_report_payload(
        operator_id=operator_id,
        operator_name=user.get("username", ""),
        operator_number=user.get("operator_number") or user.get("operator_num"),
        contact_shops=len(shops),
        intention_count=sum(1 for shop in shops if shop.contact_status in intention_statuses),
        success_count=sum(1 for shop in shops if shop.contact_status in success_statuses),
        ai_usage_count=len(shops),
    )


def _db_operator_report(db: Session, mapping) -> dict:
    operator_id = mapping["id"]
    operator_num = mapping.get("operator_num")
    row = db.execute(
        text(
            "SELECT "
            "count(*) AS contact_shops, "
            "count(*) FILTER (WHERE contact_status IN "
            "('interested', 'following', 'negotiating')) AS intention_count, "
            "count(*) FILTER (WHERE contact_status IN "
            "('cooperated', 'contracted')) AS success_count "
            "FROM shops WHERE operator_id = :operator_id"
        ),
        {"operator_id": operator_id},
    ).fetchone()
    stats = row._mapping if row else {}
    contact_shops = int(stats.get("contact_shops") or 0)
    return _operator_report_payload(
        operator_id=operator_id,
        operator_name=mapping.get("username", ""),
        operator_number=int(operator_num) if operator_num is not None else None,
        contact_shops=contact_shops,
        intention_count=int(stats.get("intention_count") or 0),
        success_count=int(stats.get("success_count") or 0),
        ai_usage_count=contact_shops,
    )


def _operator_account_payload(mapping, report: dict | None = None) -> dict:
    operator_num = mapping.get("operator_num") or mapping.get("operator_number")
    return {
        "id": mapping["id"],
        "username": mapping.get("username", ""),
        "phone": mapping.get("phone"),
        "operator_number": int(operator_num) if operator_num is not None else None,
        "is_active": bool(mapping.get("is_active", True)),
        "permissions": _normalize_operator_permissions(mapping.get("permissions")),
        "report": report,
    }


def _operator_lookup_clause(identifier: str) -> tuple[str, dict[str, object]]:
    if identifier.isdigit():
        return (
            "(id = :id OR operator_num = :operator_num) AND user_type = 'operator'",
            {"id": identifier, "operator_num": int(identifier)},
        )
    return (
        "id = :id AND user_type = 'operator'",
        {"id": identifier},
    )


def _memory_find_operator(identifier: str) -> dict | None:
    user = USERS_DB.get(identifier)
    if user and user.get("user_type") == "operator":
        return user
    if identifier.isdigit():
        number = int(identifier)
        for candidate in USERS_DB.values():
            if (
                candidate.get("user_type") == "operator"
                and (candidate.get("operator_number") or candidate.get("operator_num")) == number
            ):
                return candidate
    return None


def _ts(value):
    if value is None:
        return None
    return value.isoformat() if hasattr(value, "isoformat") else str(value)


def _activity_tag_key(*, status: str | None = None, raw_tag: str | None = None, typ: str | None = None) -> str:
    if typ in {"order_new", "order_paid", "order_shipped", "order_completed", "order_refund"}:
        return TAG_ORDERS
    if typ == "stock_warning":
        return TAG_STOCK
    if typ == "system":
        return TAG_SYSTEM
    if typ in {"ai", "ai_reply", "ai_task"}:
        return TAG_AI
    if raw_tag in {"支付", "物流", "完成", "订单", "退款"}:
        return TAG_ORDERS
    if raw_tag == "库存":
        return TAG_STOCK
    if raw_tag == "系统":
        return TAG_SYSTEM
    if raw_tag == "AI":
        return TAG_AI
    if status in {"pending", "paid", "shipped", "delivered", "completed", "refunding"}:
        return TAG_ORDERS
    return raw_tag or ""


def _activity_item(
    *,
    tag: str,
    title: str,
    subtitle: str,
    time: str | None,
    typ: str,
    status: str | None = None,
    title_key: str | None = None,
    title_args: dict | None = None,
    subtitle_key: str | None = None,
    subtitle_args: dict | None = None,
) -> dict:
    return {
        "tag": tag,
        "tag_key": _activity_tag_key(status=status, raw_tag=tag, typ=typ),
        "title": title,
        "title_key": title_key,
        "title_args": title_args,
        "subtitle": subtitle,
        "subtitle_key": subtitle_key,
        "subtitle_args": subtitle_args,
        "time": time,
        "type": typ,
    }


def _activity_from_db(activities: list, mapping: dict) -> None:
    status = mapping["status"]
    name = mapping.get("item_name", "商品")
    amount = float(mapping["total_amount"])
    qty = mapping.get("total_qty", 1)
    table = {
        "pending": ("订单", f"新订单 {name} x{qty}", f"¥{amount:.0f}", _ts(mapping["created_at"]), "order_new"),
        "paid": ("支付", f"支付完成: {name}", f"¥{amount:.0f}", _ts(mapping.get("paid_at") or mapping["created_at"]), "order_paid"),
        "shipped": ("物流", f"已发货: {mapping.get('tracking_no', '')}", f"{mapping.get('logistics_company', '')} · {name}", _ts(mapping.get("shipped_at") or mapping["created_at"]), "order_shipped"),
        "delivered": ("完成", f"交易完成: {name}", f"¥{amount:.0f}", _ts(mapping.get("completed_at") or mapping["created_at"]), "order_completed"),
        "refunding": ("退款", f"退款申请: {name}", mapping.get("refund_reason", ""), _ts(mapping["created_at"]), "order_refund"),
    }
    if status in table:
        tag, title, subtitle, time, typ = table[status]
        title_key_map = {
            "order_new": "admin_activity_title_order_new",
            "order_paid": "admin_activity_title_order_paid",
            "order_shipped": "admin_activity_title_order_shipped",
            "order_completed": "admin_activity_title_order_completed",
            "order_refund": "admin_activity_title_order_refund",
        }
        title_args = {
            "order_new": {"name": name, "quantity": qty},
            "order_paid": {"name": name},
            "order_shipped": {"tracking": mapping.get("tracking_no", "")},
            "order_completed": {"name": name},
            "order_refund": {"name": name},
        }
        subtitle_key = None
        subtitle_args = None
        if typ in {"order_new", "order_paid", "order_completed"}:
            subtitle_key = "admin_activity_subtitle_amount"
            subtitle_args = {"amount": f"¥{amount:.0f}"}
        elif typ == "order_shipped":
            subtitle_key = "admin_activity_subtitle_shipping"
            subtitle_args = {
                "carrier": mapping.get("logistics_company", ""),
                "name": name,
            }
        activities.append(_activity_item(
            tag=tag,
            title=title,
            subtitle=subtitle,
            time=time,
            typ=typ,
            status=status,
            title_key=title_key_map.get(typ),
            title_args=title_args.get(typ),
            subtitle_key=subtitle_key,
            subtitle_args=subtitle_args,
        ))


def _activity_from_memory(activities: list, order, name: str, qty: int) -> None:
    table = {
        "pending": ("订单", f"新订单 {name} x{qty}", f"¥{order.total_amount:.0f}", order.created_at, "order_new"),
        "paid": ("支付", f"支付完成: {name}", f"¥{order.total_amount:.0f}", order.paid_at or order.created_at, "order_paid"),
        "shipped": ("物流", f"已发货: {order.tracking_number or ''}", f"{order.logistics_company or ''} · {name}", order.shipped_at or order.created_at, "order_shipped"),
        "completed": ("完成", f"交易完成: {name}", f"¥{order.total_amount:.0f}", order.completed_at or order.created_at, "order_completed"),
        "refunding": ("退款", f"退款申请: {name}", order.refund_reason or "", order.created_at, "order_refund"),
    }
    if order.status in table:
        tag, title, subtitle, time, typ = table[order.status]
        title_key_map = {
            "order_new": "admin_activity_title_order_new",
            "order_paid": "admin_activity_title_order_paid",
            "order_shipped": "admin_activity_title_order_shipped",
            "order_completed": "admin_activity_title_order_completed",
            "order_refund": "admin_activity_title_order_refund",
        }
        title_args = {
            "order_new": {"name": name, "quantity": qty},
            "order_paid": {"name": name},
            "order_shipped": {"tracking": order.tracking_number or ""},
            "order_completed": {"name": name},
            "order_refund": {"name": name},
        }
        subtitle_key = None
        subtitle_args = None
        if typ in {"order_new", "order_paid", "order_completed"}:
            subtitle_key = "admin_activity_subtitle_amount"
            subtitle_args = {"amount": f"¥{order.total_amount:.0f}"}
        elif typ == "order_shipped":
            subtitle_key = "admin_activity_subtitle_shipping"
            subtitle_args = {
                "carrier": order.logistics_company or "",
                "name": name,
            }
        activities.append(_activity_item(
            tag=tag,
            title=title,
            subtitle=subtitle,
            time=time,
            typ=typ,
            status=order.status,
            title_key=title_key_map.get(typ),
            title_args=title_args.get(typ),
            subtitle_key=subtitle_key,
            subtitle_args=subtitle_args,
        ))


def _filter_activities(activities: list[dict], tag_filter: str | None) -> list[dict]:
    if not tag_filter or tag_filter == TAG_ALL:
        return activities
    return [item for item in activities if item.get("tag_key") == tag_filter]


@router.get("/dashboard")
async def get_admin_dashboard(authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    require_admin(authorization)
    if db is not None:
        try:
            orders = db.execute(text("SELECT count(*) AS total_orders, count(*) FILTER (WHERE created_at::date = CURRENT_DATE) AS today_orders, coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered')), 0) AS total_rev, coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered') AND created_at::date = CURRENT_DATE), 0) AS today_rev, count(*) FILTER (WHERE status = 'paid') AS pending_ship, count(*) FILTER (WHERE status = 'refunding') AS pending_refund FROM orders")).fetchone()._mapping
            products = db.execute(text("SELECT count(*) AS total, count(*) FILTER (WHERE stock <= 5) AS low_stock FROM products WHERE is_active = true")).fetchone()._mapping
            operators = db.execute(text("SELECT count(*) AS cnt FROM users WHERE user_type = 'operator' AND is_active = true")).fetchone()._mapping
            return {"total_orders": orders["total_orders"], "today_orders": orders["today_orders"], "total_revenue": round(float(orders["total_rev"]), 2), "today_revenue": round(float(orders["today_rev"]), 2), "total_products": products["total"], "pending_ship": orders["pending_ship"], "pending_refund": orders["pending_refund"], "operator_count": operators["cnt"], "low_stock_items": products["low_stock"]}
        except Exception as exc:
            handle_database_error(db, "读取管理看板", exc)
    require_database(db, "读取管理看板")
    all_orders = list(ORDERS_DB.values())
    today = datetime.now().date()
    today_orders = [order for order in all_orders if datetime.fromisoformat(order.created_at).date() == today]
    total_revenue = sum(order.total_amount for order in all_orders if order.status in ("paid", "shipped", "completed"))
    today_revenue = sum(order.total_amount for order in today_orders if order.status in ("paid", "shipped", "completed"))
    return {"total_orders": len(all_orders), "today_orders": len(today_orders), "total_revenue": round(total_revenue, 2), "today_revenue": round(today_revenue, 2), "total_products": len(PRODUCTS_DB), "pending_ship": sum(1 for order in all_orders if order.status == "paid"), "pending_refund": sum(1 for order in all_orders if order.status == "refunding"), "operator_count": len([user for user in USERS_DB.values() if user.get("user_type") == "operator"]), "low_stock_items": sum(1 for product in PRODUCTS_DB.values() if product.stock <= 5)}


@router.get("/activities")
async def get_admin_activities(limit: int = 10, filter: str | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    require_admin(authorization)
    activities: list = []
    if db is not None:
        try:
            rows = db.execute(text("SELECT o.id, o.status, o.total_amount, o.created_at, o.paid_at, o.shipped_at, o.completed_at, o.tracking_no, o.logistics_company, o.refund_reason, COALESCE((SELECT oi.product_snap->>'name' FROM order_items oi WHERE oi.order_id = o.id LIMIT 1), '商品') AS item_name, COALESCE((SELECT sum(oi.quantity) FROM order_items oi WHERE oi.order_id = o.id), 1) AS total_qty FROM orders o ORDER BY o.created_at DESC LIMIT :lim"), {"lim": limit}).fetchall()
            for row in rows:
                _activity_from_db(activities, row._mapping)
            low_stock = db.execute(text("SELECT name, stock FROM products WHERE is_active = true AND stock <= 5")).fetchall()
            for row in low_stock:
                mapping = row._mapping
                activities.append(_activity_item(
                    tag="库存",
                    title=f"库存预警: {mapping['name']}",
                    subtitle=f"当前库存 {mapping['stock']} 件",
                    time=datetime.now().isoformat(),
                    typ="stock_warning",
                    title_key="admin_activity_title_stock_warning",
                    title_args={"name": mapping["name"]},
                    subtitle_key="admin_activity_subtitle_stock_units",
                    subtitle_args={"stock": mapping["stock"]},
                ))
            activities.sort(key=lambda item: item.get("time", ""), reverse=True)
            filtered = _filter_activities(activities, filter)
            return {"items": filtered[:limit], "total": len(filtered)}
        except Exception as exc:
            handle_database_error(db, "读取管理动态", exc)
    require_database(db, "读取管理动态")
    recent = sorted(ORDERS_DB.values(), key=lambda order: order.created_at, reverse=True)[:limit]
    for order in recent:
        name = order.items[0].get("product_name", "商品") if order.items else "商品"
        qty = sum(item.get("quantity", 1) for item in order.items)
        _activity_from_memory(activities, order, name, qty)
    for product in PRODUCTS_DB.values():
        if product.stock <= 5:
            activities.append(_activity_item(
                tag="库存",
                title=f"库存预警: {product.name}",
                subtitle=f"当前库存 {product.stock} 件",
                time=datetime.now().isoformat(),
                typ="stock_warning",
                title_key="admin_activity_title_stock_warning",
                title_args={"name": product.name},
                subtitle_key="admin_activity_subtitle_stock_units",
                subtitle_args={"stock": product.stock},
            ))
    activities.sort(key=lambda item: item.get("time", ""), reverse=True)
    filtered = _filter_activities(activities, filter)
    return {"items": filtered[:limit], "total": len(filtered)}


@router.get("/operators")
async def list_admin_operators(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT id, phone, username, user_type, operator_num, "
                    "is_active, permissions "
                    "FROM users WHERE user_type = 'operator' "
                    "ORDER BY operator_num NULLS LAST, id"
                )
            ).fetchall()
            items = []
            for row in rows:
                mapping = row._mapping
                items.append(
                    _operator_account_payload(
                        mapping,
                        report=_db_operator_report(db, mapping),
                    )
                )
            return {"items": items, "total": len(items)}
        except Exception as exc:
            handle_database_error(db, "读取操作员账号", exc)

    require_database(db, "读取操作员账号")
    operators = [
        user
        for user in USERS_DB.values()
        if user.get("user_type") == "operator"
    ]
    operators.sort(key=lambda user: user.get("operator_number") or user.get("operator_num") or 999)
    items = [
        _operator_account_payload(user, report=_memory_operator_report(user))
        for user in operators
    ]
    return {"items": items, "total": len(items)}


@router.put("/operators/{operator_id}")
async def update_admin_operator(
    operator_id: str,
    payload: OperatorUpdateRequest,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    _validate_operator_update(payload)
    permissions = _validate_operator_permissions(payload.permissions)

    if db is not None:
        try:
            row = db.execute(
                text(
                    "SELECT id, phone, username, user_type, operator_num, "
                    "is_active, permissions "
                    "FROM users WHERE id = :id AND user_type = 'operator'"
                ),
                {"id": operator_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="操作员不存在")

            current_permissions = _normalize_operator_permissions(
                row._mapping.get("permissions")
            )
            set_parts: list[str] = []
            params: dict[str, object] = {"id": operator_id}
            if payload.username is not None:
                set_parts.append("username = :username")
                params["username"] = payload.username.strip()
            if payload.phone is not None:
                set_parts.append("phone = :phone")
                params["phone"] = payload.phone.strip()
            if payload.is_active is not None:
                set_parts.append("is_active = :is_active")
                params["is_active"] = payload.is_active
            if permissions is not None:
                set_parts.append("permissions = CAST(:permissions AS JSONB)")
                params["permissions"] = json.dumps(permissions, ensure_ascii=False)
            if payload.password:
                set_parts.append("password_hash = :password_hash")
                params["password_hash"] = hash_password(payload.password)

            if set_parts:
                set_parts.append("updated_at = NOW()")
                db.execute(
                    text(
                        f"UPDATE users SET {', '.join(set_parts)} "
                        "WHERE id = :id AND user_type = 'operator'"
                    ),
                    params,
                )
                db.commit()

            permissions_changed = (
                permissions is not None and permissions != current_permissions
            )
            if payload.password or payload.is_active is False or permissions_changed:
                revoke_all_user_sessions(operator_id)

            updated = db.execute(
                text(
                    "SELECT id, phone, username, user_type, operator_num, "
                    "is_active, permissions "
                    "FROM users WHERE id = :id AND user_type = 'operator'"
                ),
                {"id": operator_id},
            ).fetchone()
            mapping = updated._mapping
            return {
                "success": True,
                "operator": _operator_account_payload(
                    mapping,
                    report=_db_operator_report(db, mapping),
                ),
            }
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "更新操作员账号", exc)

    require_database(db, "更新操作员账号")
    user = USERS_DB.get(operator_id)
    if not user or user.get("user_type") != "operator":
        raise HTTPException(status_code=404, detail="操作员不存在")

    current_permissions = _normalize_operator_permissions(user.get("permissions"))
    if payload.username is not None:
        user["username"] = payload.username.strip()
    if payload.phone is not None:
        user["phone"] = payload.phone.strip()
    if payload.is_active is not None:
        user["is_active"] = payload.is_active
    if permissions is not None:
        user["permissions"] = permissions
    if payload.password:
        user["password_hash"] = hash_password(payload.password)
    permissions_changed = (
        permissions is not None and permissions != current_permissions
    )
    if payload.password or payload.is_active is False or permissions_changed:
        revoke_all_user_sessions(operator_id)

    return {
        "success": True,
        "operator": _operator_account_payload(
            user,
            report=_memory_operator_report(user),
        ),
    }


@router.get("/operators/reports")
async def get_operator_reports(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    operators = await list_admin_operators(authorization=authorization, db=db)
    return {
        "items": [
            item["report"]
            for item in operators["items"]
            if item.get("report") is not None
        ],
        "total": operators["total"],
    }


@router.get("/operators/{operator_id}/report")
async def get_operator_report(
    operator_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    if db is not None:
        try:
            where_clause, params = _operator_lookup_clause(operator_id)
            row = db.execute(
                text(
                    "SELECT id, phone, username, user_type, operator_num, "
                    "is_active, permissions "
                    f"FROM users WHERE {where_clause}"
                ),
                params,
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="操作员不存在")
            return _db_operator_report(db, row._mapping)
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取操作员报表", exc)

    require_database(db, "读取操作员报表")
    user = _memory_find_operator(operator_id)
    if not user:
        raise HTTPException(status_code=404, detail="操作员不存在")
    return _memory_operator_report(user)


@router.post("/orders/{order_id}/ship")
async def ship_order(order_id: str, data: dict, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    _require_order_manage_access(authorization, db)
    carrier = data.get("carrier", "顺丰速运")
    tracking = data.get("tracking_number", f"SF{random.randint(10**11, 10**12 - 1)}")
    now = datetime.now().isoformat()
    if db is not None:
        try:
            from routers.orders import _fetch_order, _ws_notify

            order = _fetch_order(db, order_id)
            if not order:
                raise HTTPException(status_code=404, detail="订单不存在")
            if order.status != "paid":
                raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法发货")
            entries = [{"time": now, "status": "已发货", "description": f"商家已发货，{carrier} 运单号 {tracking}"}, {"time": now, "status": "揽收", "description": f"快件已被 {carrier} 揽收"}] + order.logistics_entries
            db.execute(text("UPDATE orders SET status = 'shipped', shipped_at = NOW(), logistics_company = :carrier, tracking_no = :tracking, logistics_entries = CAST(:entries AS JSONB) WHERE id = :oid"), {"carrier": carrier, "tracking": tracking, "entries": json.dumps(entries), "oid": order_id})
            db.commit()
            _ws_notify(order.user_id, {"type": "order_shipped", "order_id": order_id, "tracking_number": tracking, "carrier": carrier, "message": f"您的订单已发货，{carrier} 运单号 {tracking}"})
            return {"success": True, "message": "发货成功", "tracking_number": tracking}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "订单发货", exc)
    require_database(db, "订单发货")
    order = ORDERS_DB.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.status != "paid":
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法发货")
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "shipped", "shipped_at": now, "logistics_company": carrier, "tracking_number": tracking, "logistics_entries": [{"time": now, "status": "已发货", "description": f"商家已发货，{carrier} 运单号 {tracking}"}, {"time": now, "status": "揽收", "description": f"快件已被 {carrier} 揽收"}] + order.logistics_entries})
    return {"success": True, "message": "发货成功", "tracking_number": tracking}


@router.post("/orders/{order_id}/confirm-payment")
async def confirm_order_payment(order_id: str, data: dict | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    admin_user_id = _require_payment_reconcile_access(authorization, db)
    note = (data or {}).get("note", "管理员已确认到账")
    now = datetime.now().isoformat()
    if db is not None:
        try:
            from routers.orders import _fetch_order, _payment, _ws_notify
            from services.payment_service import (
                get_payment_record,
                update_payment_status,
                PAYMENT_STATUS_PENDING,
                PAYMENT_STATUS_AWAITING_CONFIRMATION,
                PAYMENT_STATUS_CONFIRMED,
                PAYMENT_STATUS_DISPUTED,
            )

            order = _fetch_order(db, order_id)
            if not order:
                raise HTTPException(status_code=404, detail="订单不存在")
            if order.status not in ("pending",):
                raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无需确认到账")
            pay = _payment(db, order_id)
            if not pay or not order.payment_id:
                raise HTTPException(status_code=400, detail="订单尚未创建支付单")

            # 同步更新新支付记录状态
            payment_record = get_payment_record(order.payment_id, db=db)
            if not payment_record:
                raise HTTPException(status_code=400, detail="payment record missing")
            if payment_record["status"] not in (
                PAYMENT_STATUS_PENDING,
                PAYMENT_STATUS_AWAITING_CONFIRMATION,
                PAYMENT_STATUS_DISPUTED,
            ):
                raise HTTPException(
                    status_code=400,
                    detail=f"payment status {payment_record['status']} cannot be confirmed",
                )
            updated_payment = update_payment_status(
                order.payment_id,
                PAYMENT_STATUS_CONFIRMED,
                admin_id=admin_user_id,
                admin_note=note,
                db=db,
            )
            if updated_payment is None:
                raise HTTPException(status_code=409, detail="payment status changed")

            entries = [{
                "time": now,
                "status": "支付成功",
                "description": f"{note}，订单已支付 ¥{order.total_amount:.2f} ({pay['method']})",
            }] + order.logistics_entries
            db.execute(
                text(
                    "UPDATE orders SET status = 'paid', paid_at = NOW(), "
                    "logistics_entries = :entries::jsonb WHERE id = :oid"
                ),
                {"entries": json.dumps(entries), "oid": order_id},
            )
            db.commit()
            _ws_notify(order.user_id, {"type": "payment_success", "order_id": order_id, "message": f"订单 {order_id} 已确认到账"})
            return {"success": True, "message": "已确认到账", "confirmed_by": admin_user_id, "payment_id": order.payment_id}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "确认订单到账", exc)

    require_database(db, "确认订单到账")
    from store import PAYMENTS_DB
    from services.payment_service import (
        get_payment_record,
        update_payment_status,
        PAYMENT_STATUS_PENDING,
        PAYMENT_STATUS_AWAITING_CONFIRMATION,
        PAYMENT_STATUS_CONFIRMED,
        PAYMENT_STATUS_DISPUTED,
    )

    order = ORDERS_DB.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无需确认到账")
    if not order.payment_id or order.payment_id not in PAYMENTS_DB:
        raise HTTPException(status_code=400, detail="订单尚未创建支付单")

    pay = PAYMENTS_DB[order.payment_id]
    pay["status"] = "confirmed"
    pay["paid_at"] = now
    PAYMENTS_DB[order.payment_id] = pay

    # 同步更新新支付记录状态
    payment_record = get_payment_record(order.payment_id)
    if not payment_record:
        raise HTTPException(status_code=400, detail="payment record missing")
    if payment_record["status"] not in (
        PAYMENT_STATUS_PENDING,
        PAYMENT_STATUS_AWAITING_CONFIRMATION,
        PAYMENT_STATUS_DISPUTED,
    ):
        raise HTTPException(
            status_code=400,
            detail=f"payment status {payment_record['status']} cannot be confirmed",
        )
    updated_payment = update_payment_status(
        order.payment_id,
        PAYMENT_STATUS_CONFIRMED,
        admin_id=admin_user_id,
        admin_note=note,
    )
    if updated_payment is None:
        raise HTTPException(status_code=409, detail="payment status changed")
    ORDERS_DB[order_id] = Order(**{
        **order.model_dump(),
        "status": "paid",
        "paid_at": now,
        "logistics_entries": [{
            "time": now,
            "status": "支付成功",
            "description": f"{note}，订单已支付 ¥{order.total_amount:.2f} ({pay['method']})",
        }] + order.logistics_entries,
    })
    return {"success": True, "message": "已确认到账", "confirmed_by": admin_user_id, "payment_id": order.payment_id}
