"""
Reviews router - create + product review list
DB-first with in-memory fallback
"""

import json
import uuid
import logging
from datetime import datetime
from typing import Optional, List

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.review import Review, ReviewCreate
from schemas.product import Product
from security import require_user
from database import get_db
from store import REVIEWS_DB, USERS_DB, PRODUCTS_DB

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Reviews"])


def _row_to_review(m) -> Review:
    imgs = m.get("images")
    if isinstance(imgs, str):
        imgs = json.loads(imgs)
    return Review(
        id=m["id"],
        product_id=m["product_id"],
        user_id=m["user_id"],
        user_name=m.get("user_name") or m.get("username", "用户"),
        user_avatar=m.get("user_avatar") or m.get("avatar_url"),
        rating=m["rating"],
        content=m.get("content", ""),
        images=imgs if isinstance(imgs, list) else [],
        created_at=m["created_at"].isoformat() if hasattr(m["created_at"], "isoformat") else str(m["created_at"]),
        is_anonymous=m.get("is_anonymous", False),
        like_count=m.get("like_count", 0),
        is_verified=m.get("is_verified", True),
    )


@router.get("/api/products/{product_id}/reviews", response_model=List[Review])
async def get_product_reviews(
    product_id: str,
    page: int = 1,
    page_size: int = 20,
    db: Optional[Session] = Depends(get_db),
):
    if db is not None:
        try:
            offset = (page - 1) * page_size
            rows = db.execute(
                text(
                    "SELECT r.*, "
                    "  CASE WHEN r.is_anonymous THEN '匿名用户' ELSE u.username END as user_name, "
                    "  CASE WHEN r.is_anonymous THEN NULL ELSE u.avatar_url END as user_avatar "
                    "FROM reviews r "
                    "LEFT JOIN users u ON r.user_id = u.id "
                    "WHERE r.product_id = :pid "
                    "ORDER BY r.created_at DESC "
                    "LIMIT :lim OFFSET :off"
                ),
                {"pid": product_id, "lim": page_size, "off": offset},
            ).fetchall()
            return [_row_to_review(r._mapping) for r in rows]
        except Exception as e:
            logger.error(f"DB get_product_reviews: {e}")

    reviews = [r for r in REVIEWS_DB.values() if r.product_id == product_id]
    reviews.sort(key=lambda x: x.created_at, reverse=True)
    start = (page - 1) * page_size
    return reviews[start : start + page_size]


@router.post("/api/reviews", response_model=Review)
async def create_review(review: ReviewCreate, authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)
    user = USERS_DB.get(user_id, {})

    review_id = f"rev_{uuid.uuid4().hex[:8]}"
    user_name = "匿名用户" if review.is_anonymous else user.get("username", "用户")
    user_avatar = None if review.is_anonymous else user.get("avatar")
    now_str = datetime.now().isoformat()

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO reviews "
                    "(id, product_id, order_id, user_id, rating, content, images, is_anonymous) "
                    "VALUES (:id, :pid, :oid, :uid, :rating, :content, :imgs::jsonb, :anon)"
                ),
                {
                    "id": review_id, "pid": review.product_id,
                    "oid": review.order_id, "uid": user_id,
                    "rating": review.rating, "content": review.content,
                    "imgs": json.dumps(review.images), "anon": review.is_anonymous,
                },
            )
            # update product avg rating
            avg_row = db.execute(
                text("SELECT AVG(rating)::numeric(3,1) as avg_r FROM reviews WHERE product_id = :pid"),
                {"pid": review.product_id},
            ).fetchone()
            if avg_row and avg_row._mapping["avg_r"] is not None:
                db.execute(
                    text("UPDATE products SET rating = :r WHERE id = :pid"),
                    {"r": float(avg_row._mapping["avg_r"]), "pid": review.product_id},
                )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB create_review: {e}")

    new_review = Review(
        id=review_id, product_id=review.product_id,
        user_id=user_id, user_name=user_name, user_avatar=user_avatar,
        rating=review.rating, content=review.content,
        images=review.images, created_at=now_str,
        is_anonymous=review.is_anonymous,
    )
    REVIEWS_DB[review_id] = new_review

    # update memory product rating
    if review.product_id in PRODUCTS_DB:
        product = PRODUCTS_DB[review.product_id]
        all_reviews = [r for r in REVIEWS_DB.values() if r.product_id == review.product_id]
        if all_reviews:
            avg = sum(r.rating for r in all_reviews) / len(all_reviews)
            PRODUCTS_DB[review.product_id] = Product(
                **{**product.model_dump(), "rating": round(avg, 1)}
            )

    return new_review
