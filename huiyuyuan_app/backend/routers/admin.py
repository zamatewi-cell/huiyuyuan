"""Admin router - dashboard / activities / confirm payment / ship order."""

import json
import logging
import random
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.order import Order
from security import AuthorizationDep, require_admin
from store import ORDERS_DB, PRODUCTS_DB, USERS_DB

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/admin", tags=["Admin"])

TAG_ALL = "order_all"
TAG_ORDERS = "admin_tag_orders"
TAG_STOCK = "product_stock"
TAG_SYSTEM = "admin_tag_system"
TAG_AI = "admin_tag_ai"


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


@router.post("/orders/{order_id}/ship")
async def ship_order(order_id: str, data: dict, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    require_admin(authorization)
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
            db.execute(text("UPDATE orders SET status = 'shipped', shipped_at = NOW(), logistics_company = :carrier, tracking_no = :tracking, logistics_entries = :entries::jsonb WHERE id = :oid"), {"carrier": carrier, "tracking": tracking, "entries": json.dumps(entries), "oid": order_id})
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
    admin_user_id = require_admin(authorization)
    note = (data or {}).get("note", "管理员已确认到账")
    now = datetime.now().isoformat()
    if db is not None:
        try:
            from routers.orders import _fetch_order, _payment, _ws_notify
            from services.payment_service import (
                get_payment_record,
                update_payment_status,
                PAYMENT_STATUS_AWAITING_CONFIRMATION,
                PAYMENT_STATUS_CONFIRMED,
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
            if payment_record and payment_record["status"] == PAYMENT_STATUS_AWAITING_CONFIRMATION:
                update_payment_status(
                    order.payment_id,
                    PAYMENT_STATUS_CONFIRMED,
                    admin_id=admin_user_id,
                    admin_note=note,
                    db=db,
                )

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
            db.execute(
                text(
                    "UPDATE payments SET status = 'success', paid_at = NOW() "
                    "WHERE order_id = :oid AND status = 'pending'"
                ),
                {"oid": order_id},
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
        PAYMENT_STATUS_AWAITING_CONFIRMATION,
        PAYMENT_STATUS_CONFIRMED,
    )

    order = ORDERS_DB.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无需确认到账")
    if not order.payment_id or order.payment_id not in PAYMENTS_DB:
        raise HTTPException(status_code=400, detail="订单尚未创建支付单")

    pay = PAYMENTS_DB[order.payment_id]
    pay["status"] = "success"
    pay["paid_at"] = now
    PAYMENTS_DB[order.payment_id] = pay

    # 同步更新新支付记录状态
    payment_record = get_payment_record(order.payment_id)
    if payment_record and payment_record["status"] == PAYMENT_STATUS_AWAITING_CONFIRMATION:
        update_payment_status(
            order.payment_id,
            PAYMENT_STATUS_CONFIRMED,
            admin_id=admin_user_id,
            admin_note=note,
        )
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
