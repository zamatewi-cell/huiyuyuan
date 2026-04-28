"""订单相关 Pydantic 模型"""

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


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
    logistics_entries: List[Dict[str, Any]] = Field(default_factory=list)
    payment_id: Optional[str] = None
    payment_account_id: Optional[str] = None
    payment_account: Optional[Dict[str, Any]] = None
    payment_voucher_url: Optional[str] = None
    payment_admin_note: Optional[str] = None
    payment_record_status: Optional[str] = None
    payment_confirmed_by: Optional[str] = None
    payment_confirmed_at: Optional[str] = None


class OrderCreateItem(BaseModel):
    product_id: str = Field(min_length=1)
    quantity: int = Field(default=1, ge=1)


class OrderCreate(BaseModel):
    items: List[OrderCreateItem] = Field(min_length=1)
    address_id: str
    payment_method: str = "wechat"
    remark: Optional[str] = None
