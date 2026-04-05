"""
Cart router - CRUD
DB-first with development-only in-memory fallback
"""

import json
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.cart import CartItem
from security import AuthorizationDep, require_user
from store import CARTS_DB, PRODUCTS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/cart", tags=["Cart"])


def _ensure_memory_product_exists(product_id: str) -> None:
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")


@router.get("")
async def get_cart(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT ci.product_id, ci.quantity, ci.selected, "
                    "p.id AS pid, p.name, p.description, p.price, p.original_price, "
                    "p.category, p.material, p.images, p.stock, p.rating, "
                    "p.sales_count, p.is_hot, p.is_new, p.is_welfare, "
                    "p.origin, p.certificate, p.blockchain_hash, p.material_verify "
                    "FROM cart_items ci "
                    "JOIN products p ON ci.product_id = p.id "
                    "WHERE ci.user_id = :uid AND p.is_active = true "
                    "ORDER BY ci.added_at DESC"
                ),
                {"uid": user_id},
            ).fetchall()

            items = []
            for row in rows:
                mapping = row._mapping
                images = mapping["images"]
                if isinstance(images, str):
                    images = json.loads(images)
                items.append(
                    {
                        "product_id": mapping["product_id"],
                        "quantity": mapping["quantity"],
                        "selected": mapping["selected"],
                        "product": {
                            "id": mapping["pid"],
                            "name": mapping["name"],
                            "description": mapping["description"] or "",
                            "price": float(mapping["price"]),
                            "original_price": (
                                float(mapping["original_price"])
                                if mapping["original_price"]
                                else None
                            ),
                            "category": mapping["category"] or "",
                            "material": mapping["material"] or "",
                            "images": images if isinstance(images, list) else [],
                            "stock": mapping["stock"],
                            "rating": float(mapping["rating"]),
                            "sales_count": mapping["sales_count"],
                            "is_hot": mapping["is_hot"],
                            "is_new": mapping["is_new"],
                            "is_welfare": mapping.get("is_welfare", False),
                            "origin": mapping.get("origin"),
                            "certificate": mapping.get("certificate"),
                            "blockchain_hash": mapping.get("blockchain_hash"),
                            "material_verify": mapping.get("material_verify", "天然A货"),
                        },
                    }
                )
            return {"items": items, "total": len(items)}
        except Exception as exc:
            handle_database_error(db, "读取购物车", exc)

    require_database(db, "读取购物车")

    cart = CARTS_DB.get(user_id, [])
    items = []
    for item in cart:
        if item.product_id in PRODUCTS_DB:
            items.append(
                {
                    "product_id": item.product_id,
                    "quantity": item.quantity,
                    "selected": item.selected,
                    "product": PRODUCTS_DB[item.product_id].model_dump(),
                }
            )
    return {"items": items, "total": len(items)}


@router.post("")
async def add_to_cart(
    item: CartItem,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            product = db.execute(
                text("SELECT id FROM products WHERE id = :id AND is_active = true"),
                {"id": item.product_id},
            ).fetchone()
            if not product:
                raise HTTPException(status_code=404, detail="商品不存在")

            db.execute(
                text(
                    "INSERT INTO cart_items (user_id, product_id, quantity, selected) "
                    "VALUES (:uid, :pid, :qty, :selected) "
                    "ON CONFLICT (user_id, product_id) "
                    "DO UPDATE SET quantity = cart_items.quantity + :qty, "
                    "selected = EXCLUDED.selected"
                ),
                {
                    "uid": user_id,
                    "pid": item.product_id,
                    "qty": item.quantity,
                    "selected": item.selected,
                },
            )
            db.commit()
            return {"success": True, "message": "已添加到购物车"}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "加入购物车", exc)

    require_database(db, "加入购物车")

    _ensure_memory_product_exists(item.product_id)
    cart = CARTS_DB.setdefault(user_id, [])
    for existing in cart:
        if existing.product_id == item.product_id:
            existing.quantity += item.quantity
            existing.selected = item.selected
            return {"success": True, "message": "已更新购物车数量"}

    cart.append(item)
    return {"success": True, "message": "已添加到购物车"}


@router.put("/{product_id}")
async def update_cart_item(
    product_id: str,
    quantity: int,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            if quantity <= 0:
                result = db.execute(
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
        except Exception as exc:
            handle_database_error(db, "更新购物车", exc)

    require_database(db, "更新购物车")

    cart = CARTS_DB.get(user_id)
    if not cart:
        raise HTTPException(status_code=404, detail="购物车为空")

    for existing in cart:
        if existing.product_id == product_id:
            if quantity <= 0:
                cart.remove(existing)
            else:
                existing.quantity = quantity
            return {"success": True}

    raise HTTPException(status_code=404, detail="商品不在购物车中")


@router.delete("/{product_id}")
async def remove_from_cart(
    product_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM cart_items WHERE user_id = :uid AND product_id = :pid"),
                {"uid": user_id, "pid": product_id},
            )
            db.commit()
            return {"success": True, "message": "已从购物车移除"}
        except Exception as exc:
            handle_database_error(db, "移除购物车商品", exc)

    require_database(db, "移除购物车商品")

    if user_id in CARTS_DB:
        CARTS_DB[user_id] = [item for item in CARTS_DB[user_id] if item.product_id != product_id]
    return {"success": True, "message": "已从购物车移除"}


@router.delete("")
async def clear_cart(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM cart_items WHERE user_id = :uid"),
                {"uid": user_id},
            )
            db.commit()
            return {"success": True, "message": "购物车已清空"}
        except Exception as exc:
            handle_database_error(db, "清空购物车", exc)

    require_database(db, "清空购物车")

    CARTS_DB[user_id] = []
    return {"success": True, "message": "购物车已清空"}
