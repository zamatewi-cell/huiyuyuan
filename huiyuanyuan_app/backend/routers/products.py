"""
Products router - CRUD + filter + search + pagination
DB-first with in-memory fallback
"""

import json
import uuid
import logging
from typing import Optional, List

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.product import Product, ProductCreate
from security import require_user
from database import get_db
from store import PRODUCTS_DB, USERS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/products", tags=["Products"])


def _row_to_product(m) -> Product:
    imgs = m["images"]
    if isinstance(imgs, str):
        imgs = json.loads(imgs)
    return Product(
        id=m["id"],
        name=m["name"],
        description=m["description"] or "",
        price=float(m["price"]),
        original_price=float(m["original_price"]) if m.get("original_price") else None,
        category=m["category"] or "",
        material=m["material"] or "",
        images=imgs if isinstance(imgs, list) else [],
        stock=m["stock"],
        rating=float(m["rating"]),
        sales_count=m["sales_count"],
        is_hot=m["is_hot"],
        is_new=m["is_new"],
        is_welfare=m.get("is_welfare", False),
        origin=m.get("origin"),
        certificate=m.get("certificate"),
        blockchain_hash=m.get("blockchain_hash"),
        material_verify=m.get("material_verify", "天然A货"),
    )


# ====== LIST ======

@router.get("", response_model=List[Product])
async def get_products(
    category: Optional[str] = None,
    material: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    is_hot: Optional[bool] = None,
    is_new: Optional[bool] = None,
    is_welfare: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    db: Optional[Session] = Depends(get_db),
):
    if db is not None:
        try:
            conds = ["is_active = true"]
            params: dict = {}

            if category and category != "全部":
                conds.append("category = :category")
                params["category"] = category
            if material:
                conds.append("material = :material")
                params["material"] = material
            if min_price is not None:
                conds.append("price >= :min_price")
                params["min_price"] = min_price
            if max_price is not None:
                conds.append("price <= :max_price")
                params["max_price"] = max_price
            if is_hot is not None:
                conds.append("is_hot = :is_hot")
                params["is_hot"] = is_hot
            if is_new is not None:
                conds.append("is_new = :is_new")
                params["is_new"] = is_new
            if is_welfare is not None:
                conds.append("is_welfare = :is_welfare")
                params["is_welfare"] = is_welfare
            if search:
                conds.append("(name ILIKE :q OR description ILIKE :q)")
                params["q"] = f"%{search}%"

            order_map = {
                "price_asc": "price ASC",
                "price_desc": "price DESC",
                "sales": "sales_count DESC",
                "rating": "rating DESC",
            }
            order = order_map.get(sort_by, "created_at DESC")

            offset = (page - 1) * page_size
            params["lim"] = page_size
            params["off"] = offset

            sql = (
                f"SELECT * FROM products WHERE {' AND '.join(conds)} "
                f"ORDER BY {order} LIMIT :lim OFFSET :off"
            )
            rows = db.execute(text(sql), params).fetchall()
            return [_row_to_product(r._mapping) for r in rows]
        except Exception as e:
            logger.error(f"DB get_products: {e}")

    # ---- memory fallback ----
    products = list(PRODUCTS_DB.values())
    if category and category != "全部":
        products = [p for p in products if p.category == category]
    if material:
        products = [p for p in products if p.material == material]
    if min_price is not None:
        products = [p for p in products if p.price >= min_price]
    if max_price is not None:
        products = [p for p in products if p.price <= max_price]
    if is_hot is not None:
        products = [p for p in products if p.is_hot == is_hot]
    if is_new is not None:
        products = [p for p in products if p.is_new == is_new]
    if is_welfare is not None:
        products = [p for p in products if p.is_welfare == is_welfare]
    if search:
        q = search.lower()
        products = [p for p in products if q in p.name.lower() or q in p.description.lower()]

    if sort_by == "price_asc":
        products.sort(key=lambda x: x.price)
    elif sort_by == "price_desc":
        products.sort(key=lambda x: x.price, reverse=True)
    elif sort_by == "sales":
        products.sort(key=lambda x: x.sales_count, reverse=True)
    elif sort_by == "rating":
        products.sort(key=lambda x: x.rating, reverse=True)

    start = (page - 1) * page_size
    return products[start : start + page_size]


