"""Orders router - DB-first with development-only in-memory fallback."""

import json
import logging
import random
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.order import Order, OrderCreate
from schemas.product import Product
from security import AuthorizationDep, is_admin_user, require_user
from store import ADDRESSES_DB, CARTS_DB, ORDERS_DB, PAYMENTS_DB, PRODUCTS_DB

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/orders", tags=["Orders"])


def _ts(value) -> Optional[str]:
    if value is None:
        return None
    return value.isoformat() if hasattr(value, "isoformat") else str(value)


def _status_from_db(status: Optional[str]) -> Optional[str]:
    return "completed" if status == "delivered" else status


def _status_to_db(status: Optional[str]) -> Optional[str]:
    return "delivered" if status == "completed" else status


def _row_to_order(mapping, items: list | None = None) -> Order:
    address = mapping.get("address_snap")
    entries = mapping.get("logistics_entries")
    if isinstance(address, str):
        address = json.loads(address)
    if isinstance(entries, str):
        entries = json.loads(entries)
    return Order(
        id=mapping["id"],
        user_id=mapping["user_id"],
        items=items or [],
        total_amount=float(mapping["total_amount"]),
        status=_status_from_db(mapping["status"]) or "pending",
        address=address,
        created_at=_ts(mapping["created_at"]) or "",
        payment_method=mapping.get("payment_method"),
        paid_at=_ts(mapping.get("paid_at")),
        shipped_at=_ts(mapping.get("shipped_at")),
        delivered_at=_ts(mapping.get("delivered_at")),
        completed_at=_ts(mapping.get("completed_at")),
        cancelled_at=_ts(mapping.get("cancelled_at")),
        cancel_reason=mapping.get("cancel_reason"),
        tracking_number=mapping.get("tracking_no"),
        logistics_company=mapping.get("logistics_company"),
        refund_reason=mapping.get("refund_reason"),
        refund_amount=float(mapping["refund_amount"]) if mapping.get("refund_amount") is not None else None,
        logistics_entries=entries if isinstance(entries, list) else [],
        payment_id=mapping.get("payment_id"),
    )


def _fetch_order_items(db: Session, order_id: str) -> list:
    rows = db.execute(
        text("SELECT product_id, product_snap, quantity, unit_price FROM order_items WHERE order_id = :oid"),
        {"oid": order_id},
    ).fetchall()
    items = []
    for row in rows:
        mapping = row._mapping
        snap = mapping["product_snap"]
        if isinstance(snap, str):
            snap = json.loads(snap)
        images = snap.get("images") if isinstance(snap, dict) else []
        items.append({
            "product_id": mapping["product_id"],
            "product_name": snap.get("name", "") if isinstance(snap, dict) else "",
            "price": float(mapping["unit_price"]),
            "quantity": mapping["quantity"],
            "image": images[0] if isinstance(images, list) and images else None,
        })
    return items


def _fetch_order(db: Session, order_id: str) -> Optional[Order]:
    row = db.execute(text("SELECT * FROM orders WHERE id = :id"), {"id": order_id}).fetchone()
    return None if not row else _row_to_order(row._mapping, _fetch_order_items(db, order_id))


def _payment(db: Session, order_id: str) -> Optional[dict]:
    row = db.execute(
        text(
            "SELECT id, order_id, amount, method, status, paid_at, created_at "
            "FROM payments WHERE order_id = :oid ORDER BY created_at DESC, id DESC LIMIT 1"
        ),
        {"oid": order_id},
    ).fetchone()
    if not row:
        return None
    mapping = row._mapping
    return {
        "id": mapping["id"],
        "order_id": mapping["order_id"],
        "amount": float(mapping["amount"]),
        "method": mapping["method"],
        "status": mapping["status"],
        "paid_at": _ts(mapping.get("paid_at")),
        "created_at": _ts(mapping.get("created_at")),
    }


def _new_order_id(prefix: str) -> str:
    return f"{prefix}{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000, 9999)}"


def _ws_notify(user_id: str, payload: dict) -> None:
    try:
        import asyncio
        from routers.ws import manager, persist_notification

        asyncio.ensure_future(manager.send_to_user(user_id, payload))
        persist_notification(user_id=user_id, title=payload.get("message", "订单通知"), body=payload.get("message", ""), ntype=payload.get("type", "order"), ref_id=payload.get("order_id"))
    except Exception:
        logger.exception("Failed to send websocket notification")


