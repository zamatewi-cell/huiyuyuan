"""用户 & 地址相关 Pydantic 模型"""

from pydantic import BaseModel
from typing import Optional


class UserResponse(BaseModel):
    id: str
    username: str
    phone: Optional[str] = None
    is_admin: bool = False
    balance: float = 0.0
    points: int = 0
    avatar: Optional[str] = None
    operator_number: Optional[int] = None
    user_type: str = "operator"


class Address(BaseModel):
    id: str
    user_id: str
    recipient_name: str
    phone_number: str
    province: str
    city: str
    district: str
    detail_address: str
    is_default: bool = False
    postal_code: Optional[str] = None
    tag: Optional[str] = None


class AddressCreate(BaseModel):
    recipient_name: str
    phone_number: str
    province: str
    city: str
    district: str
    detail_address: str
    is_default: bool = False
    postal_code: Optional[str] = None
    tag: Optional[str] = None
