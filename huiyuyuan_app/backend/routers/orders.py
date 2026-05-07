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
from security import (
    AuthorizationDep,
    get_user_record,
    has_permission,
    is_admin_user,
    require_user,
)
from store import (
    ADDRESSES_DB,
    CARTS_DB,
    ORDERS_DB,
    PAYMENT_ACCOUNTS_DB,
    PAYMENTS_DB,
    PRODUCTS_DB,
    USERS_DB,
)

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


def _payment_account_to_public(mapping) -> dict:
    return {
        "id": mapping["id"],
        "user_id": mapping["user_id"],
        "name": mapping.get("account_name") or mapping.get("name") or "",
        "type": mapping.get("account_type") or mapping.get("type") or "other",
        "account_number": mapping.get("account_number"),
        "bank_name": mapping.get("bank_name"),
        "qr_code_url": mapping.get("qr_code_url"),
        "is_active": bool(mapping.get("is_active", True)),
        "is_default": bool(mapping.get("is_default", False)),
        "created_at": _ts(mapping.get("created_at")),
        "updated_at": _ts(mapping.get("updated_at")),
    }


def _resolve_payment_account_type(method: Optional[str]) -> Optional[str]:
    raw = (method or "").strip().lower()
    if raw in {"wechat", "alipay", "cash", "other"}:
        return raw
    if raw in {"unionpay", "bank", "balance"}:
        return "bank"
    return None


def _fetch_payment_account_by_id(db: Session, account_id: Optional[str]) -> Optional[dict]:
    if not account_id:
        return None
    row = db.execute(
        text("SELECT * FROM payment_accounts WHERE id = :id LIMIT 1"),
        {"id": account_id},
    ).fetchone()
    return None if not row else _payment_account_to_public(row._mapping)


def _fetch_payment_account_by_id_from_memory(account_id: Optional[str]) -> Optional[dict]:
    if not account_id:
        return None
    account = PAYMENT_ACCOUNTS_DB.get(account_id)
    return None if not account else _payment_account_to_public(account.model_dump())


def _find_platform_payment_account(
    db: Optional[Session],
    method: Optional[str],
) -> Optional[dict]:
    account_type = _resolve_payment_account_type(method)
    strict_match = account_type is not None and (method or "").strip() != ""

    if db is not None:
        try:
            if account_type:
                row = db.execute(
                    text(
                        "SELECT pa.* FROM payment_accounts pa "
                        "JOIN users u ON u.id = pa.user_id "
                        "WHERE u.user_type = 'admin' AND pa.is_active = true "
                        "AND pa.account_type = :account_type "
                        "ORDER BY pa.is_default DESC, pa.updated_at DESC, pa.created_at DESC "
                        "LIMIT 1"
                    ),
                    {"account_type": account_type},
                ).fetchone()
                if row:
                    return _payment_account_to_public(row._mapping)
                if strict_match:
                    return None

            row = db.execute(
                text(
                    "SELECT pa.* FROM payment_accounts pa "
                    "JOIN users u ON u.id = pa.user_id "
                    "WHERE u.user_type = 'admin' AND pa.is_active = true "
                    "ORDER BY pa.is_default DESC, pa.updated_at DESC, pa.created_at DESC "
                    "LIMIT 1"
                )
            ).fetchone()
            if row:
                return _payment_account_to_public(row._mapping)
        except Exception:
            logger.debug("payment_accounts lookup skipped for method=%s", method, exc_info=True)

    admin_ids = {
        user_id
        for user_id, user in USERS_DB.items()
        if user.get("user_type") == "admin" or user.get("is_admin") is True
    }
    if not admin_ids:
        return None

    candidates = [
        account
        for account in PAYMENT_ACCOUNTS_DB.values()
        if account.user_id in admin_ids and account.is_active
    ]
    if not candidates:
        return None

    if account_type:
        typed = [account for account in candidates if account.type == account_type]
        if typed:
            typed.sort(key=lambda item: (not item.is_default, -(item.updated_at.timestamp())))
            return _payment_account_to_public(typed[0].model_dump())
        if strict_match:
            return None

    candidates.sort(key=lambda item: (not item.is_default, -(item.updated_at.timestamp())))
    return _payment_account_to_public(candidates[0].model_dump())


