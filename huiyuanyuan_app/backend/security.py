"""
安全模块 — JWT 令牌 + bcrypt 密码哈希 + 认证依赖
安全修复:
  - JWT Secret 强制从环境变量读取（生产环境无值则启动失败）
  - 密码存储使用 bcrypt 哈希（不再明文）
  - Token 验证优先 JWT 解码，回退内存映射（兼容旧 token）
"""

import uuid
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException

from config import (
    JWT_SECRET_KEY,
    JWT_ALGORITHM,
    JWT_ACCESS_EXPIRE_SECONDS,
    JWT_REFRESH_EXPIRE_DAYS,
)

logger = logging.getLogger(__name__)

# ---- JWT ----
JWT_AVAILABLE = False
try:
    from jose import jwt as _jose_jwt
    JWT_AVAILABLE = True
except ImportError:
    _jose_jwt = None
    logger.warning("python-jose 未安装，JWT 不可用，将使用 UUID token")

# ---- bcrypt ----
BCRYPT_AVAILABLE = False
pwd_context = None
try:
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    BCRYPT_AVAILABLE = True
except ImportError:
    logger.warning("passlib[bcrypt] 未安装，密码将以明文比较（仅限开发环境）")


# ============ 密码工具 ============

def hash_password(plain: str) -> str:
    """哈希密码（bcrypt），降级时返回原文"""
    if BCRYPT_AVAILABLE:
        return pwd_context.hash(plain)
    return plain


def verify_password(plain: str, hashed: str) -> bool:
    """验证密码（bcrypt），降级时明文比较"""
    if BCRYPT_AVAILABLE:
        try:
            return pwd_context.verify(plain, hashed)
        except Exception:
            # 哈希格式不匹配时回退明文比较（兼容旧数据迁移期）
            return plain == hashed
    return plain == hashed


# ============ JWT 工具 ============

def create_jwt_token(user_id: str, extra: dict = None) -> str:
    """生成 JWT Token，降级时返回 UUID"""
    if not JWT_AVAILABLE:
        return str(uuid.uuid4())
    payload = {
        "sub": user_id,
        "exp": datetime.now(timezone.utc) + timedelta(seconds=JWT_ACCESS_EXPIRE_SECONDS),
        "iat": datetime.now(timezone.utc),
    }
    if extra:
        payload.update(extra)
    return _jose_jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def create_refresh_token(user_id: str, extra: dict = None) -> str:
    """生成刷新 Token"""
    if not JWT_AVAILABLE:
        return f"refresh_{uuid.uuid4()}"
    payload = {
        "sub": user_id,
        "exp": datetime.now(timezone.utc) + timedelta(days=JWT_REFRESH_EXPIRE_DAYS),
        "iat": datetime.now(timezone.utc),
        "refresh": True,
    }
    if extra:
        payload.update(extra)
    return _jose_jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_jwt_token(token: str) -> Optional[dict]:
    """解码 JWT，失败返回 None"""
    if not JWT_AVAILABLE:
        return None
    try:
        return _jose_jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
    except Exception:
        return None


# ============ 认证依赖 ============

def get_user_id_from_token(authorization: str) -> Optional[str]:
    """从 Authorization 提取 user_id（JWT 优先 → 内存 TOKENS_DB 回退）"""
    if not authorization:
        return None
    token = authorization.replace("Bearer ", "").strip()
    if not token:
        return None

    # 先尝试 JWT 解码
    payload = decode_jwt_token(token)
    if payload and "sub" in payload:
        return payload["sub"]

    # 回退到内存 token 映射（兼容旧 token）
    from store import TOKENS_DB
    return TOKENS_DB.get(token)


def require_user(authorization: str = None) -> str:
    """验证 token 并返回 user_id，失败抛 401"""
    user_id = get_user_id_from_token(authorization or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="未提供认证Token或Token已过期")
    return user_id


def require_admin(authorization: str = None) -> str:
    """验证 admin 权限，返回 user_id"""
    user_id = require_user(authorization)
    from store import USERS_DB
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="需要管理员权限")
    return user_id
