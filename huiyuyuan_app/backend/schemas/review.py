"""评价相关 Pydantic 模型"""

from pydantic import BaseModel, Field
from typing import List, Optional


class Review(BaseModel):
    id: str
    product_id: str
    order_id: Optional[str] = None
    user_id: str
    user_name: str
    user_avatar: Optional[str] = None
    rating: int
    content: str
    images: List[str] = []
    video_url: Optional[str] = None
    is_anonymous: bool = False
    created_at: str
    like_count: int = 0
    is_verified: bool = True


class ReviewCreate(BaseModel):
    product_id: str
    order_id: str
    rating: int = Field(..., ge=1, le=5)
    content: str
    images: List[str] = []
    is_anonymous: bool = False
