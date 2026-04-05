"""
Favorites router - add / remove / list
DB-first with development-only in-memory fallback
"""

import json
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from security import AuthorizationDep, require_user
from store import FAVORITES_DB, PRODUCTS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/favorites", tags=["Favorites"])


@router.get("")
async def get_favorites(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT p.* FROM favorites f "
                    "JOIN products p ON f.product_id = p.id "
                    "WHERE f.user_id = :uid AND p.is_active = true "
                    "ORDER BY f.created_at DESC"
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
                        "id": mapping["id"],
                        "name": mapping["name"],
                        "description": mapping["description"] or "",
                        "price": float(mapping["price"]),
                        "original_price": (
                            float(mapping["original_price"])
                            if mapping.get("original_price")
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
                    }
                )
            return {"items": items, "total": len(items)}
        except Exception as exc:
            handle_database_error(db, "读取收藏夹", exc)

    require_database(db, "读取收藏夹")

    favorite_ids = FAVORITES_DB.get(user_id, [])
    products = [PRODUCTS_DB[product_id] for product_id in favorite_ids if product_id in PRODUCTS_DB]
    return {"items": [product.model_dump() for product in products], "total": len(products)}


@router.post("/{product_id}")
async def add_favorite(
    product_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            product = db.execute(
                text("SELECT id FROM products WHERE id = :id AND is_active = true"),
                {"id": product_id},
            ).fetchone()
            if not product:
                raise HTTPException(status_code=404, detail="商品不存在")

            db.execute(
                text(
                    "INSERT INTO favorites (user_id, product_id) "
                    "VALUES (:uid, :pid) ON CONFLICT DO NOTHING"
                ),
                {"uid": user_id, "pid": product_id},
            )
            db.commit()
            return {"success": True, "message": "已添加收藏"}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "添加收藏", exc)

    require_database(db, "添加收藏")

    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")

    favorites = FAVORITES_DB.setdefault(user_id, [])
    if product_id not in favorites:
        favorites.append(product_id)

    return {"success": True, "message": "已添加收藏"}


@router.delete("/{product_id}")
async def remove_favorite(
    product_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM favorites WHERE user_id = :uid AND product_id = :pid"),
                {"uid": user_id, "pid": product_id},
            )
            db.commit()
            return {"success": True, "message": "已取消收藏"}
        except Exception as exc:
            handle_database_error(db, "取消收藏", exc)

    require_database(db, "取消收藏")

    if user_id in FAVORITES_DB and product_id in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].remove(product_id)

    return {"success": True, "message": "已取消收藏"}
