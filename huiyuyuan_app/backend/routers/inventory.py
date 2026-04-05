"""Inventory router - admin inventory overview, stock updates, and logs."""

import json
import logging
from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.inventory import (
    InventoryItemResponse,
    InventoryStockUpdate,
    InventoryTransactionCreate,
    InventoryTransactionRecord,
)
from security import AuthorizationDep, require_admin
from store import (
    INVENTORY_META_DB,
    INVENTORY_TRANSACTIONS_DB,
    PRODUCTS_DB,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/inventory", tags=["Inventory"])


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _parse_images(raw_images: Any) -> list[str]:
    if isinstance(raw_images, list):
        return [str(image) for image in raw_images if image]
    if isinstance(raw_images, str) and raw_images.strip():
        try:
            decoded = json.loads(raw_images)
        except json.JSONDecodeError:
            return []
        if isinstance(decoded, list):
            return [str(image) for image in decoded if image]
    return []


def _default_min_stock(current_stock: int) -> int:
    if current_stock > 100:
        return 20
    if current_stock > 30:
        return 10
    return 5


def _default_cost_price(selling_price: float) -> float:
    ratio = 0.45 + (int(selling_price) % 3) * 0.05
    return round(selling_price * ratio, 2)


def _meta_for_product(
    product_id: str,
    *,
    current_stock: int,
    selling_price: float,
) -> dict[str, Any]:
    meta = INVENTORY_META_DB.setdefault(
        product_id,
        {
            "min_stock": _default_min_stock(current_stock),
            "cost_price": _default_cost_price(selling_price),
            "last_updated": _utcnow(),
        },
    )
    meta.setdefault("min_stock", _default_min_stock(current_stock))
    meta.setdefault("cost_price", _default_cost_price(selling_price))
    meta.setdefault("last_updated", _utcnow())
    return meta


def _inventory_item(
    *,
    product_id: str,
    product_name: str,
    category: str,
    image_url: Optional[str],
    current_stock: int,
    selling_price: float,
) -> InventoryItemResponse:
    meta = _meta_for_product(
        product_id,
        current_stock=current_stock,
        selling_price=selling_price,
    )
    return InventoryItemResponse(
        product_id=product_id,
        product_name=product_name,
        category=category,
        image_url=image_url,
        current_stock=current_stock,
        min_stock=int(meta["min_stock"]),
        cost_price=float(meta["cost_price"]),
        selling_price=selling_price,
        last_updated=meta["last_updated"],
    )


def _inventory_from_db_row(mapping: dict[str, Any]) -> InventoryItemResponse:
    images = _parse_images(mapping.get("images"))
    return _inventory_item(
        product_id=str(mapping["id"]),
        product_name=str(mapping.get("name") or ""),
        category=str(mapping.get("category") or ""),
        image_url=images[0] if images else None,
        current_stock=int(mapping.get("stock") or 0),
        selling_price=float(mapping.get("price") or 0.0),
    )


def _inventory_from_memory_product(product: Any) -> InventoryItemResponse:
    return _inventory_item(
        product_id=product.id,
        product_name=product.name,
        category=product.category,
        image_url=product.images[0] if product.images else None,
        current_stock=product.stock,
        selling_price=float(product.price),
    )


def _inventory_transactions_table_exists(db: Session) -> bool:
    try:
        table_name = db.execute(
            text("SELECT to_regclass('public.inventory_transactions')")
        ).scalar()
        return bool(table_name)
    except Exception:
        return False


def _list_memory_transactions(limit: int) -> list[InventoryTransactionRecord]:
    ordered = sorted(
        INVENTORY_TRANSACTIONS_DB,
        key=lambda item: item["created_at"],
        reverse=True,
    )
    return [InventoryTransactionRecord(**item) for item in ordered[:limit]]


def _persist_memory_transaction(record: InventoryTransactionRecord) -> None:
    payload = record.model_dump()
    INVENTORY_TRANSACTIONS_DB[:] = [
        tx for tx in INVENTORY_TRANSACTIONS_DB if tx["id"] != payload["id"]
    ]
    INVENTORY_TRANSACTIONS_DB.insert(0, payload)


def _update_inventory_meta(
    product_id: str,
    *,
    current_stock: int,
    selling_price: float,
    min_stock: Optional[int] = None,
    cost_price: Optional[float] = None,
    last_updated: Optional[datetime] = None,
) -> None:
    meta = _meta_for_product(
        product_id,
        current_stock=current_stock,
        selling_price=selling_price,
    )
    if min_stock is not None:
        meta["min_stock"] = min_stock
    if cost_price is not None:
        meta["cost_price"] = round(cost_price, 2)
    meta["last_updated"] = last_updated or _utcnow()


def _fetch_inventory_item(db: Session, product_id: str) -> Optional[InventoryItemResponse]:
    row = db.execute(
        text(
            "SELECT id, name, category, images, stock, price "
            "FROM products WHERE id = :id AND is_active = true LIMIT 1"
        ),
        {"id": product_id},
    ).fetchone()
    if not row:
        return None
    return _inventory_from_db_row(row._mapping)


def _update_product_stock_in_db(
    db: Session,
    product_id: str,
    new_stock: int,
    *,
    commit: bool = True,
) -> InventoryItemResponse:
    result = db.execute(
        text(
            "UPDATE products SET stock = :stock "
            "WHERE id = :id AND is_active = true"
        ),
        {"id": product_id, "stock": new_stock},
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Product not found")
    if commit:
        db.commit()
    item = _fetch_inventory_item(db, product_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return item


def _update_product_stock_in_memory(product_id: str, new_stock: int) -> InventoryItemResponse:
    product = PRODUCTS_DB.get(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    PRODUCTS_DB[product_id] = product.model_copy(update={"stock": new_stock})
    return _inventory_from_memory_product(PRODUCTS_DB[product_id])


@router.get("", response_model=list[InventoryItemResponse])
async def get_inventory(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT id, name, category, images, stock, price "
                    "FROM products WHERE is_active = true "
                    "ORDER BY created_at DESC, id DESC"
                )
            ).fetchall()
            return [_inventory_from_db_row(row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "read inventory list", exc)
    require_database(db, "read inventory list")
    return [_inventory_from_memory_product(product) for product in PRODUCTS_DB.values()]


@router.get("/transactions", response_model=list[InventoryTransactionRecord])
async def get_inventory_transactions(
    limit: int = 100,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    safe_limit = max(1, min(limit, 500))
    if db is not None and _inventory_transactions_table_exists(db):
        try:
            rows = db.execute(
                text(
                    "SELECT id, product_id, product_name, type, quantity, "
                    "stock_before, stock_after, note, operator_name, created_at "
                    "FROM inventory_transactions "
                    "ORDER BY created_at DESC LIMIT :lim"
                ),
                {"lim": safe_limit},
            ).fetchall()
            return [InventoryTransactionRecord(**row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "read inventory transactions", exc)
    require_database(db, "read inventory transactions")
    return _list_memory_transactions(safe_limit)


@router.post("/transactions", response_model=InventoryTransactionRecord)
async def create_inventory_transaction(
    payload: InventoryTransactionCreate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    if db is not None:
        try:
            item = _update_product_stock_in_db(
                db,
                payload.product_id,
                payload.stock_after,
                commit=False,
            )
            if _inventory_transactions_table_exists(db):
                db.execute(
                    text(
                        "INSERT INTO inventory_transactions "
                        "(id, product_id, product_name, type, quantity, stock_before, "
                        "stock_after, note, operator_name, created_at) "
                        "VALUES "
                        "(:id, :product_id, :product_name, :type, :quantity, :stock_before, "
                        ":stock_after, :note, :operator_name, :created_at)"
                    ),
                    {
                        **payload.model_dump(),
                        "created_at": payload.created_at,
                    },
                )
            db.commit()
            _update_inventory_meta(
                payload.product_id,
                current_stock=item.current_stock,
                selling_price=item.selling_price,
                last_updated=payload.created_at,
            )
        except HTTPException:
            if db is not None:
                db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "create inventory transaction", exc)
    else:
        require_database(db, "create inventory transaction")
        item = _update_product_stock_in_memory(payload.product_id, payload.stock_after)
        _update_inventory_meta(
            payload.product_id,
            current_stock=item.current_stock,
            selling_price=item.selling_price,
            last_updated=payload.created_at,
        )

    _persist_memory_transaction(payload)
    return payload


@router.get("/{product_id}", response_model=InventoryItemResponse)
async def get_inventory_item(
    product_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    if db is not None:
        try:
            item = _fetch_inventory_item(db, product_id)
            if item is None:
                raise HTTPException(status_code=404, detail="Product not found")
            return item
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "read inventory item", exc)
    require_database(db, "read inventory item")
    product = PRODUCTS_DB.get(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return _inventory_from_memory_product(product)


@router.put("/{product_id}/stock", response_model=InventoryItemResponse)
async def update_inventory_stock(
    product_id: str,
    payload: InventoryStockUpdate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    require_admin(authorization, db)
    if db is not None:
        try:
            item = _update_product_stock_in_db(db, product_id, payload.current_stock)
            _update_inventory_meta(
                product_id,
                current_stock=item.current_stock,
                selling_price=item.selling_price,
                min_stock=payload.min_stock,
                cost_price=payload.cost_price,
            )
            return _fetch_inventory_item(db, product_id) or item
        except HTTPException:
            if db is not None:
                db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "update inventory stock", exc)
    require_database(db, "update inventory stock")
    item = _update_product_stock_in_memory(product_id, payload.current_stock)
    _update_inventory_meta(
        product_id,
        current_stock=item.current_stock,
        selling_price=item.selling_price,
        min_stock=payload.min_stock,
        cost_price=payload.cost_price,
    )
    product = PRODUCTS_DB[product_id]
    return _inventory_from_memory_product(product)