def _require_owner(order: Optional[Order], user_id: str) -> Order:
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    return order


def _load_product_from_db(db: Session, product_id: str) -> Product:
    row = db.execute(text("SELECT * FROM products WHERE id = :id AND is_active = true"), {"id": product_id}).fetchone()
    if not row:
        raise HTTPException(status_code=400, detail=f"商品 {product_id} 不存在")
    from routers.products import _row_to_product
    return _row_to_product(row._mapping)


def _address_snapshot_from_db(db: Session, address_id: str, user_id: str) -> dict:
    row = db.execute(text("SELECT * FROM addresses WHERE id = :id"), {"id": address_id}).fetchone()
    if not row:
        raise HTTPException(status_code=400, detail="收货地址不存在")
    mapping = row._mapping
    if mapping["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="收货地址不属于当前用户")
    return {
        "recipient_name": mapping["recipient_name"],
        "phone_number": mapping["phone_number"],
        "province": mapping["province"],
        "city": mapping["city"],
        "district": mapping["district"],
        "detail_address": mapping["detail_address"],
        "postal_code": mapping.get("postal_code"),
        "tag": mapping.get("tag"),
    }


@router.get("", response_model=List[Order])
async def get_orders(status: Optional[str] = None, page: int = 1, page_size: int = 20, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            conditions = ["user_id = :uid"]
            params: dict[str, object] = {"uid": user_id, "lim": page_size, "off": (page - 1) * page_size}
            if status:
                conditions.append("status = :status")
                params["status"] = _status_to_db(status)
            rows = db.execute(text(f"SELECT * FROM orders WHERE {' AND '.join(conditions)} ORDER BY created_at DESC LIMIT :lim OFFSET :off"), params).fetchall()
            return [_row_to_order(row._mapping, _fetch_order_items(db, row._mapping["id"])) for row in rows]
        except Exception as exc:
            handle_database_error(db, "读取订单列表", exc)
    require_database(db, "读取订单列表")
    orders = [order for order in ORDERS_DB.values() if order.user_id == user_id and (not status or order.status == status)]
    orders.sort(key=lambda item: item.created_at, reverse=True)
    start = (page - 1) * page_size
    return orders[start:start + page_size]


@router.get("/stats")
async def get_order_stats(authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            row = db.execute(text("SELECT count(*) AS total, coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered')), 0) AS revenue, count(*) FILTER (WHERE status = 'pending') AS pending, count(*) FILTER (WHERE status = 'paid') AS paid, count(*) FILTER (WHERE status = 'shipped') AS shipped, count(*) FILTER (WHERE status = 'delivered') AS completed, count(*) FILTER (WHERE status = 'cancelled') AS cancelled, count(*) FILTER (WHERE status = 'refunding') AS refunding FROM orders WHERE user_id = :uid"), {"uid": user_id}).fetchone()
            mapping = row._mapping
            return {"total": mapping["total"], "total_amount": round(float(mapping["revenue"]), 2), "pending": mapping["pending"], "paid": mapping["paid"], "shipped": mapping["shipped"], "completed": mapping["completed"], "cancelled": mapping["cancelled"], "refunding": mapping["refunding"]}
        except Exception as exc:
            handle_database_error(db, "读取订单统计", exc)
    require_database(db, "读取订单统计")
    mine = [order for order in ORDERS_DB.values() if order.user_id == user_id]
    stats: dict[str, int] = {}
    for order in mine:
        stats[order.status] = stats.get(order.status, 0) + 1
    total_amount = sum(order.total_amount for order in mine if order.status in ("paid", "shipped", "completed"))
    return {"total": len(mine), "total_amount": round(total_amount, 2), "pending": stats.get("pending", 0), "paid": stats.get("paid", 0), "shipped": stats.get("shipped", 0), "completed": stats.get("completed", 0), "cancelled": stats.get("cancelled", 0), "refunding": stats.get("refunding", 0)}


@router.get("/{order_id}", response_model=Order)
async def get_order_detail(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            return _require_owner(_fetch_order(db, order_id), user_id)
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取订单详情", exc)
    require_database(db, "读取订单详情")
    return _require_owner(ORDERS_DB.get(order_id), user_id)


@router.post("", response_model=Order)
async def create_order(order: OrderCreate, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    order_id = _new_order_id("ORD")
    if db is not None:
        try:
            address = _address_snapshot_from_db(db, order.address_id, user_id)
            items, total = [], 0.0
            for raw in order.items:
                product = _load_product_from_db(db, raw["product_id"])
                qty = raw.get("quantity", 1)
                if product.stock < qty:
                    raise HTTPException(status_code=400, detail=f"商品 {product.name} 库存不足 (剩余 {product.stock})")
                total += product.price * qty
                items.append({"product_id": raw["product_id"], "product_name": product.name, "price": product.price, "quantity": qty, "image": product.images[0] if product.images else None})
            db.execute(text("INSERT INTO orders (id, user_id, address_id, address_snap, total_amount, status, payment_method, remark) VALUES (:id, :uid, :aid, :snap::jsonb, :total, 'pending', :method, :remark)"), {"id": order_id, "uid": user_id, "aid": order.address_id, "snap": json.dumps(address), "total": total, "method": order.payment_method, "remark": order.remark})
            for item in items:
                db.execute(text("INSERT INTO order_items (order_id, product_id, product_snap, quantity, unit_price, subtotal) VALUES (:oid, :pid, :snap::jsonb, :qty, :price, :subtotal)"), {"oid": order_id, "pid": item["product_id"], "snap": json.dumps({"name": item["product_name"], "images": [item["image"]] if item["image"] else []}), "qty": item["quantity"], "price": item["price"], "subtotal": item["price"] * item["quantity"]})
                db.execute(text("UPDATE products SET stock = stock - :qty, sales_count = sales_count + :qty WHERE id = :pid"), {"qty": item["quantity"], "pid": item["product_id"]})
                db.execute(text("DELETE FROM cart_items WHERE user_id = :uid AND product_id = :pid"), {"uid": user_id, "pid": item["product_id"]})
            db.commit()
            created = _fetch_order(db, order_id) or Order(id=order_id, user_id=user_id, items=items, total_amount=total, status="pending", address=address, created_at=datetime.now().isoformat(), payment_method=order.payment_method)
            _ws_notify(user_id, {"type": "order_created", "order_id": order_id, "message": f"订单 {order_id} 已创建"})
            return created
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "创建订单", exc)
    require_database(db, "创建订单")
    if order.address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=400, detail="收货地址不存在")
    address_model = ADDRESSES_DB[order.address_id]
    if address_model.user_id != user_id:
        raise HTTPException(status_code=403, detail="收货地址不属于当前用户")
    address = address_model.model_dump()
    items, total = [], 0.0
    for raw in order.items:
        product = PRODUCTS_DB.get(raw["product_id"])
        if product is None:
            raise HTTPException(status_code=400, detail=f"商品 {raw['product_id']} 不存在")
        qty = raw.get("quantity", 1)
        if product.stock < qty:
            raise HTTPException(status_code=400, detail=f"商品 {product.name} 库存不足 (剩余 {product.stock})")
        total += product.price * qty
        items.append({"product_id": raw["product_id"], "product_name": product.name, "price": product.price, "quantity": qty, "image": product.images[0] if product.images else None})
    for item in items:
        product = PRODUCTS_DB[item["product_id"]]
        PRODUCTS_DB[item["product_id"]] = Product(**{**product.model_dump(), "stock": product.stock - item["quantity"], "sales_count": product.sales_count + item["quantity"]})
    created = Order(id=order_id, user_id=user_id, items=items, total_amount=total, status="pending", address=address, created_at=datetime.now().isoformat(), payment_method=order.payment_method)
    ORDERS_DB[order_id] = created
    if user_id in CARTS_DB:
        ordered = {item["product_id"] for item in order.items}
        CARTS_DB[user_id] = [cart_item for cart_item in CARTS_DB[user_id] if cart_item.product_id not in ordered]
    _ws_notify(user_id, {"type": "order_created", "order_id": order_id, "message": f"订单 {order_id} 已创建"})
    return created


@router.post("/checkout")
async def checkout(data: dict, authorization: AuthorizationDep = None):
    require_user(authorization)
    return {"success": True, "order_id": data.get("order_id"), "payment_url": f"https://pay.example.com/{data.get('order_id')}", "message": "请完成支付"}


@router.post("/{order_id}/pay")
async def pay_order(order_id: str, data: dict | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    data = data or {}
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status != "pending":
                raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法支付")
            payment_id = _new_order_id("PAY")
            method = data.get("method", order.payment_method or "wechat")
            db.execute(text("INSERT INTO payments (order_id, user_id, amount, method, status) VALUES (:oid, :uid, :amount, :method, 'pending')"), {"oid": order_id, "uid": user_id, "amount": order.total_amount, "method": method})
            db.execute(text("UPDATE orders SET payment_id = :pid, payment_method = :method WHERE id = :oid"), {"pid": payment_id, "method": method, "oid": order_id})
            db.commit()
            return {"success": True, "payment_id": payment_id, "amount": order.total_amount, "method": method, "status": "pending", "message": "支付已创建，请等待确认"}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "创建支付单", exc)
    require_database(db, "创建支付单")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法支付")
    payment_id = _new_order_id("PAY")
    method = data.get("method", order.payment_method or "wechat")
    PAYMENTS_DB[payment_id] = {"id": payment_id, "order_id": order_id, "amount": order.total_amount, "method": method, "status": "pending", "created_at": datetime.now().isoformat()}
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "payment_id": payment_id})
    return {"success": True, "payment_id": payment_id, "amount": order.total_amount, "method": method, "status": "pending", "message": "支付已创建，请等待确认"}


@router.get("/{order_id}/pay-status")
async def get_pay_status(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            pay = _payment(db, order_id)
            if not pay or not order.payment_id:
                return {"status": "no_payment", "message": "未找到支付记录"}
            if pay["status"] == "pending" and (datetime.now() - datetime.fromisoformat(pay["created_at"])).total_seconds() >= 3:
                now = datetime.now().isoformat()
                entries = [{"time": now, "status": "支付成功", "description": f"订单已支付 ¥{order.total_amount:.2f} ({pay['method']})"}] + order.logistics_entries
                db.execute(text("UPDATE orders SET status = 'paid', paid_at = NOW(), logistics_entries = :entries::jsonb WHERE id = :oid"), {"entries": json.dumps(entries), "oid": order_id})
                db.execute(text("UPDATE payments SET status = 'success', paid_at = NOW() WHERE order_id = :oid AND status = 'pending'"), {"oid": order_id})
                db.commit()
                pay["status"] = "success"
                pay["paid_at"] = now
                _ws_notify(user_id, {"type": "payment_success", "order_id": order_id, "message": f"订单 {order_id} 支付成功"})
            return {"payment_id": order.payment_id, "status": pay["status"], "amount": pay["amount"], "method": pay["method"], "paid_at": pay.get("paid_at")}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "读取支付状态", exc)
    require_database(db, "读取支付状态")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    pid = order.payment_id
    if not pid or pid not in PAYMENTS_DB:
        return {"status": "no_payment", "message": "未找到支付记录"}
    pay = PAYMENTS_DB[pid]
    if pay["status"] == "pending" and (datetime.now() - datetime.fromisoformat(pay["created_at"])).total_seconds() >= 3:
        now = datetime.now().isoformat()
        pay["status"] = "success"
        pay["paid_at"] = now
        PAYMENTS_DB[pid] = pay
        ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "paid", "paid_at": now, "logistics_entries": [{"time": now, "status": "支付成功", "description": f"订单已支付 ¥{order.total_amount:.2f} ({pay['method']})"}] + order.logistics_entries})
        _ws_notify(user_id, {"type": "payment_success", "order_id": order_id, "message": f"订单 {order_id} 支付成功"})
    return {"payment_id": pid, "status": pay["status"], "amount": pay["amount"], "method": pay["method"], "paid_at": pay.get("paid_at")}


