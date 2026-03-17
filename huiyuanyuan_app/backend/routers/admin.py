"""
Admin router - dashboard / activities / ship order
DB-first with in-memory fallback
"""

import json
import random
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.order import Order
from security import require_user
from database import get_db
from store import ORDERS_DB, PRODUCTS_DB, USERS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/admin", tags=["Admin"])


def _require_admin(authorization: str = None) -> str:
    user_id = require_user(authorization)
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="需要管理员权限")
    return user_id


# ====== DASHBOARD ======

@router.get("/dashboard")
async def get_admin_dashboard(authorization: str = None, db: Optional[Session] = Depends(get_db)):
    _require_admin(authorization)

    if db is not None:
        try:
            row = db.execute(text(
                "SELECT "
                "  count(*) as total_orders, "
                "  count(*) FILTER (WHERE created_at::date = CURRENT_DATE) as today_orders, "
                "  coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered')), 0) as total_rev, "
                "  coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered') AND created_at::date = CURRENT_DATE), 0) as today_rev, "
                "  count(*) FILTER (WHERE status = 'paid') as pending_ship, "
                "  count(*) FILTER (WHERE status = 'refunding') as pending_refund "
                "FROM orders"
            )).fetchone()
            m = row._mapping

            prod_row = db.execute(text(
                "SELECT count(*) as total, "
                "count(*) FILTER (WHERE stock <= 5) as low_stock "
                "FROM products WHERE is_active = true"
            )).fetchone()
            pm = prod_row._mapping

            op_row = db.execute(text(
                "SELECT count(*) as cnt FROM users WHERE user_type = 'operator' AND is_active = true"
            )).fetchone()

            return {
                "total_orders": m["total_orders"],
                "today_orders": m["today_orders"],
                "total_revenue": round(float(m["total_rev"]), 2),
                "today_revenue": round(float(m["today_rev"]), 2),
                "total_products": pm["total"],
                "pending_ship": m["pending_ship"],
                "pending_refund": m["pending_refund"],
                "operator_count": op_row._mapping["cnt"],
                "low_stock_items": pm["low_stock"],
            }
        except Exception as e:
            logger.error(f"DB get_admin_dashboard: {e}")

    # memory
    all_orders = list(ORDERS_DB.values())
    today = datetime.now().date()
    today_orders = [o for o in all_orders if datetime.fromisoformat(o.created_at).date() == today]
    total_rev = sum(o.total_amount for o in all_orders if o.status in ("paid", "shipped", "completed"))
    today_rev = sum(o.total_amount for o in today_orders if o.status in ("paid", "shipped", "completed"))

    return {
        "total_orders": len(all_orders),
        "today_orders": len(today_orders),
        "total_revenue": round(total_rev, 2),
        "today_revenue": round(today_rev, 2),
        "total_products": len(PRODUCTS_DB),
        "pending_ship": sum(1 for o in all_orders if o.status == "paid"),
        "pending_refund": sum(1 for o in all_orders if o.status == "refunding"),
        "operator_count": len([u for u in USERS_DB.values() if u.get("user_type") == "operator"]),
        "low_stock_items": sum(1 for p in PRODUCTS_DB.values() if p.stock <= 5),
    }


# ====== ACTIVITIES ======

