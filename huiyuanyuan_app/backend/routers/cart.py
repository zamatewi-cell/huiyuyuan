"""
Cart router - CRUD
DB-first with in-memory fallback
"""

import json
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.cart import CartItem
from security import require_user
from database import get_db
from store import CARTS_DB, PRODUCTS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/cart", tags=["Cart"])


@router.get("")
async def get_cart(authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT ci.product_id, ci.quantity, ci.selected, "
                    "  p.id as pid, p.name, p.description, p.price, p.original_price, "
                    "  p.category, p.material, p.images, p.stock, p.rating, "
                    "  p.sales_count, p.is_hot, p.is_new, p.is_welfare, "
                    "  p.origin, p.certificate, p.blockchain_hash, p.material_verify "
                    "FROM cart_items ci "
                    "JOIN products p ON ci.product_id = p.id "
                    "WHERE ci.user_id = :uid AND p.is_active = true "
                    "ORDER BY ci.added_at DESC"
                ),
                {"uid": user_id},
            ).fetchall()

            items = []
            for r in rows:
                m = r._mapping
                imgs = m["images"]
                if isinstance(imgs, str):
                    imgs = json.loads(imgs)
                items.append({
                    "product_id": m["product_id"],
                    "quantity": m["quantity"],
                    "selected": m["selected"],
                    "product": {
                        "id": m["pid"], "name": m["name"],
                        "description": m["description"] or "",
                        "price": float(m["price"]),
                        "original_price": float(m["original_price"]) if m["original_price"] else None,
                        "category": m["category"] or "",
                        "material": m["material"] or "",
                        "images": imgs if isinstance(imgs, list) else [],
                        "stock": m["stock"], "rating": float(m["rating"]),
                        "sales_count": m["sales_count"],
                        "is_hot": m["is_hot"], "is_new": m["is_new"],
                        "is_welfare": m.get("is_welfare", False),
                        "origin": m.get("origin"), "certificate": m.get("certificate"),
                        "blockchain_hash": m.get("blockchain_hash"),
                        "material_verify": m.get("material_verify", "天然A货"),
                    },
                })
            return {"items": items, "total": len(items)}
        except Exception as e:
            logger.error(f"DB get_cart: {e}")

    # ---- memory fallback ----
    cart = CARTS_DB.get(user_id, [])
    items = []
    for item in cart:
        if item.product_id in PRODUCTS_DB:
            product = PRODUCTS_DB[item.product_id]
            items.append({
                "product_id": item.product_id,
                "quantity": item.quantity,
                "selected": item.selected,
                "product": product.model_dump(),
            })
    return {"items": items, "total": len(items)}


@router.post("")
async def add_to_cart(item: CartItem, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if item.product_id not in PRODUCTS_DB:
        # Also check DB
        if db is not None:
            row = db.execute(
                text("SELECT id FROM products WHERE id = :id AND is_active = true"),
                {"id": item.product_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="商品不存在")
        else:
            raise HTTPException(status_code=404, detail="商品不存在")

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO cart_items (user_id, product_id, quantity, selected) "
                    "VALUES (:uid, :pid, :qty, :sel) "
                    "ON CONFLICT (user_id, product_id) "
                    "DO UPDATE SET quantity = cart_items.quantity + :qty"
                ),
                {"uid": user_id, "pid": item.product_id, "qty": item.quantity, "sel": item.selected},
            )
            db.commit()
            return {"success": True, "message": "已添加到购物车"}
        except Exception as e:
            db.rollback()
            logger.error(f"DB add_to_cart: {e}")

    # ---- memory fallback ----
    if user_id not in CARTS_DB:
        CARTS_DB[user_id] = []
    for existing in CARTS_DB[user_id]:
        if existing.product_id == item.product_id:
            existing.quantity += item.quantity
            return {"success": True, "message": "已更新数量"}
    CARTS_DB[user_id].append(item)
    return {"success": True, "message": "已添加到购物车"}


@router.put("/{product_id}")
async def update_cart_item(
    product_id: str, quantity: int,
    authorization: str = None, db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            if quantity <= 0:
                db.execute(
                    text("DELETE FROM cart_items WHERE user_id = :uid AND product_id = :pid"),
                    {"uid": user_id, "pid": product_id},
                )
            else:
                result = db.execute(
                    text(
                        "UPDATE cart_items SET quantity = :qty "
                        "WHERE user_id = :uid AND product_id = :pid"
                    ),
                    {"uid": user_id, "pid": product_id, "qty": quantity},
                )
                if result.rowcount == 0:
                    raise HTTPException(status_code=404, detail="商品不在购物车中")
            db.commit()
            return {"success": True}
        except HTTPException:
            raise
        except Exception as e:
            db.rollback()
            logger.error(f"DB update_cart_item: {e}")

    # ---- memory fallback ----
    if user_id not in CARTS_DB:
        raise HTTPException(status_code=404, detail="购物车为空")
    for ci in CARTS_DB[user_id]:
        if ci.product_id == product_id:
            if quantity <= 0:
                CARTS_DB[user_id].remove(ci)
            else:
                ci.quantity = quantity
            return {"success": True}
    raise HTTPException(status_code=404, detail="商品不在购物车中")


@router.delete("/{product_id}")
async def remove_from_cart(
    product_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM cart_items WHERE user_id = :uid AND product_id = :pid"),
                {"uid": user_id, "pid": product_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB remove_from_cart: {e}")

    if user_id in CARTS_DB:
        CARTS_DB[user_id] = [i for i in CARTS_DB[user_id] if i.product_id != product_id]
    return {"success": True, "message": "已从购物车移除"}


@router.delete("")
async def clear_cart(authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM cart_items WHERE user_id = :uid"),
                {"uid": user_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB clear_cart: {e}")

    CARTS_DB[user_id] = []
    return {"success": True, "message": "购物车已清空"}
