"""Shops router - DB-first with development-only in-memory fallback."""

import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.shop import Shop
from security import AuthorizationDep, require_permission
from store import SHOPS_DB

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/shops", tags=["Shops"])


def _row_to_shop(mapping) -> Shop:
    return Shop(
        id=mapping["id"],
        name=mapping["name"],
        platform=mapping["platform"],
        rating=float(mapping["rating"]),
        conversion_rate=float(mapping["conversion_rate"]),
        followers=mapping["followers"],
        category=mapping["category"],
        contact_status=mapping["contact_status"],
        shop_url=mapping.get("shop_url"),
        monthly_sales=mapping.get("monthly_sales"),
        negative_rate=float(mapping["negative_rate"]) if mapping.get("negative_rate") is not None else None,
        is_influencer=mapping["is_influencer"],
        operator_id=mapping.get("operator_id"),
        ai_priority=mapping.get("ai_priority"),
    )


@router.get("", response_model=List[Shop])
async def get_shops(platform: Optional[str] = None, category: Optional[str] = None, contact_status: Optional[str] = None, is_influencer: Optional[bool] = None, operator_id: Optional[str] = None, page: int = 1, page_size: int = 20, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    require_permission(authorization, "shop_radar", db=db)
    if db is not None:
        try:
            conditions = ["is_active = true"]
            params: dict[str, object] = {"lim": page_size, "off": (page - 1) * page_size}
            if platform:
                conditions.append("platform = :platform")
                params["platform"] = platform
            if category:
                conditions.append("category = :category")
                params["category"] = category
            if contact_status:
                conditions.append("contact_status = :contact_status")
                params["contact_status"] = contact_status
            if is_influencer is not None:
                conditions.append("is_influencer = :is_influencer")
                params["is_influencer"] = is_influencer
            if operator_id:
                conditions.append("operator_id = :operator_id")
                params["operator_id"] = operator_id
            rows = db.execute(text(f"SELECT * FROM shops WHERE {' AND '.join(conditions)} ORDER BY COALESCE(ai_priority, 0) DESC, created_at DESC LIMIT :lim OFFSET :off"), params).fetchall()
            return [_row_to_shop(row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "读取店铺列表", exc)
    require_database(db, "读取店铺列表")
    shops = list(SHOPS_DB.values())
    if platform:
        shops = [shop for shop in shops if shop.platform == platform]
    if category:
        shops = [shop for shop in shops if shop.category == category]
    if contact_status:
        shops = [shop for shop in shops if shop.contact_status == contact_status]
    if is_influencer is not None:
        shops = [shop for shop in shops if shop.is_influencer == is_influencer]
    if operator_id:
        shops = [shop for shop in shops if shop.operator_id == operator_id]
    shops.sort(key=lambda item: item.ai_priority or 0, reverse=True)
    start = (page - 1) * page_size
    return shops[start:start + page_size]


@router.get("/{shop_id}", response_model=Shop)
async def get_shop_detail(shop_id: str, authorization: AuthorizationDep = None, db: Optional[Session] = Depends(get_db)):
    require_permission(authorization, "shop_radar", db=db)
    if db is not None:
        try:
            row = db.execute(text("SELECT * FROM shops WHERE id = :id AND is_active = true"), {"id": shop_id}).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="店铺不存在")
            return _row_to_shop(row._mapping)
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "读取店铺详情", exc)
    require_database(db, "读取店铺详情")
    if shop_id not in SHOPS_DB:
        raise HTTPException(status_code=404, detail="店铺不存在")
    return SHOPS_DB[shop_id]
