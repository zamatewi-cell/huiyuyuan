"""User, address, and payment-account schemas."""

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel


class UserResponse(BaseModel):
    id: str
    username: str
    phone: Optional[str] = None
    is_admin: bool = False
    balance: float = 0.0
    points: int = 0
    avatar: Optional[str] = None
    operator_number: Optional[int] = None
    payment_account_id: Optional[str] = None
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


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
    confirm_password: str


class DeactivateAccountRequest(BaseModel):
    current_password: str


PaymentAccountType = Literal["bank", "alipay", "wechat", "cash", "other"]


class PaymentAccountBase(BaseModel):
    name: str
    type: PaymentAccountType = "bank"
    account_number: Optional[str] = None
    bank_name: Optional[str] = None
    qr_code_url: Optional[str] = None
    is_active: bool = True
    is_default: bool = False


class PaymentAccountCreate(PaymentAccountBase):
    pass


class PaymentAccountUpdate(PaymentAccountBase):
    pass


class PaymentAccountResponse(PaymentAccountBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
