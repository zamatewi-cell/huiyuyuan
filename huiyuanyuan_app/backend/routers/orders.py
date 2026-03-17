"""
Orders router - create / pay / cancel / ship / confirm / refund / logistics / stats
DB-first with in-memory fallback
"""

import json
import random
import logging
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.order import Order, OrderCreate
from schemas.product import Product
from security import require_user
from database import get_db
from store import (
    ORDERS_DB, PRODUCTS_DB, ADDRESSES_DB,
    CARTS_DB, USERS_DB, PAYMENTS_DB,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/orders", tags=["Orders"])


# ---- helpers ----

def _row_to_order(m, items: list = None) -> Order:
    addr = m.get("address_snap")
    if isinstance(addr, str):
        addr = json.loads(addr)
    entries = m.get("logistics_entries")
    if isinstance(entries, str):
        entries = json.loads(entries)
    return Order(
        id=m["id"],
        user_id=m["user_id"],
        items=items or [],
        total_amount=float(m["total_amount"]),
        status=m["status"],
        address=addr,
        created_at=m["created_at"].isoformat() if hasattr(m["created_at"], "isoformat") else str(m["created_at"]),
        payment_method=m.get("payment_method"),
        paid_at=_ts(m.get("paid_at")),
        shipped_at=_ts(m.get("shipped_at")),
        delivered_at=_ts(m.get("delivered_at")),
        completed_at=_ts(m.get("completed_at")),
        cancelled_at=_ts(m.get("cancelled_at")),
        cancel_reason=m.get("cancel_reason"),
        tracking_number=m.get("tracking_no"),
        logistics_company=m.get("logistics_company"),
        refund_reason=m.get("refund_reason"),
        refund_amount=float(m["refund_amount"]) if m.get("refund_amount") else None,
        logistics_entries=entries if isinstance(entries, list) else [],
        payment_id=m.get("payment_id"),
    )


def _ts(val) -> Optional[str]:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


def _fetch_order_items(db: Session, order_id: str) -> list:
    rows = db.execute(
        text(
            "SELECT product_id, product_snap, quantity, unit_price "
            "FROM order_items WHERE order_id = :oid"
        ),
        {"oid": order_id},
    ).fetchall()
    items = []
    for r in rows:
        m = r._mapping
        snap = m["product_snap"]
        if isinstance(snap, str):
            snap = json.loads(snap)
        items.append({
            "product_id": m["product_id"],
            "product_name": snap.get("name", ""),
            "price": float(m["unit_price"]),
            "quantity": m["quantity"],
            "image": snap.get("images", [None])[0] if isinstance(snap.get("images"), list) else None,
        })
    return items


def _fetch_order_with_items(db: Session, order_id: str) -> Optional[Order]:
    row = db.execute(
        text("SELECT * FROM orders WHERE id = :id"), {"id": order_id}
    ).fetchone()
    if not row:
        return None
    items = _fetch_order_items(db, order_id)
    return _row_to_order(row._mapping, items)


def _ws_notify(user_id: str, payload: dict):
    try:
        from routers.ws import manager, persist_notification
        import asyncio
        asyncio.ensure_future(manager.send_to_user(user_id, payload))
        # Persist to DB for offline retrieval
        persist_notification(
            user_id=user_id,
            title=payload.get("message", "订单通知"),
            body=payload.get("message", ""),
            ntype=payload.get("type", "order"),
            ref_id=payload.get("order_id"),
        )
    except Exception:
        pass


# ====== LIST ======

@router.get("", response_model=List[Order])
async def get_orders(
    status: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    authorization: str = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            conds = ["o.user_id = :uid"]
            params: dict = {"uid": user_id}
            if status:
                conds.append("o.status = :status")
                params["status"] = status

            params["lim"] = page_size
            params["off"] = (page - 1) * page_size
            where = " AND ".join(conds)

            rows = db.execute(
                text(
                    f"SELECT * FROM orders o WHERE {where} "
                    f"ORDER BY o.created_at DESC LIMIT :lim OFFSET :off"
                ),
                params,
            ).fetchall()

            orders = []
            for r in rows:
                items = _fetch_order_items(db, r._mapping["id"])
                orders.append(_row_to_order(r._mapping, items))
            return orders
        except Exception as e:
            logger.error(f"DB get_orders: {e}")

    # memory
    orders = [o for o in ORDERS_DB.values() if o.user_id == user_id]
    if status:
        orders = [o for o in orders if o.status == status]
    orders.sort(key=lambda x: x.created_at, reverse=True)
    start = (page - 1) * page_size
    return orders[start : start + page_size]


# ====== STATS ======

@router.get("/stats")
async def get_order_stats(authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if db is not None:
        try:
            row = db.execute(
                text(
                    "SELECT "
                    "  count(*) as total, "
                    "  coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered')), 0) as revenue, "
                    "  count(*) FILTER (WHERE status = 'pending') as pending, "
                    "  count(*) FILTER (WHERE status = 'paid') as paid, "
                    "  count(*) FILTER (WHERE status = 'shipped') as shipped, "
                    "  count(*) FILTER (WHERE status = 'delivered') as completed, "
                    "  count(*) FILTER (WHERE status = 'cancelled') as cancelled, "
                    "  count(*) FILTER (WHERE status = 'refunding') as refunding "
                    "FROM orders WHERE user_id = :uid"
                ),
                {"uid": user_id},
            ).fetchone()
            m = row._mapping
            return {
                "total": m["total"],
                "total_amount": round(float(m["revenue"]), 2),
                "pending": m["pending"], "paid": m["paid"],
                "shipped": m["shipped"], "completed": m["completed"],
                "cancelled": m["cancelled"], "refunding": m["refunding"],
            }
        except Exception as e:
            logger.error(f"DB get_order_stats: {e}")

    my = [o for o in ORDERS_DB.values() if o.user_id == user_id]
    total_amount = sum(o.total_amount for o in my if o.status in ("paid", "shipped", "completed"))
    sc: dict = {}
    for o in my:
        sc[o.status] = sc.get(o.status, 0) + 1
    return {
        "total": len(my), "total_amount": round(total_amount, 2),
        "pending": sc.get("pending", 0), "paid": sc.get("paid", 0),
        "shipped": sc.get("shipped", 0), "completed": sc.get("completed", 0),
        "cancelled": sc.get("cancelled", 0), "refunding": sc.get("refunding", 0),
    }


# ====== DETAIL ======

@router.get("/{order_id}", response_model=Order)
async def get_order_detail(order_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if db is not None:
        try:
            order = _fetch_order_with_items(db, order_id)
            if order:
                if order.user_id != user_id:
                    raise HTTPException(status_code=403, detail="没有权限")
                return order
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"DB get_order_detail: {e}")

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")
    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    return order


# ====== CREATE ======

@router.post("", response_model=Order)
async def create_order(order: OrderCreate, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    # validate address
    address_data = None
    if db is not None:
        row = db.execute(
            text("SELECT * FROM addresses WHERE id = :id"), {"id": order.address_id}
        ).fetchone()
        if row:
            m = row._mapping
            if m["user_id"] != user_id:
                raise HTTPException(status_code=403, detail="地址不属于当前用户")
            address_data = {
                "recipient_name": m["recipient_name"], "phone_number": m["phone_number"],
                "province": m["province"], "city": m["city"],
                "district": m["district"], "detail_address": m["detail_address"],
            }

    if address_data is None:
        if order.address_id not in ADDRESSES_DB:
            raise HTTPException(status_code=400, detail="地址不存在")
        addr = ADDRESSES_DB[order.address_id]
        if addr.user_id != user_id:
            raise HTTPException(status_code=403, detail="地址不属于当前用户")
        address_data = addr.model_dump()

    # compute items + total
    total = 0.0
    items = []
    for item in order.items:
        pid = item["product_id"]
        qty = item.get("quantity", 1)

        product = PRODUCTS_DB.get(pid)
        if product is None and db is not None:
            prow = db.execute(
                text("SELECT * FROM products WHERE id = :id AND is_active = true"),
                {"id": pid},
            ).fetchone()
            if prow:
                from routers.products import _row_to_product
                product = _row_to_product(prow._mapping)

        if product is None:
            raise HTTPException(status_code=400, detail=f"商品 {pid} 不存在")

        if product.stock < qty:
            raise HTTPException(
                status_code=400,
                detail=f"商品 {product.name} 库存不足 (剩余{product.stock}件)",
            )

        total += product.price * qty
        items.append({
            "product_id": pid,
            "product_name": product.name,
            "price": product.price,
            "quantity": qty,
            "image": product.images[0] if product.images else None,
        })

    order_id = f"ORD{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000, 9999)}"

    # ---- DB write ----
    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO orders "
                    "(id, user_id, address_id, address_snap, total_amount, status, payment_method, remark) "
                    "VALUES (:id, :uid, :aid, :snap::jsonb, :total, 'pending', :method, :remark)"
                ),
                {
                    "id": order_id, "uid": user_id, "aid": order.address_id,
                    "snap": json.dumps(address_data), "total": total,
                    "method": order.payment_method, "remark": order.remark,
                },
            )
            for it in items:
                snap = {"name": it["product_name"], "images": [it["image"]] if it["image"] else []}
                db.execute(
                    text(
                        "INSERT INTO order_items "
                        "(order_id, product_id, product_snap, quantity, unit_price, subtotal) "
                        "VALUES (:oid, :pid, :snap::jsonb, :qty, :price, :sub)"
                    ),
                    {
                        "oid": order_id, "pid": it["product_id"],
                        "snap": json.dumps(snap), "qty": it["quantity"],
                        "price": it["price"], "sub": it["price"] * it["quantity"],
                    },
                )
            # stock deduction
            for it in items:
                db.execute(
                    text(
                        "UPDATE products SET stock = stock - :qty, "
                        "sales_count = sales_count + :qty WHERE id = :pid"
                    ),
                    {"qty": it["quantity"], "pid": it["product_id"]},
                )
            # clear cart items that were ordered
            ordered_pids = [it["product_id"] for it in items]
            for pid in ordered_pids:
                db.execute(
                    text("DELETE FROM cart_items WHERE user_id = :uid AND product_id = :pid"),
                    {"uid": user_id, "pid": pid},
                )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB create_order: {e}")

    # ---- memory write-through ----
    for it in items:
        pid = it["product_id"]
        if pid in PRODUCTS_DB:
            p = PRODUCTS_DB[pid]
            PRODUCTS_DB[pid] = Product(**{
                **p.model_dump(),
                "stock": p.stock - it["quantity"],
                "sales_count": p.sales_count + it["quantity"],
            })

    new_order = Order(
        id=order_id, user_id=user_id, items=items,
        total_amount=total, status="pending",
        address=address_data,
        created_at=datetime.now().isoformat(),
        payment_method=order.payment_method,
    )
    ORDERS_DB[order_id] = new_order

    if user_id in CARTS_DB:
        ordered_ids = {i["product_id"] for i in order.items}
        CARTS_DB[user_id] = [c for c in CARTS_DB[user_id] if c.product_id not in ordered_ids]

    _ws_notify(user_id, {"type": "order_created", "order_id": order_id, "message": f"订单 {order_id} 已创建"})
    return new_order


# ====== CHECKOUT ======

@router.post("/checkout")
async def checkout(data: dict, authorization: str = None):
    return {
        "success": True, "order_id": data.get("order_id"),
        "payment_url": f"https://pay.example.com/{data.get('order_id')}",
        "message": "请完成支付",
    }


# ====== PAY ======

@router.post("/{order_id}/pay")
async def pay_order(order_id: str, data: dict = None, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    data = data or {}

    # load order
    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法支付")

    payment_id = f"PAY{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000, 9999)}"
    method = data.get("method", order.payment_method or "wechat")

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO payments (order_id, user_id, amount, method, status) "
                    "VALUES (:oid, :uid, :amt, :method, 'pending')"
                ),
                {"oid": order_id, "uid": user_id, "amt": order.total_amount, "method": method},
            )
            db.execute(
                text("UPDATE orders SET payment_id = :pid, payment_method = :method WHERE id = :oid"),
                {"pid": payment_id, "method": method, "oid": order_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB pay_order: {e}")

    PAYMENTS_DB[payment_id] = {
        "id": payment_id, "order_id": order_id,
        "amount": order.total_amount, "method": method,
        "status": "pending", "created_at": datetime.now().isoformat(),
    }
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "payment_id": payment_id})

    return {
        "success": True, "payment_id": payment_id,
        "amount": order.total_amount, "method": method,
        "status": "pending", "message": "支付已创建，请等待确认",
    }


# ====== PAY STATUS ======

@router.get("/{order_id}/pay-status")
async def get_pay_status(order_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")

    pid = order.payment_id
    if not pid or pid not in PAYMENTS_DB:
        return {"status": "no_payment", "message": "未找到支付记录"}

    pay = PAYMENTS_DB[pid]

    # auto-callback after 3s
    if pay["status"] == "pending":
        created = datetime.fromisoformat(pay["created_at"])
        if (datetime.now() - created).total_seconds() >= 3:
            pay["status"] = "success"
            pay["paid_at"] = datetime.now().isoformat()
            PAYMENTS_DB[pid] = pay

            now_str = datetime.now().isoformat()
            new_entries = [
                {"time": now_str, "status": "支付成功",
                 "description": f"订单已支付 ?{order.total_amount:.2f} ({pay['method']})"}
            ] + order.logistics_entries

            updated = Order(**{
                **order.model_dump(),
                "status": "paid", "paid_at": now_str,
                "logistics_entries": new_entries,
            })
            ORDERS_DB[order_id] = updated

            if db is not None:
                try:
                    db.execute(
                        text(
                            "UPDATE orders SET status='paid', paid_at=NOW(), "
                            "logistics_entries=:entries::jsonb WHERE id=:oid"
                        ),
                        {"entries": json.dumps(new_entries), "oid": order_id},
                    )
                    db.execute(
                        text("UPDATE payments SET status='success', paid_at=NOW() WHERE order_id=:oid"),
                        {"oid": order_id},
                    )
                    db.commit()
                except Exception as e:
                    db.rollback()
                    logger.error(f"DB pay_status update: {e}")

            _ws_notify(user_id, {
                "type": "payment_success", "order_id": order_id,
                "message": f"订单 {order_id} 支付成功",
            })

    return {
        "payment_id": pid, "status": pay["status"],
        "amount": pay["amount"], "method": pay["method"],
        "paid_at": pay.get("paid_at"),
    }


# ====== CANCEL ======

@router.post("/{order_id}/cancel")
async def cancel_order(order_id: str, data: dict = None, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    data = data or {}

    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status not in ("pending", "paid"):
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法取消")

    reason = data.get("reason", "用户主动取消")
    now_str = datetime.now().isoformat()

    new_entries = [
        {"time": now_str, "status": "订单已取消", "description": reason}
    ] + order.logistics_entries

    # restore stock
    if db is not None:
        try:
            for it in order.items:
                pid = it.get("product_id")
                qty = it.get("quantity", 1)
                if pid:
                    db.execute(
                        text(
                            "UPDATE products SET stock = stock + :qty, "
                            "sales_count = GREATEST(sales_count - :qty, 0) "
                            "WHERE id = :pid"
                        ),
                        {"qty": qty, "pid": pid},
                    )
            db.execute(
                text(
                    "UPDATE orders SET status='cancelled', cancelled_at=NOW(), "
                    "cancel_reason=:reason, logistics_entries=:entries::jsonb "
                    "WHERE id=:oid"
                ),
                {"reason": reason, "entries": json.dumps(new_entries), "oid": order_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB cancel_order: {e}")

    # memory
    for it in order.items:
        pid = it.get("product_id")
        qty = it.get("quantity", 1)
        if pid and pid in PRODUCTS_DB:
            p = PRODUCTS_DB[pid]
            PRODUCTS_DB[pid] = Product(**{
                **p.model_dump(), "stock": p.stock + qty,
                "sales_count": max(0, p.sales_count - qty),
            })

    ORDERS_DB[order_id] = Order(**{
        **order.model_dump(), "status": "cancelled",
        "cancelled_at": now_str, "cancel_reason": reason,
        "logistics_entries": new_entries,
    })
    return {"success": True, "message": "订单已取消，库存已恢复"}


# ====== CONFIRM RECEIPT ======

@router.post("/{order_id}/confirm-receipt")
async def confirm_receipt(order_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status != "shipped":
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法确认收货")

    now_str = datetime.now().isoformat()
    new_entries = [
        {"time": now_str, "status": "已签收", "description": "买家已确认收货，交易完成"}
    ] + order.logistics_entries

    if db is not None:
        try:
            db.execute(
                text(
                    "UPDATE orders SET status='delivered', delivered_at=NOW(), "
                    "completed_at=NOW(), logistics_entries=:entries::jsonb "
                    "WHERE id=:oid"
                ),
                {"entries": json.dumps(new_entries), "oid": order_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB confirm_receipt: {e}")

    ORDERS_DB[order_id] = Order(**{
        **order.model_dump(), "status": "completed",
        "delivered_at": now_str, "completed_at": now_str,
        "logistics_entries": new_entries,
    })
    return {"success": True, "message": "已确认收货"}


# ====== REFUND ======

@router.post("/{order_id}/refund")
async def request_refund(order_id: str, data: dict = None, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    data = data or {}

    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status not in ("paid", "shipped", "completed"):
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法退款")

    reason = data.get("reason", "买家申请退款")
    now_str = datetime.now().isoformat()
    new_entries = [
        {"time": now_str, "status": "退款申请", "description": f"买家申请退款: {reason}"}
    ] + order.logistics_entries

    if db is not None:
        try:
            db.execute(
                text(
                    "UPDATE orders SET status='refunding', refund_reason=:reason, "
                    "refund_amount=:amt, logistics_entries=:entries::jsonb WHERE id=:oid"
                ),
                {
                    "reason": reason, "amt": order.total_amount,
                    "entries": json.dumps(new_entries), "oid": order_id,
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB request_refund: {e}")

    ORDERS_DB[order_id] = Order(**{
        **order.model_dump(), "status": "refunding",
        "refund_reason": reason, "refund_amount": order.total_amount,
        "logistics_entries": new_entries,
    })
    return {"success": True, "message": "退款申请已提交", "refund_amount": order.total_amount}


# ====== LOGISTICS ======

@router.get("/{order_id}/logistics")
async def get_order_logistics(order_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    order = ORDERS_DB.get(order_id)
    if order is None and db is not None:
        order = _fetch_order_with_items(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        user = USERS_DB.get(user_id, {})
        if not user.get("is_admin"):
            raise HTTPException(status_code=403, detail="没有权限")

    return {
        "order_id": order_id,
        "carrier": order.logistics_company,
        "tracking_number": order.tracking_number,
        "status": order.status,
        "entries": order.logistics_entries,
    }