def _row_to_order(
    mapping,
    items: list | None = None,
    payment_account: dict | None = None,
    payment_record: dict | None = None,
) -> Order:
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
        payment_account_id=mapping.get("payment_account_id"),
        payment_account=payment_account,
        payment_voucher_url=None if payment_record is None else payment_record.get("voucher_url"),
        payment_admin_note=None if payment_record is None else payment_record.get("admin_note"),
        payment_record_status=None if payment_record is None else payment_record.get("status"),
        payment_confirmed_by=None if payment_record is None else payment_record.get("confirmed_by"),
        payment_confirmed_at=None if payment_record is None else payment_record.get("confirmed_at"),
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
    if not row:
        return None
    mapping = row._mapping
    payment_account = _fetch_payment_account_by_id(db, mapping.get("payment_account_id"))
    return _row_to_order(
        mapping,
        _fetch_order_items(db, order_id),
        payment_account,
        _payment(db, order_id),
    )


def _payment(db: Session, order_id: str) -> Optional[dict]:
    row = db.execute(
        text(
            "SELECT payment_id, order_id, amount, payment_method, status, "
            "voucher_url, admin_note, confirmed_by, confirmed_at, created_at "
            "FROM payment_records "
            "WHERE order_id = :oid ORDER BY created_at DESC, payment_id DESC LIMIT 1"
        ),
        {"oid": order_id},
    ).fetchone()
    if not row:
        return None
    mapping = row._mapping
    return {
        "id": mapping["payment_id"],
        "payment_id": mapping["payment_id"],
        "order_id": mapping["order_id"],
        "amount": float(mapping["amount"]),
        "method": mapping["payment_method"],
        "status": mapping["status"],
        "voucher_url": mapping.get("voucher_url"),
        "admin_note": mapping.get("admin_note"),
        "confirmed_by": mapping.get("confirmed_by"),
        "confirmed_at": _ts(mapping.get("confirmed_at")),
        "paid_at": _ts(mapping.get("confirmed_at")),
        "created_at": _ts(mapping.get("created_at")),
    }


def _memory_payment(order: Order) -> Optional[dict]:
    if order.payment_id:
        from services.payment_service import get_payment_record

        payment = get_payment_record(order.payment_id) or PAYMENTS_DB.get(order.payment_id)
        if payment:
            return {
                "id": order.payment_id,
                "payment_id": order.payment_id,
                "order_id": order.id,
                "amount": float(payment.get("amount", order.total_amount)),
                "method": payment.get("method") or payment.get("payment_method"),
                "status": payment.get("status"),
                "voucher_url": payment.get("voucher_url"),
                "admin_note": payment.get("admin_note"),
                "confirmed_by": payment.get("confirmed_by"),
                "confirmed_at": payment.get("confirmed_at") or payment.get("paid_at"),
                "paid_at": payment.get("paid_at") or payment.get("confirmed_at"),
                "created_at": payment.get("created_at"),
            }
    return None


def _payment_order_fields(payment_record: Optional[dict]) -> dict:
    if not payment_record:
        return {}
    return {
        "payment_voucher_url": payment_record.get("voucher_url"),
        "payment_admin_note": payment_record.get("admin_note"),
        "payment_record_status": payment_record.get("status"),
        "payment_confirmed_by": payment_record.get("confirmed_by"),
        "payment_confirmed_at": payment_record.get("confirmed_at"),
    }


def _payment_status_message(status: Optional[str]) -> str:
    if status in {"pending", "awaiting_confirmation"}:
        return "Awaiting admin confirmation"
    if status == "confirmed":
        return "鏀粯鎴愬姛"
    if status == "cancelled":
        return "Payment cancelled"
    if status == "timeout":
        return "支付超时"
    if status == "disputed":
        return "Payment disputed, please contact support"
    return "支付状态已更新"


