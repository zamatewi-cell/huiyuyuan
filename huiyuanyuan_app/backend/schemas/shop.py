"""店铺相关 Pydantic 模型"""

from pydantic import BaseModel
from typing import Optional


class Shop(BaseModel):
    id: str
    name: str
    platform: str
    rating: float
    conversion_rate: float
    followers: int
    category: str
    contact_status: str = "pending"
    shop_url: Optional[str] = None
    monthly_sales: Optional[int] = None
    negative_rate: Optional[float] = None
    is_influencer: bool = False
    operator_id: Optional[str] = None
    ai_priority: Optional[int] = None