# ====== DETAIL ======

@router.get("/{product_id}", response_model=Product)
async def get_product_detail(product_id: str, db: Optional[Session] = Depends(get_db)):
    if db is not None:
        try:
            row = db.execute(
                text("SELECT * FROM products WHERE id = :id AND is_active = true"),
                {"id": product_id},
            ).fetchone()
            if row:
                return _row_to_product(row._mapping)
        except Exception as e:
            logger.error(f"DB get_product_detail: {e}")

    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    return PRODUCTS_DB[product_id]


# ====== CREATE ======

@router.post("", response_model=Product)
async def create_product(
    product: ProductCreate,
    authorization: str = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="没有权限")

    product_id = f"HYY-{uuid.uuid4().hex[:6].upper()}"
    bhash = f"0x{uuid.uuid4().hex[:40]}"
    cert = f"GTC-2026-{product_id[-6:]}"

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO products "
                    "(id, name, description, price, original_price, category, material, "
                    " images, stock, is_hot, is_new, is_welfare, origin, certificate, blockchain_hash) "
                    "VALUES (:id,:name,:desc,:price,:orig,:cat,:mat,"
                    " :imgs::jsonb,:stock,:hot,:new,:welf,:origin,:cert,:bhash)"
                ),
                {
                    "id": product_id, "name": product.name, "desc": product.description,
                    "price": product.price, "orig": product.original_price,
                    "cat": product.category, "mat": product.material,
                    "imgs": json.dumps(product.images), "stock": product.stock,
                    "hot": product.is_hot, "new": product.is_new,
                    "welf": product.is_welfare, "origin": product.origin,
                    "cert": cert, "bhash": bhash,
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB create_product: {e}")

    new_product = Product(id=product_id, blockchain_hash=bhash, certificate=cert, **product.model_dump())
    PRODUCTS_DB[product_id] = new_product
    return new_product


# ====== UPDATE ======

@router.put("/{product_id}", response_model=Product)
async def update_product(
    product_id: str,
    product: ProductCreate,
    authorization: str = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="没有权限")

    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")

    if db is not None:
        try:
            db.execute(
                text(
                    "UPDATE products SET "
                    "name=:name, description=:desc, price=:price, original_price=:orig, "
                    "category=:cat, material=:mat, images=:imgs::jsonb, stock=:stock, "
                    "is_hot=:hot, is_new=:new, is_welfare=:welf, origin=:origin "
                    "WHERE id = :id"
                ),
                {
                    "id": product_id, "name": product.name, "desc": product.description,
                    "price": product.price, "orig": product.original_price,
                    "cat": product.category, "mat": product.material,
                    "imgs": json.dumps(product.images), "stock": product.stock,
                    "hot": product.is_hot, "new": product.is_new,
                    "welf": product.is_welfare, "origin": product.origin,
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB update_product: {e}")

    existing = PRODUCTS_DB[product_id]
    updated = Product(
        id=product_id,
        blockchain_hash=existing.blockchain_hash,
        certificate=existing.certificate,
        rating=existing.rating,
        sales_count=existing.sales_count,
        **product.model_dump(),
    )
    PRODUCTS_DB[product_id] = updated
    return updated


# ====== DELETE ======

@router.delete("/{product_id}")
async def delete_product(
    product_id: str,
    authorization: str = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="没有权限")

    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")

    if db is not None:
        try:
            db.execute(
                text("UPDATE products SET is_active = false WHERE id = :id"),
                {"id": product_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB delete_product: {e}")

    PRODUCTS_DB.pop(product_id, None)
    return {"success": True, "message": "商品已删除"}