@router.post("/{order_id}/cancel")
async def cancel_order(order_id: str, data: dict | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    reason = (data or {}).get("reason", "用户主动取消")
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status not in ("pending", "paid"):
                raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法取消")
            entries = [{"time": datetime.now().isoformat(), "status": "订单已取消", "description": reason}] + order.logistics_entries
            for item in order.items:
                db.execute(text("UPDATE products SET stock = stock + :qty, sales_count = GREATEST(sales_count - :qty, 0) WHERE id = :pid"), {"qty": item.get("quantity", 1), "pid": item.get("product_id")})
            db.execute(text("UPDATE orders SET status = 'cancelled', cancelled_at = NOW(), cancel_reason = :reason, logistics_entries = :entries::jsonb WHERE id = :oid"), {"reason": reason, "entries": json.dumps(entries), "oid": order_id})
            db.commit()
            return {"success": True, "message": "订单已取消，库存已恢复"}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "取消订单", exc)
    require_database(db, "取消订单")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status not in ("pending", "paid"):
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法取消")
    for item in order.items:
        pid = item.get("product_id")
        if pid and pid in PRODUCTS_DB:
            product = PRODUCTS_DB[pid]
            PRODUCTS_DB[pid] = Product(**{**product.model_dump(), "stock": product.stock + item.get("quantity", 1), "sales_count": max(0, product.sales_count - item.get("quantity", 1))})
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "cancelled", "cancelled_at": datetime.now().isoformat(), "cancel_reason": reason, "logistics_entries": [{"time": datetime.now().isoformat(), "status": "订单已取消", "description": reason}] + order.logistics_entries})
    return {"success": True, "message": "订单已取消，库存已恢复"}