def _require_visible_order(order: Optional[Order], user_id: str, db: Optional[Session]) -> Order:
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.user_id != user_id and not _can_view_all_orders(user_id, db):
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    return order


def _can_view_all_orders(user_id: str, db: Optional[Session]) -> bool:
    return is_admin_user(user_id, db) or has_permission(
        user_id,
        "orders",
        db,
        allow_non_operator=False,
    ) or has_permission(
        user_id,
        "order_manage",
        db,
        allow_non_operator=False,
    ) or has_permission(
        user_id,
        "payment_reconcile",
        db,
        allow_non_operator=False,
    ) or has_permission(
        user_id,
        "payment_exception_mark",
        db,
        allow_non_operator=False,
    )


def _require_order_access_if_operator(user_id: str, db: Optional[Session]) -> None:
    user = get_user_record(user_id, db)
    if not user or user.get("user_type") != "operator":
        return
    if not _can_view_all_orders(user_id, db):
        raise HTTPException(status_code=403, detail="No permission to access orders")


def _new_order_id(prefix: str) -> str:
    return f"{prefix}{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000, 9999)}"


def _build_notification_payload(payload: dict) -> dict:
    notification_type = (payload.get("type") or "").strip()
    order_id = payload.get("order_id")
    title = payload.get("title")
    body = payload.get("body") or payload.get("message") or ""
    title_key = payload.get("title_key")
    title_args = payload.get("title_args")
    body_key = payload.get("body_key")
    body_args = payload.get("body_args")

    if notification_type == "order_created":
        title = title or "订单已创建"
        body = body or f"订单 {order_id} 已创建"
        title_key = title_key or "notification_order_created_title"
        body_key = body_key or "notification_order_created_body"
        if order_id and body_args is None:
            body_args = {"order_id": order_id}
    elif notification_type == "order_shipped":
        carrier = payload.get("carrier")
        tracking = payload.get("tracking_number")
        title = title or "订单已发货"
        body = body or (
            f"您的订单已发货，{carrier} 运单号：{tracking}"
            if carrier and tracking
            else "您的订单已发货，请注意查收。"
        )
        title_key = title_key or "notification_order_shipped_title"
        if carrier and tracking:
            body_key = body_key or "notification_order_shipped_body_with_tracking"
            if body_args is None:
                body_args = {"carrier": carrier, "tracking": tracking}
        else:
            body_key = body_key or "notification_order_shipped_body"
    elif notification_type == "payment_success":
        title = title or "支付已确认"
        body = body or (
            f"订单 {order_id} 已确认到账"
            if order_id
            else "您的支付已确认到账"
        )
        title_key = title_key or "notification_payment_success_title"
        body_key = body_key or "notification_payment_success_body"
        if order_id and body_args is None:
            body_args = {"order_id": order_id}

    return {
        **payload,
        "title": title or body,
        "body": body,
        "message": payload.get("message") or body,
        "title_key": title_key,
        "title_args": title_args,
        "body_key": body_key,
        "body_args": body_args,
    }


def _ws_notify(user_id: str, payload: dict) -> None:
    try:
        import asyncio
        from routers.ws import manager, persist_notification

        enriched_payload = _build_notification_payload(payload)
        asyncio.ensure_future(manager.send_to_user(user_id, enriched_payload))
        persist_notification(
            user_id=user_id,
            title=enriched_payload.get("title", enriched_payload.get("message", "订单通知")),
            body=enriched_payload.get("body", enriched_payload.get("message", "")),
            ntype=enriched_payload.get("type", "order"),
            ref_id=enriched_payload.get("order_id"),
        )
    except Exception:
        logger.exception("Failed to send websocket notification")


def _require_owner(order: Optional[Order], user_id: str) -> Order:
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    return order


