"""
Favorites router - add / remove / list
DB-first with in-memory fallback
Uses 'favorites' table (user_id, product_id) with PK constraint
"""

import json
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from security import require_user
from database import get_db
from store import FAVORITES_DB, PRODUCTS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/favorites", tags=["Favorites"])


@router.get("")
async def get_favorites(authorization: str = None, db: Optional[Session] = Depends(get_db)):
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
            for r in rows:
                m = r._mapping
                imgs = m["images"]
                if isinstance(imgs, str):
                    imgs = json.loads(imgs)
                items.append({
                    "id": m["id"], "name": m["name"],
                    "description": m["description"] or "",
                    "price": float(m["price"]),
                    "original_price": float(m["original_price"]) if m.get("original_price") else None,
                    "category": m["category"] or "", "material": m["material"] or "",
                    "images": imgs if isinstance(imgs, list) else [],
                    "stock": m["stock"], "rating": float(m["rating"]),
                    "sales_count": m["sales_count"],
                    "is_hot": m["is_hot"], "is_new": m["is_new"],
                    "is_welfare": m.get("is_welfare", False),
                    "origin": m.get("origin"), "certificate": m.get("certificate"),
                    "blockchain_hash": m.get("blockchain_hash"),
                    "material_verify": m.get("material_verify", "天然A货"),
                })
            return {"items": items, "total": len(items)}
        except Exception as e:
            logger.error(f"DB get_favorites: {e}")

    # memory
    fav_ids = FAVORITES_DB.get(user_id, [])
    products = [PRODUCTS_DB[pid] for pid in fav_ids if pid in PRODUCTS_DB]
    return {"items": [p.model_dump() for p in products], "total": len(products)}


@router.post("/{product_id}")
async def add_favorite(product_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if product_id not in PRODUCTS_DB:
        if db is not None:
            row = db.execute(
                text("SELECT id FROM products WHERE id = :id AND is_active = true"),
                {"id": product_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="商品不存在")
        else:
            raise HTTPException(status_code=404, detail="商品不存在")

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO favorites (user_id, product_id) "
                    "VALUES (:uid, :pid) ON CONFLICT DO NOTHING"
                ),
                {"uid": user_id, "pid": product_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB add_favorite: {e}")

    if user_id not in FAVORITES_DB:
        FAVORITES_DB[user_id] = []
    if product_id not in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].append(product_id)

    return {"success": True, "message": "已添加收藏"}


@router.delete("/{product_id}")
async def remove_favorite(product_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM favorites WHERE user_id = :uid AND product_id = :pid"),
                {"uid": user_id, "pid": product_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB remove_favorite: {e}")

    if user_id in FAVORITES_DB and product_id in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].remove(product_id)

    return {"success": True, "message": "已取消收藏"}