@router.post("/{order_id}/confirm-receipt")
async def confirm_receipt(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status != "shipped":
                raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法确认收货")
            entries = [{"time": datetime.now().isoformat(), "status": "已签收", "description": "买家已确认收货，交易完成"}] + order.logistics_entries
            db.execute(text("UPDATE orders SET status = 'delivered', delivered_at = NOW(), completed_at = NOW(), logistics_entries = :entries::jsonb WHERE id = :oid"), {"entries": json.dumps(entries), "oid": order_id})
            db.commit()
            return {"success": True, "message": "已确认收货"}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "确认收货", exc)
    require_database(db, "确认收货")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status != "shipped":
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法确认收货")
    now = datetime.now().isoformat()
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "completed", "delivered_at": now, "completed_at": now, "logistics_entries": [{"time": now, "status": "已签收", "description": "买家已确认收货，交易完成"}] + order.logistics_entries})
    return {"success": True, "message": "已确认收货"}


@router.post("/{order_id}/refund")
async def request_refund(order_id: str, data: dict | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    reason = (data or {}).get("reason", "买家申请退款")
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status not in ("paid", "shipped", "completed"):
                raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法退款")
            entries = [{"time": datetime.now().isoformat(), "status": "退款申请", "description": f"买家申请退款: {reason}"}] + order.logistics_entries
            db.execute(text("UPDATE orders SET status = 'refunding', refund_reason = :reason, refund_amount = :amount, logistics_entries = :entries::jsonb WHERE id = :oid"), {"reason": reason, "amount": order.total_amount, "entries": json.dumps(entries), "oid": order_id})
            db.commit()
            return {"success": True, "message": "退款申请已提交", "refund_amount": order.total_amount}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "申请退款", exc)
    require_database(db, "申请退款")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status not in ("paid", "shipped", "completed"):
        raise HTTPException(status_code=400, detail=f"订单状态为 {order.status}，无法退款")
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "refunding", "refund_reason": reason, "refund_amount": order.total_amount, "logistics_entries": [{"time": datetime.now().isoformat(), "status": "退款申请", "description": f"买家申请退款: {reason}"}] + order.logistics_entries})
    return {"success": True, "message": "退款申请已提交", "refund_amount": order.total_amount}


@router.get("/{order_id}/logistics")
async def get_order_logistics(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            order = _fetch_order(db, order_id)
            if not order:
                raise HTTPException(status_code=404, detail="订单不存在")
            if order.user_id != user_id and not is_admin_user(user_id, db):
                raise HTTPException(status_code=403, detail="没有权限")
            return {"order_id": order_id, "carrier": order.logistics_company, "tracking_number": order.tracking_number, "status": order.status, "entries": order.logistics_entries}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取物流信息", exc)
    require_database(db, "读取物流信息")
    order = ORDERS_DB.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.user_id != user_id and not is_admin_user(user_id, db):
        raise HTTPException(status_code=403, detail="没有权限")
    return {"order_id": order_id, "carrier": order.logistics_company, "tracking_number": order.tracking_number, "status": order.status, "entries": order.logistics_entries}
