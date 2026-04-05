"""Products router - DB-first with development-only in-memory fallback."""

import json
import logging
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.product import Product, ProductCreate
from security import AuthorizationDep, is_admin_user, require_user
from services.product_media_service import sanitize_product_images
from store import PRODUCTS_DB

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/products", tags=["Products"])

# 翻译字段列表
_I18N_FIELDS = [
    "name_en", "description_en", "category_en", "material_en",
    "origin_en", "material_verify_en",
    "name_zh_tw", "description_zh_tw", "category_zh_tw", "material_zh_tw",
    "origin_zh_tw", "material_verify_zh_tw",
]


def _row_to_product(mapping) -> Product:
    images = mapping["images"]
    if isinstance(images, str):
        images = json.loads(images)
    images = sanitize_product_images(images if isinstance(images, list) else [], mapping.get("material"))

    kwargs = dict(
        id=mapping["id"],
        name=mapping["name"],
        description=mapping["description"] or "",
        price=float(mapping["price"]),
        original_price=float(mapping["original_price"]) if mapping.get("original_price") is not None else None,
        category=mapping["category"] or "",
        material=mapping["material"] or "",
        images=images,
        stock=mapping["stock"],
        rating=float(mapping["rating"]),
        sales_count=mapping["sales_count"],
        is_hot=mapping["is_hot"],
        is_new=mapping["is_new"],
        is_welfare=mapping.get("is_welfare", False),
        origin=mapping.get("origin"),
        certificate=mapping.get("certificate"),
        blockchain_hash=mapping.get("blockchain_hash"),
        material_verify=mapping.get("material_verify", "天然A货"),
    )

    # 加载翻译字段（如果存在）
    for field in _I18N_FIELDS:
        kwargs[field] = mapping.get(field)

    return Product(**kwargs)


def _db_product(db: Session, product_id: str, *, active_only: bool = True) -> Optional[Product]:
    sql = "SELECT * FROM products WHERE id = :id"
    if active_only:
        sql += " AND is_active = true"
    row = db.execute(text(sql), {"id": product_id}).fetchone()
    return None if not row else _row_to_product(row._mapping)


