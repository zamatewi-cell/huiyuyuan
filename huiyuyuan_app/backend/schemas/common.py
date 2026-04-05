"""通用 Pydantic 模型"""

from pydantic import BaseModel
from typing import Dict, Any, Optional


class NotificationRegister(BaseModel):
    device_token: str
    platform: str
    settings: Optional[Dict[str, Any]] = None


class OssStsResponse(BaseModel):
    access_key_id: str
    access_key_secret: str
    security_token: str
    expiration: str