def _load_product_from_db(db: Session, product_id: str) -> Product:
    row = db.execute(text("SELECT * FROM products WHERE id = :id AND is_active = true"), {"id": product_id}).fetchone()
    if not row:
        raise HTTPException(status_code=400, detail=f"Product {product_id} not found")
    from routers.products import _row_to_product
    return _row_to_product(row._mapping)


def _address_snapshot_from_db(db: Session, address_id: str, user_id: str) -> dict:
    row = db.execute(text("SELECT * FROM addresses WHERE id = :id"), {"id": address_id}).fetchone()
    if not row:
        raise HTTPException(status_code=400, detail="Address not found")
    mapping = row._mapping
    if mapping["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Address does not belong to current user")
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
    _require_order_access_if_operator(user_id, db)
    global_view = _can_view_all_orders(user_id, db)
    if db is not None:
        try:
            conditions = []
            params: dict[str, object] = {"lim": page_size, "off": (page - 1) * page_size}
            if not global_view:
                conditions.append("user_id = :uid")
                params["uid"] = user_id
            if status:
                conditions.append("status = :status")
                params["status"] = _status_to_db(status)
            where_clause = f"WHERE {' AND '.join(conditions)}" if conditions else ""
            rows = db.execute(text(f"SELECT * FROM orders {where_clause} ORDER BY created_at DESC LIMIT :lim OFFSET :off"), params).fetchall()
            results = []
            for row in rows:
                mapping = row._mapping
                account = _fetch_payment_account_by_id(db, mapping.get("payment_account_id"))
                results.append(
                    _row_to_order(
                        mapping,
                        _fetch_order_items(db, mapping["id"]),
                        account,
                        _payment(db, mapping["id"]),
                    )
                )
            return results
        except Exception as exc:
            handle_database_error(db, "读取订单列表", exc)
    require_database(db, "读取订单列表")
    orders = [
        order
        for order in ORDERS_DB.values()
        if (global_view or order.user_id == user_id) and (not status or order.status == status)
    ]
    orders.sort(key=lambda item: item.created_at, reverse=True)
    start = (page - 1) * page_size
    window = orders[start:start + page_size]
    results: list[Order] = []
    for order in window:
        payment_account = _fetch_payment_account_by_id_from_memory(order.payment_account_id)
        results.append(
            Order(
                **{
                    **order.model_dump(),
                    "payment_account": payment_account,
                    **_payment_order_fields(_memory_payment(order)),
                }
            )
        )
    return results