@router.get("/activities")
async def get_admin_activities(limit: int = 10, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    _require_admin(authorization)

    activities: list = []

    if db is not None:
        try:
            rows = db.execute(text(
                "SELECT o.id, o.status, o.total_amount, o.created_at, "
                "o.paid_at, o.shipped_at, o.completed_at, o.tracking_no, "
                "o.logistics_company, o.refund_reason, "
                "COALESCE((SELECT oi.product_snap->>'name' FROM order_items oi "
                "  WHERE oi.order_id = o.id LIMIT 1), '商品') as item_name, "
                "COALESCE((SELECT sum(oi.quantity) FROM order_items oi "
                "  WHERE oi.order_id = o.id), 1) as total_qty "
                "FROM orders o ORDER BY o.created_at DESC LIMIT :lim"
            ), {"lim": limit}).fetchall()

            for r in rows:
                m = r._mapping
                _add_activity(activities, m)

            # low-stock warnings
            low = db.execute(text(
                "SELECT name, stock FROM products WHERE is_active = true AND stock <= 5"
            )).fetchall()
            for r in low:
                lm = r._mapping
                activities.append({
                    "tag": "库存", "title": f"库存预警: {lm['name']}",
                    "subtitle": f"当前库存 {lm['stock']} 件",
                    "time": datetime.now().isoformat(), "type": "stock_warning",
                })

            activities.sort(key=lambda a: a.get("time", ""), reverse=True)
            return {"items": activities[:limit], "total": len(activities)}
        except Exception as e:
            logger.error(f"DB get_admin_activities: {e}")

    # memory
    recent = sorted(ORDERS_DB.values(), key=lambda o: o.created_at, reverse=True)[:limit]
    for o in recent:
        name = o.items[0].get("product_name", "商品") if o.items else "商品"
        qty = sum(i.get("quantity", 1) for i in o.items)
        _add_activity_mem(activities, o, name, qty)

    for p in PRODUCTS_DB.values():
        if p.stock <= 5:
            activities.append({
                "tag": "库存", "title": f"库存预警: {p.name}",
                "subtitle": f"当前库存 {p.stock} 件",
                "time": datetime.now().isoformat(), "type": "stock_warning",
            })

    activities.sort(key=lambda a: a.get("time", ""), reverse=True)
    return {"items": activities[:limit], "total": len(activities)}


def _ts(val):
    if val is None:
        return None
    return val.isoformat() if hasattr(val, "isoformat") else str(val)


def _add_activity(acts: list, m):
    status = m["status"]
    name = m.get("item_name", "商品")
    amt = float(m["total_amount"])
    qty = m.get("total_qty", 1)

    mapping = {
        "pending":    ("订单", f"新订单: {name} x{qty}", f"?{amt:.0f}", _ts(m["created_at"]), "order_new"),
        "paid":       ("支付", f"支付完成: {name}", f"?{amt:.0f}", _ts(m.get("paid_at") or m["created_at"]), "order_paid"),
        "shipped":    ("物流", f"已发货: {m.get('tracking_no','')}", f"{m.get('logistics_company','')} · {name}", _ts(m.get("shipped_at") or m["created_at"]), "order_shipped"),
        "delivered":  ("完成", f"交易完成: {name}", f"?{amt:.0f}", _ts(m.get("completed_at") or m["created_at"]), "order_completed"),
        "refunding":  ("退款", f"退款申请: {name}", m.get("refund_reason", ""), _ts(m["created_at"]), "order_refund"),
    }
    if status in mapping:
        tag, title, sub, time, typ = mapping[status]
        acts.append({"tag": tag, "title": title, "subtitle": sub, "time": time, "type": typ})


def _add_activity_mem(acts: list, o, name: str, qty: int):
    mapping = {
        "pending":   ("订单", f"新订单: {name} x{qty}", f"?{o.total_amount:.0f}", o.created_at, "order_new"),
        "paid":      ("支付", f"支付完成: {name}", f"?{o.total_amount:.0f}", o.paid_at or o.created_at, "order_paid"),
        "shipped":   ("物流", f"已发货: {o.tracking_number or ''}", f"{o.logistics_company or ''} · {name}", o.shipped_at or o.created_at, "order_shipped"),
        "completed": ("完成", f"交易完成: {name}", f"?{o.total_amount:.0f}", o.completed_at or o.created_at, "order_completed"),
        "refunding": ("退款", f"退款申请: {name}", o.refund_reason or "", o.created_at, "order_refund"),
    }
    if o.status in mapping:
        tag, title, sub, time, typ = mapping[o.status]
        acts.append({"tag": tag, "title": title, "subtitle": sub, "time": time, "type": typ})


# ====== SHIP ORDER ======

@router.post("/orders/{order_id}/ship")
async def ship_order(order_id: str, data: dict, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    _require_admin(authorization)

    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        from routers.orders import _fetch_order_with_items
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.status != "paid":
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法发货")

    carrier = data.get("carrier", "顺丰速运")
    tracking = data.get("tracking_number", f"SF{random.randint(10**11, 10**12 - 1)}")
    now_str = datetime.now().isoformat()

    new_entries = [
        {"time": now_str, "status": "已发货", "description": f"商家已发货，{carrier} 运单号 {tracking}"},
        {"time": now_str, "status": "揽收", "description": f"快件已被{carrier}揽收"},
    ] + order.logistics_entries

    if db is not None:
        try:
            db.execute(
                text(
                    "UPDATE orders SET status='shipped', shipped_at=NOW(), "
                    "logistics_company=:carrier, tracking_no=:tracking, "
                    "logistics_entries=:entries::jsonb WHERE id=:oid"
                ),
                {
                    "carrier": carrier, "tracking": tracking,
                    "entries": json.dumps(new_entries), "oid": order_id,
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB ship_order: {e}")

    ORDERS_DB[order_id] = Order(**{
        **order.model_dump(), "status": "shipped",
        "shipped_at": now_str, "logistics_company": carrier,
        "tracking_number": tracking, "logistics_entries": new_entries,
    })

    # WS notify buyer
    try:
        from routers.ws import manager
        import asyncio
        asyncio.ensure_future(manager.send_to_user(order.user_id, {
            "type": "order_shipped", "order_id": order_id,
            "tracking_number": tracking, "carrier": carrier,
            "message": f"您的订单已发货，{carrier} 运单号 {tracking}",
        }))
    except Exception:
        pass

    return {"success": True, "message": "发货成功", "tracking_number": tracking}
