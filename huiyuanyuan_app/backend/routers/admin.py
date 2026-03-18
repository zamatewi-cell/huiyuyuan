"""Admin router - dashboard / activities / ship order."""

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


def _ts(value):
    if value is None:
        return None
    return value.isoformat() if hasattr(value, "isoformat") else str(value)


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
        activities.append({"tag": tag, "title": title, "subtitle": subtitle, "time": time, "type": typ})


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
        activities.append({"tag": tag, "title": title, "subtitle": subtitle, "time": time, "type": typ})


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
async def get_admin_activities(limit: int = 10, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
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
                activities.append({"tag": "库存", "title": f"库存预警: {mapping['name']}", "subtitle": f"当前库存 {mapping['stock']} 件", "time": datetime.now().isoformat(), "type": "stock_warning"})
            activities.sort(key=lambda item: item.get("time", ""), reverse=True)
            return {"items": activities[:limit], "total": len(activities)}
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
            activities.append({"tag": "库存", "title": f"库存预警: {product.name}", "subtitle": f"当前库存 {product.stock} 件", "time": datetime.now().isoformat(), "type": "stock_warning"})
    activities.sort(key=lambda item: item.get("time", ""), reverse=True)
    return {"items": activities[:limit], "total": len(activities)}


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
