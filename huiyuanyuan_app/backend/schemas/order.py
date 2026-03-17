"""订单相关 Pydantic 模型"""

from pydantic import BaseModel
from typing import Dict, List, Any, Optional


class Order(BaseModel):
    id: str
    user_id: str
    items: List[Dict[str, Any]]
    total_amount: float
    status: str = "pending"
    address: Optional[Dict[str, Any]] = None
    created_at: str
    payment_method: Optional[str] = None
    paid_at: Optional[str] = None
    shipped_at: Optional[str] = None
    delivered_at: Optional[str] = None
    completed_at: Optional[str] = None
    cancelled_at: Optional[str] = None
    cancel_reason: Optional[str] = None
    tracking_number: Optional[str] = None
    logistics_company: Optional[str] = None
    refund_reason: Optional[str] = None
    refund_amount: Optional[float] = None
    logistics_entries: List[Dict[str, Any]] = []
    payment_id: Optional[str] = None


class OrderCreate(BaseModel):
    items: List[Dict[str, Any]]
    address_id: str
    payment_method: str = "wechat"
    remark: Optional[str] = None
