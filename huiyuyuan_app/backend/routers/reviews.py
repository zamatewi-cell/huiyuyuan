"""Reviews router - DB-first with development-only in-memory fallback."""

import json
import logging
import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.product import Product
from schemas.review import Review, ReviewCreate
from security import AuthorizationDep, get_user_record, require_user
from store import PRODUCTS_DB, REVIEWS_DB, USERS_DB

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Reviews"])


def _row_to_review(mapping) -> Review:
    images = mapping.get("images")
    if isinstance(images, str):
        images = json.loads(images)

    return Review(
        id=mapping["id"],
        product_id=mapping["product_id"],
        order_id=mapping.get("order_id"),
        user_id=mapping["user_id"],
        user_name=mapping.get("user_name") or mapping.get("username", "用户"),
        user_avatar=mapping.get("user_avatar") or mapping.get("avatar_url"),
        rating=mapping["rating"],
        content=mapping.get("content", ""),
        images=images if isinstance(images, list) else [],
        created_at=(
            mapping["created_at"].isoformat()
            if hasattr(mapping["created_at"], "isoformat")
            else str(mapping["created_at"])
        ),
        is_anonymous=mapping.get("is_anonymous", False),
        like_count=mapping.get("like_count", 0),
        is_verified=mapping.get("is_verified", True),
    )


def _raise_duplicate_review() -> None:
    raise HTTPException(status_code=409, detail="该订单已评价，请勿重复提交")


@router.get("/api/products/{product_id}/reviews", response_model=List[Review])
async def get_product_reviews(
    product_id: str,
    page: int = 1,
    page_size: int = 20,
    db: Optional[Session] = Depends(get_db),
):
    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT r.*, "
                    "CASE WHEN r.is_anonymous THEN '匿名用户' ELSE u.username END AS user_name, "
                    "CASE WHEN r.is_anonymous THEN NULL ELSE u.avatar_url END AS user_avatar "
                    "FROM reviews r "
                    "LEFT JOIN users u ON r.user_id = u.id "
                    "WHERE r.product_id = :pid "
                    "ORDER BY r.created_at DESC "
                    "LIMIT :lim OFFSET :off"
                ),
                {"pid": product_id, "lim": page_size, "off": (page - 1) * page_size},
            ).fetchall()
            return [_row_to_review(row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "读取商品评价", exc)

    require_database(db, "读取商品评价")
    reviews = [
        review for review in REVIEWS_DB.values() if review.product_id == product_id
    ]
    reviews.sort(key=lambda item: item.created_at, reverse=True)
    start = (page - 1) * page_size
    return reviews[start : start + page_size]


@router.post("/api/reviews", response_model=Review)
async def create_review(
    review: ReviewCreate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    review_id = f"rev_{uuid.uuid4().hex[:8]}"
    now = datetime.now().isoformat()

    if db is not None:
        try:
            user = get_user_record(user_id, db)
            if not user:
                raise HTTPException(status_code=404, detail="用户不存在")

            product_row = db.execute(
                text("SELECT id FROM products WHERE id = :id AND is_active = true"),
                {"id": review.product_id},
            ).fetchone()
            if not product_row:
                raise HTTPException(status_code=404, detail="商品不存在")

            existing_review = db.execute(
                text(
                    "SELECT id FROM reviews "
                    "WHERE order_id = :oid AND product_id = :pid AND user_id = :uid "
                    "LIMIT 1"
                ),
                {"oid": review.order_id, "pid": review.product_id, "uid": user_id},
            ).fetchone()
            if existing_review:
                _raise_duplicate_review()

            db.execute(
                text(
                    "INSERT INTO reviews "
                    "(id, product_id, order_id, user_id, rating, content, images, is_anonymous) "
                    "VALUES (:id, :pid, :oid, :uid, :rating, :content, :images::jsonb, :anonymous)"
                ),
                {
                    "id": review_id,
                    "pid": review.product_id,
                    "oid": review.order_id,
                    "uid": user_id,
                    "rating": review.rating,
                    "content": review.content,
                    "images": json.dumps(review.images),
                    "anonymous": review.is_anonymous,
                },
            )

            avg_row = db.execute(
                text(
                    "SELECT AVG(rating)::numeric(3,1) AS avg_rating "
                    "FROM reviews WHERE product_id = :pid"
                ),
                {"pid": review.product_id},
            ).fetchone()
            if avg_row and avg_row._mapping["avg_rating"] is not None:
                db.execute(
                    text("UPDATE products SET rating = :rating WHERE id = :pid"),
                    {
                        "rating": float(avg_row._mapping["avg_rating"]),
                        "pid": review.product_id,
                    },
                )

            db.commit()
            return Review(
                id=review_id,
                product_id=review.product_id,
                order_id=review.order_id,
                user_id=user_id,
                user_name="匿名用户" if review.is_anonymous else user.get("username", "用户"),
                user_avatar=None if review.is_anonymous else user.get("avatar"),
                rating=review.rating,
                content=review.content,
                images=review.images,
                created_at=now,
                is_anonymous=review.is_anonymous,
            )
        except HTTPException:
            db.rollback()
            raise
        except Exception as exc:
            handle_database_error(db, "创建评价", exc)

    require_database(db, "创建评价")
    user = USERS_DB.get(user_id, {})
    if any(
        item.order_id == review.order_id
        and item.product_id == review.product_id
        and item.user_id == user_id
        for item in REVIEWS_DB.values()
    ):
        _raise_duplicate_review()

    new_review = Review(
        id=review_id,
        product_id=review.product_id,
        order_id=review.order_id,
        user_id=user_id,
        user_name="匿名用户" if review.is_anonymous else user.get("username", "用户"),
        user_avatar=None if review.is_anonymous else user.get("avatar"),
        rating=review.rating,
        content=review.content,
        images=review.images,
        created_at=now,
        is_anonymous=review.is_anonymous,
    )
    REVIEWS_DB[review_id] = new_review

    if review.product_id in PRODUCTS_DB:
        product = PRODUCTS_DB[review.product_id]
        product_reviews = [
            item for item in REVIEWS_DB.values() if item.product_id == review.product_id
        ]
        if product_reviews:
            PRODUCTS_DB[review.product_id] = Product(
                **{
                    **product.model_dump(),
                    "rating": round(
                        sum(item.rating for item in product_reviews)
                        / len(product_reviews),
                        1,
                    ),
                }
            )

    return new_review
