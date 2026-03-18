"""认证相关 Pydantic 模型"""

from pydantic import BaseModel
from typing import Literal, Optional

SmsAction = Literal["login", "register", "reset"]


class LoginRequest(BaseModel):
    username: Optional[str] = None
    password: Optional[str] = None
    type: str = "operator"
    captcha: Optional[str] = None
    phone: Optional[str] = None
    code: Optional[str] = None
    login_type: Optional[str] = None


class TokenResponse(BaseModel):
    token: str
    refresh_token: str
    expires_in: int = 3600


class SmsCodeRequest(BaseModel):
    phone: str
    action: SmsAction = "login"


class SmsVerifyRequest(BaseModel):
    phone: str
    code: str
    action: SmsAction = "login"