@router.get("/stats")
async def get_order_stats(authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    _require_order_access_if_operator(user_id, db)
    global_view = _can_view_all_orders(user_id, db)
    if db is not None:
        try:
            if global_view:
                row = db.execute(text("SELECT count(*) AS total, coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered')), 0) AS revenue, count(*) FILTER (WHERE status = 'pending') AS pending, count(*) FILTER (WHERE status = 'paid') AS paid, count(*) FILTER (WHERE status = 'shipped') AS shipped, count(*) FILTER (WHERE status = 'delivered') AS completed, count(*) FILTER (WHERE status = 'cancelled') AS cancelled, count(*) FILTER (WHERE status = 'refunding') AS refunding FROM orders")).fetchone()
            else:
                row = db.execute(text("SELECT count(*) AS total, coalesce(sum(total_amount) FILTER (WHERE status IN ('paid','shipped','delivered')), 0) AS revenue, count(*) FILTER (WHERE status = 'pending') AS pending, count(*) FILTER (WHERE status = 'paid') AS paid, count(*) FILTER (WHERE status = 'shipped') AS shipped, count(*) FILTER (WHERE status = 'delivered') AS completed, count(*) FILTER (WHERE status = 'cancelled') AS cancelled, count(*) FILTER (WHERE status = 'refunding') AS refunding FROM orders WHERE user_id = :uid"), {"uid": user_id}).fetchone()
            mapping = row._mapping
            return {"total": mapping["total"], "total_amount": round(float(mapping["revenue"]), 2), "pending": mapping["pending"], "paid": mapping["paid"], "shipped": mapping["shipped"], "completed": mapping["completed"], "cancelled": mapping["cancelled"], "refunding": mapping["refunding"]}
        except Exception as exc:
            handle_database_error(db, "读取订单统计", exc)
    require_database(db, "读取订单统计")
    mine = [order for order in ORDERS_DB.values() if global_view or order.user_id == user_id]
    stats: dict[str, int] = {}
    for order in mine:
        stats[order.status] = stats.get(order.status, 0) + 1
    total_amount = sum(order.total_amount for order in mine if order.status in ("paid", "shipped", "completed"))
    return {"total": len(mine), "total_amount": round(total_amount, 2), "pending": stats.get("pending", 0), "paid": stats.get("paid", 0), "shipped": stats.get("shipped", 0), "completed": stats.get("completed", 0), "cancelled": stats.get("cancelled", 0), "refunding": stats.get("refunding", 0)}


@router.get("/{order_id}", response_model=Order)
async def get_order_detail(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    _require_order_access_if_operator(user_id, db)
    if db is not None:
        try:
            return _require_visible_order(_fetch_order(db, order_id), user_id, db)
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取订单详情", exc)
    require_database(db, "读取订单详情")
    order = _require_visible_order(ORDERS_DB.get(order_id), user_id, db)
    payment_account = _fetch_payment_account_by_id_from_memory(order.payment_account_id)
    return Order(
        **{
            **order.model_dump(),
            "payment_account": payment_account,
            **_payment_order_fields(_memory_payment(order)),
        }
    )


@router.post("", response_model=Order)
async def create_order(order: OrderCreate, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    order_id = _new_order_id("ORD")
    payment_account = _find_platform_payment_account(db, order.payment_method)
    payment_account_id = payment_account["id"] if payment_account else None
    if db is not None:
        try:
            address = _address_snapshot_from_db(db, order.address_id, user_id)
            items, total = [], 0.0
            for raw in order.items:
                product = _load_product_from_db(db, raw.product_id)
                qty = raw.quantity
                if product.stock < qty:
                    raise HTTPException(status_code=400, detail=f"商品 {product.name} 库存不足 (剩余 {product.stock})")
                total += product.price * qty
                items.append({"product_id": raw.product_id, "product_name": product.name, "price": product.price, "quantity": qty, "image": product.images[0] if product.images else None})
            db.execute(text("INSERT INTO orders (id, user_id, address_id, address_snap, total_amount, status, payment_method, payment_account_id, remark) VALUES (:id, :uid, :aid, CAST(:snap AS JSONB), :total, 'pending', :method, :payment_account_id, :remark)"), {"id": order_id, "uid": user_id, "aid": order.address_id, "snap": json.dumps(address), "total": total, "method": order.payment_method, "payment_account_id": payment_account_id, "remark": order.remark})
            for item in items:
                db.execute(text("INSERT INTO order_items (order_id, product_id, product_snap, quantity, unit_price, subtotal) VALUES (:oid, :pid, CAST(:snap AS JSONB), :qty, :price, :subtotal)"), {"oid": order_id, "pid": item["product_id"], "snap": json.dumps({"name": item["product_name"], "images": [item["image"]] if item["image"] else []}), "qty": item["quantity"], "price": item["price"], "subtotal": item["price"] * item["quantity"]})
                updated = db.execute(
                    text(
                        "UPDATE products SET stock = stock - :qty, "
                        "sales_count = sales_count + :qty "
                        "WHERE id = :pid AND stock >= :qty"
                    ),
                    {"qty": item["quantity"], "pid": item["product_id"]},
                )
                if updated.rowcount != 1:
                    raise HTTPException(status_code=409, detail=f"Product {item['product_name']} stock changed, please retry")
                db.execute(text("DELETE FROM cart_items WHERE user_id = :uid AND product_id = :pid"), {"uid": user_id, "pid": item["product_id"]})
            db.commit()
            created = _fetch_order(db, order_id) or Order(id=order_id, user_id=user_id, items=items, total_amount=total, status="pending", address=address, created_at=datetime.now().isoformat(), payment_method=order.payment_method, payment_account_id=payment_account_id, payment_account=payment_account)
            _ws_notify(user_id, {"type": "order_created", "order_id": order_id, "message": f"Order {order_id} created"})
            return created
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "创建订单", exc)
    require_database(db, "创建订单")
    if order.address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=400, detail="Address not found")
    address_model = ADDRESSES_DB[order.address_id]
    if address_model.user_id != user_id:
        raise HTTPException(status_code=403, detail="Address does not belong to current user")
    address = address_model.model_dump()
    items, total = [], 0.0
    for raw in order.items:
        product = PRODUCTS_DB.get(raw.product_id)
        if product is None:
            raise HTTPException(status_code=400, detail=f"Product {raw.product_id} not found")
        qty = raw.quantity
        if product.stock < qty:
            raise HTTPException(status_code=400, detail=f"商品 {product.name} 库存不足 (剩余 {product.stock})")
        total += product.price * qty
        items.append({"product_id": raw.product_id, "product_name": product.name, "price": product.price, "quantity": qty, "image": product.images[0] if product.images else None})
    for item in items:
        product = PRODUCTS_DB[item["product_id"]]
        PRODUCTS_DB[item["product_id"]] = Product(**{**product.model_dump(), "stock": product.stock - item["quantity"], "sales_count": product.sales_count + item["quantity"]})
    created = Order(id=order_id, user_id=user_id, items=items, total_amount=total, status="pending", address=address, created_at=datetime.now().isoformat(), payment_method=order.payment_method, payment_account_id=payment_account_id, payment_account=payment_account)
    ORDERS_DB[order_id] = created
    if user_id in CARTS_DB:
        ordered = {item.product_id for item in order.items}
        CARTS_DB[user_id] = [cart_item for cart_item in CARTS_DB[user_id] if cart_item.product_id not in ordered]
    _ws_notify(user_id, {"type": "order_created", "order_id": order_id, "message": f"Order {order_id} created"})
    return created


@router.post("/checkout")
async def checkout(data: dict, authorization: AuthorizationDep = None):
    require_user(authorization)
    return {
        "success": True,
        "order_id": data.get("order_id"),
        # payment_url is None until a real payment gateway is integrated.
        # A hardcoded placeholder URL was a redirection risk; removed.
        "payment_url": None,
        "message": "Please complete payment via the manual voucher flow",
    }


@router.post("/{order_id}/pay")
async def pay_order(
    order_id: str,
    data: dict | None = None,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    data = data or {}
    requested_method = data.get("method")
    voucher_url = data.get("voucher_url")
    remark = data.get("remark")
    payment_account = _find_platform_payment_account(db, requested_method)
    if not payment_account:
        raise HTTPException(status_code=400, detail="当前支付方式暂无可用收款账户，请联系管理员配置后再试")
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status != "pending":
                raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot be paid")
            method = requested_method or order.payment_method or "wechat"

            # 使用支付服务创建记录
            from services.payment_service import (
                create_payment_record,
                upload_voucher,
            )
            record = create_payment_record(
                order_id=order_id,
                user_id=user_id,
                amount=order.total_amount,
                payment_account_id=payment_account["id"],
                payment_method=method,
                remark=remark,
                db=db,
            )
            payment_id = record["payment_id"]

            # 如果有凭证，直接上传并改为 awaiting_confirmation
            if voucher_url:
                record = upload_voucher(payment_id, user_id, voucher_url, db=db) or record

            # 同步更新订单关联
            db.execute(
                text(
                    "UPDATE orders SET payment_id = :pid, payment_method = :method, "
                    "payment_account_id = :paid WHERE id = :oid"
                ),
                {
                    "pid": payment_id,
                    "method": method,
                    "paid": payment_account["id"],
                    "oid": order_id,
                },
            )
            db.commit()

            return {
                "success": True,
                "payment_id": payment_id,
                "amount": order.total_amount,
                "method": method,
                "status": record["status"],
                "payment_account_id": payment_account["id"],
                "payment_account": payment_account,
                "message": "Please transfer using the payment account details and wait for confirmation.",
            }
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "create payment", exc)
    require_database(db, "create payment")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot be paid")
    method = requested_method or order.payment_method or "wechat"

    from services.payment_service import create_payment_record, upload_voucher
    record = create_payment_record(
        order_id=order_id,
        user_id=user_id,
        amount=order.total_amount,
        payment_account_id=payment_account["id"],
        payment_method=method,
        remark=remark,
    )
    payment_id = record["payment_id"]

    if voucher_url:
        record = upload_voucher(payment_id, user_id, voucher_url) or record

    PAYMENTS_DB[payment_id] = {
        "id": payment_id,
        "order_id": order_id,
        "amount": order.total_amount,
        "method": method,
        "status": record["status"],
        "created_at": record["created_at"],
    }
    ORDERS_DB[order_id] = Order(
        **{
            **order.model_dump(),
            "payment_id": payment_id,
            "payment_method": method,
            "payment_account_id": payment_account["id"],
            "payment_account": payment_account,
        }
    )
    return {
        "success": True,
        "payment_id": payment_id,
        "amount": order.total_amount,
        "method": method,
        "status": record["status"],
        "payment_account_id": payment_account["id"],
        "payment_account": payment_account,
        "message": "Please transfer using the payment account details and wait for confirmation.",
    }


@router.get("/{order_id}/pay-status")
async def get_pay_status(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            pay = _payment(db, order_id)
            if not pay or not order.payment_id:
                return {"status": "no_payment", "message": "Payment record not found"}
            return {"payment_id": order.payment_id, "status": pay["status"], "amount": pay["amount"], "method": pay["method"], "paid_at": pay.get("paid_at"), "payment_account_id": order.payment_account_id, "payment_account": order.payment_account, "message": _payment_status_message(pay["status"])}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "read payment status", exc)
    require_database(db, "read payment status")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    pid = order.payment_id
    if not pid or pid not in PAYMENTS_DB:
        return {"status": "no_payment", "message": "Payment record not found"}
    pay = PAYMENTS_DB[pid]
    payment_account = _fetch_payment_account_by_id_from_memory(order.payment_account_id)
    return {"payment_id": pid, "status": pay["status"], "amount": pay["amount"], "method": pay["method"], "paid_at": pay.get("paid_at"), "payment_account_id": order.payment_account_id, "payment_account": payment_account, "message": _payment_status_message(pay["status"])}


@router.post("/{order_id}/cancel")
async def cancel_order(order_id: str, data: dict | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    reason = (data or {}).get("reason", "鐢ㄦ埛涓诲姩鍙栨秷")
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status not in ("pending", "paid"):
                raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot be cancelled")
            entries = [{"time": datetime.now().isoformat(), "status": "Order cancelled", "description": reason}] + order.logistics_entries
            for item in order.items:
                db.execute(text("UPDATE products SET stock = stock + :qty, sales_count = GREATEST(sales_count - :qty, 0) WHERE id = :pid"), {"qty": item.get("quantity", 1), "pid": item.get("product_id")})
            db.execute(text("UPDATE orders SET status = 'cancelled', cancelled_at = NOW(), cancel_reason = :reason, logistics_entries = :entries::jsonb WHERE id = :oid"), {"reason": reason, "entries": json.dumps(entries), "oid": order_id})
            db.commit()
            return {"success": True, "message": "Order cancelled and stock restored"}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "取消订单", exc)
    require_database(db, "取消订单")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status not in ("pending", "paid"):
        raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot be cancelled")
    for item in order.items:
        pid = item.get("product_id")
        if pid and pid in PRODUCTS_DB:
            product = PRODUCTS_DB[pid]
            PRODUCTS_DB[pid] = Product(**{**product.model_dump(), "stock": product.stock + item.get("quantity", 1), "sales_count": max(0, product.sales_count - item.get("quantity", 1))})
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "cancelled", "cancelled_at": datetime.now().isoformat(), "cancel_reason": reason, "logistics_entries": [{"time": datetime.now().isoformat(), "status": "Order cancelled", "description": reason}] + order.logistics_entries})
    return {"success": True, "message": "Order cancelled and stock restored"}


