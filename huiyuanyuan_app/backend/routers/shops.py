"""
店铺路由 — 列表 + 详情
DB-first with in-memory fallback
"""

import logging
from typing import Optional, List

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.shop import Shop
from database import get_db
from store import SHOPS_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/shops", tags=["店铺"])


def _row_to_shop(m) -> Shop:
    """DB row mapping → Shop"""
    return Shop(
        id=m["id"],
        name=m["name"],
        platform=m["platform"],
        rating=float(m["rating"]),
        conversion_rate=float(m["conversion_rate"]),
        followers=m["followers"],
        category=m["category"],
        contact_status=m["contact_status"],
        shop_url=m.get("shop_url"),
        monthly_sales=m.get("monthly_sales"),
        negative_rate=float(m["negative_rate"]) if m.get("negative_rate") is not None else None,
        is_influencer=m["is_influencer"],
        operator_id=m.get("operator_id"),
        ai_priority=m.get("ai_priority"),
    )


@router.get("", response_model=List[Shop])
async def get_shops(
    platform: Optional[str] = None,
    category: Optional[str] = None,
    contact_status: Optional[str] = None,
    is_influencer: Optional[bool] = None,
    operator_id: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    db: Optional[Session] = Depends(get_db),
):
    """获取店铺列表"""

    if db is not None:
        try:
            conditions = ["is_active = true"]
            params: dict = {}

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
                conditions.append("is_influencer = :is_inf")
                params["is_inf"] = is_influencer
            if operator_id:
                conditions.append("operator_id = :op_id")
                params["op_id"] = operator_id

            where = " AND ".join(conditions)
            offset = (page - 1) * page_size
            params["lim"] = page_size
            params["off"] = offset

            rows = db.execute(
                text(f"SELECT * FROM shops WHERE {where} "
                     f"ORDER BY COALESCE(ai_priority, 0) DESC, created_at DESC "
                     f"LIMIT :lim OFFSET :off"),
                params,
            ).fetchall()
            return [_row_to_shop(r._mapping) for r in rows]
        except Exception as e:
            logger.error(f"DB get_shops: {e}")

    # memory fallback
    shops = list(SHOPS_DB.values())
    if platform:
        shops = [s for s in shops if s.platform == platform]
    if category:
        shops = [s for s in shops if s.category == category]
    if contact_status:
        shops = [s for s in shops if s.contact_status == contact_status]
    if is_influencer is not None:
        shops = [s for s in shops if s.is_influencer == is_influencer]
    if operator_id:
        shops = [s for s in shops if s.operator_id == operator_id]

    shops.sort(key=lambda x: x.ai_priority or 0, reverse=True)
    start = (page - 1) * page_size
    return shops[start : start + page_size]


@router.get("/{shop_id}", response_model=Shop)
async def get_shop_detail(shop_id: str, db: Optional[Session] = Depends(get_db)):
    """获取店铺详情"""

    if db is not None:
        try:
            row = db.execute(
                text("SELECT * FROM shops WHERE id = :id AND is_active = true"),
                {"id": shop_id},
            ).fetchone()
            if row:
                return _row_to_shop(row._mapping)
        except Exception as e:
            logger.error(f"DB get_shop_detail: {e}")

    if shop_id not in SHOPS_DB:
        raise HTTPException(status_code=404, detail="店铺不存在")
    return SHOPS_DB[shop_id]