def _sanitize_memory_product(product: Product) -> Product:
    return product.model_copy(
        update={
            "images": sanitize_product_images(product.images, product.material),
        }
    )


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
            conditions = ["is_active = true"]
            params: dict[str, object] = {"lim": page_size, "off": (page - 1) * page_size}
            if category and category != "全部":
                conditions.append("category = :category")
                params["category"] = category
            if material:
                conditions.append("material = :material")
                params["material"] = material
            if min_price is not None:
                conditions.append("price >= :min_price")
                params["min_price"] = min_price
            if max_price is not None:
                conditions.append("price <= :max_price")
                params["max_price"] = max_price
            if is_hot is not None:
                conditions.append("is_hot = :is_hot")
                params["is_hot"] = is_hot
            if is_new is not None:
                conditions.append("is_new = :is_new")
                params["is_new"] = is_new
            if is_welfare is not None:
                conditions.append("is_welfare = :is_welfare")
                params["is_welfare"] = is_welfare
            if search:
                conditions.append("(name ILIKE :q OR description ILIKE :q)")
                params["q"] = f"%{search}%"
            order = {"price_asc": "price ASC", "price_desc": "price DESC", "sales": "sales_count DESC", "rating": "rating DESC"}.get(sort_by, "created_at DESC")
            rows = db.execute(text(f"SELECT * FROM products WHERE {' AND '.join(conditions)} ORDER BY {order} LIMIT :lim OFFSET :off"), params).fetchall()
            return [_row_to_product(row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "读取商品列表", exc)
    require_database(db, "读取商品列表")
    products = list(PRODUCTS_DB.values())
    if category and category != "全部":
        products = [product for product in products if product.category == category]
    if material:
        products = [product for product in products if product.material == material]
    if min_price is not None:
        products = [product for product in products if product.price >= min_price]
    if max_price is not None:
        products = [product for product in products if product.price <= max_price]
    if is_hot is not None:
        products = [product for product in products if product.is_hot == is_hot]
    if is_new is not None:
        products = [product for product in products if product.is_new == is_new]
    if is_welfare is not None:
        products = [product for product in products if product.is_welfare == is_welfare]
    if search:
        q = search.lower()
        products = [product for product in products if q in product.name.lower() or q in product.description.lower()]
    if sort_by == "price_asc":
        products.sort(key=lambda item: item.price)
    elif sort_by == "price_desc":
        products.sort(key=lambda item: item.price, reverse=True)
    elif sort_by == "sales":
        products.sort(key=lambda item: item.sales_count, reverse=True)
    elif sort_by == "rating":
        products.sort(key=lambda item: item.rating, reverse=True)
    start = (page - 1) * page_size
    return [_sanitize_memory_product(product) for product in products[start:start + page_size]]


@router.get("/{product_id}", response_model=Product)
async def get_product_detail(product_id: str, db: Optional[Session] = Depends(get_db)):
    if db is not None:
        try:
            product = _db_product(db, product_id)
            if not product:
                raise HTTPException(status_code=404, detail="商品不存在")
            return product
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取商品详情", exc)
    require_database(db, "读取商品详情")
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    return _sanitize_memory_product(PRODUCTS_DB[product_id])


async def _translate_and_save(product_id: str, name: str, description: str,
                               category: str, material: str,
                               origin: Optional[str], material_verify: str):
    """后台任务：翻译商品并写入数据库"""
    from services.translation_service import translate_product_fields
    from database import SessionLocal, DB_AVAILABLE

    if not DB_AVAILABLE or SessionLocal is None:
        return

    try:
        translations = await translate_product_fields(
            name=name, description=description,
            category=category, material=material,
            origin=origin, material_verify=material_verify,
        )

        db = SessionLocal()
        try:
            set_clauses = []
            params = {"id": product_id}
            for field, value in translations.items():
                if value is not None:
                    set_clauses.append(f"{field} = :{field}")
                    params[field] = value

            if set_clauses:
                sql = f"UPDATE products SET {', '.join(set_clauses)} WHERE id = :id"
                db.execute(text(sql), params)
                db.commit()
                logger.info("✅ 商品 %s 翻译完成（%d 个字段）", product_id, len(set_clauses))
        finally:
            db.close()
    except Exception as e:
        logger.error("翻译商品 %s 失败: %s", product_id, e)


@router.post("", response_model=Product)
async def create_product(
    product: ProductCreate,
    background_tasks: BackgroundTasks,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    if not is_admin_user(user_id, db):
        raise HTTPException(status_code=403, detail="没有权限")
    product_id = f"HYY-{uuid.uuid4().hex[:6].upper()}"
    blockchain_hash = f"0x{uuid.uuid4().hex[:40]}"
    certificate = f"GTC-2026-{product_id[-6:]}"
    if db is not None:
        try:
            db.execute(text(
                "INSERT INTO products (id, name, description, price, original_price, "
                "category, material, images, stock, is_hot, is_new, is_welfare, "
                "origin, certificate, blockchain_hash) "
                "VALUES (:id, :name, :description, :price, :original_price, "
                ":category, :material, :images::jsonb, :stock, :is_hot, :is_new, "
                ":is_welfare, :origin, :certificate, :blockchain_hash)"
            ), {
                "id": product_id, "name": product.name,
                "description": product.description, "price": product.price,
                "original_price": product.original_price,
                "category": product.category, "material": product.material,
                "images": json.dumps(product.images), "stock": product.stock,
                "is_hot": product.is_hot, "is_new": product.is_new,
                "is_welfare": product.is_welfare, "origin": product.origin,
                "certificate": certificate, "blockchain_hash": blockchain_hash,
            })
            db.commit()

            # 后台异步翻译
            background_tasks.add_task(
                _translate_and_save, product_id, product.name,
                product.description, product.category, product.material,
                product.origin, "天然A货",
            )

            return _db_product(db, product_id, active_only=False) or Product(
                id=product_id, certificate=certificate,
                blockchain_hash=blockchain_hash, **product.model_dump(),
            )
        except Exception as exc:
            handle_database_error(db, "创建商品", exc)
    require_database(db, "创建商品")
    created = Product(
        id=product_id, certificate=certificate,
        blockchain_hash=blockchain_hash, **product.model_dump(),
    )
    created = _sanitize_memory_product(created)
    PRODUCTS_DB[product_id] = created
    return created


@router.put("/{product_id}", response_model=Product)
async def update_product(
    product_id: str,
    product: ProductCreate,
    background_tasks: BackgroundTasks,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    if not is_admin_user(user_id, db):
        raise HTTPException(status_code=403, detail="没有权限")
    if db is not None:
        try:
            existing = _db_product(db, product_id, active_only=False)
            if not existing:
                raise HTTPException(status_code=404, detail="商品不存在")
            result = db.execute(text(
                "UPDATE products SET name = :name, description = :description, "
                "price = :price, original_price = :original_price, "
                "category = :category, material = :material, "
                "images = :images::jsonb, stock = :stock, is_hot = :is_hot, "
                "is_new = :is_new, is_welfare = :is_welfare, origin = :origin "
                "WHERE id = :id"
            ), {
                "id": product_id, "name": product.name,
                "description": product.description, "price": product.price,
                "original_price": product.original_price,
                "category": product.category, "material": product.material,
                "images": json.dumps(product.images), "stock": product.stock,
                "is_hot": product.is_hot, "is_new": product.is_new,
                "is_welfare": product.is_welfare, "origin": product.origin,
            })
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="商品不存在")
            db.commit()

            # 后台异步重新翻译
            background_tasks.add_task(
                _translate_and_save, product_id, product.name,
                product.description, product.category, product.material,
                product.origin, existing.material_verify,
            )

            return _db_product(db, product_id, active_only=False) or Product(
                id=product_id, certificate=existing.certificate,
                blockchain_hash=existing.blockchain_hash,
                rating=existing.rating, sales_count=existing.sales_count,
                **product.model_dump(),
            )
        except HTTPException:
            if db is not None:
                db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "更新商品", exc)
    require_database(db, "更新商品")
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    existing = PRODUCTS_DB[product_id]
    updated = Product(
        id=product_id, certificate=existing.certificate,
        blockchain_hash=existing.blockchain_hash,
        rating=existing.rating, sales_count=existing.sales_count,
        **product.model_dump(),
    )
    PRODUCTS_DB[product_id] = updated
    return updated


@router.delete("/{product_id}")
async def delete_product(product_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    if not is_admin_user(user_id, db):
        raise HTTPException(status_code=403, detail="没有权限")
    if db is not None:
        try:
            result = db.execute(text("UPDATE products SET is_active = false WHERE id = :id"), {"id": product_id})
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="商品不存在")
            db.commit()
            return {"success": True, "message": "商品已删除"}
        except HTTPException:
            if db is not None:
                db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "删除商品", exc)
    require_database(db, "删除商品")
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    PRODUCTS_DB.pop(product_id, None)
    return {"success": True, "message": "商品已删除"}