@router.post("/{order_id}/confirm-receipt")
async def confirm_receipt(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status != "shipped":
                raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot confirm receipt")
            entries = [{"time": datetime.now().isoformat(), "status": "Delivered", "description": "Customer confirmed receipt, order completed"}] + order.logistics_entries
            db.execute(text("UPDATE orders SET status = 'delivered', delivered_at = NOW(), completed_at = NOW(), logistics_entries = :entries::jsonb WHERE id = :oid"), {"entries": json.dumps(entries), "oid": order_id})
            db.commit()
            return {"success": True, "message": "Receipt confirmed"}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "纭鏀惰揣", exc)
    require_database(db, "纭鏀惰揣")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status != "shipped":
        raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot confirm receipt")
    now = datetime.now().isoformat()
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "completed", "delivered_at": now, "completed_at": now, "logistics_entries": [{"time": now, "status": "Delivered", "description": "Customer confirmed receipt, order completed"}] + order.logistics_entries})
    return {"success": True, "message": "Receipt confirmed"}


@router.post("/{order_id}/refund")
async def request_refund(order_id: str, data: dict | None = None, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    reason = (data or {}).get("reason", "Customer requested refund")
    if db is not None:
        try:
            order = _require_owner(_fetch_order(db, order_id), user_id)
            if order.status not in ("paid", "shipped", "completed"):
                raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot be refunded")
            entries = [{"time": datetime.now().isoformat(), "status": "Refund requested", "description": f"Customer requested refund: {reason}"}] + order.logistics_entries
            db.execute(text("UPDATE orders SET status = 'refunding', refund_reason = :reason, refund_amount = :amount, logistics_entries = :entries::jsonb WHERE id = :oid"), {"reason": reason, "amount": order.total_amount, "entries": json.dumps(entries), "oid": order_id})
            db.commit()
            return {"success": True, "message": "閫€娆剧敵璇峰凡鎻愪氦", "refund_amount": order.total_amount}
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "request refund", exc)
    require_database(db, "request refund")
    order = _require_owner(ORDERS_DB.get(order_id), user_id)
    if order.status not in ("paid", "shipped", "completed"):
        raise HTTPException(status_code=400, detail=f"Order status {order.status} cannot be refunded")
    ORDERS_DB[order_id] = Order(**{**order.model_dump(), "status": "refunding", "refund_reason": reason, "refund_amount": order.total_amount, "logistics_entries": [{"time": datetime.now().isoformat(), "status": "Refund requested", "description": f"Customer requested refund: {reason}"}] + order.logistics_entries})
    return {"success": True, "message": "閫€娆剧敵璇峰凡鎻愪氦", "refund_amount": order.total_amount}


@router.get("/{order_id}/logistics")
async def get_order_logistics(order_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    _require_order_access_if_operator(user_id, db)
    if db is not None:
        try:
            order = _require_visible_order(_fetch_order(db, order_id), user_id, db)
            return {
                "order_id": order_id,
                "carrier": order.logistics_company,
                "tracking_number": order.tracking_number,
                "status": order.status,
                "entries": order.logistics_entries,
            }
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取物流信息", exc)
    require_database(db, "读取物流信息")
    order = _require_visible_order(ORDERS_DB.get(order_id), user_id, db)
    return {
        "order_id": order_id,
        "carrier": order.logistics_company,
        "tracking_number": order.tracking_number,
        "status": order.status,
        "entries": order.logistics_entries,
    }
