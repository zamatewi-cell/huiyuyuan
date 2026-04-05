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
from typing import Annotated, Optional

from fastapi import Depends, Header, HTTPException, Query, Request
from sqlalchemy import text

from config import (
    JWT_SECRET_KEY,
    JWT_ALGORITHM,
    JWT_ACCESS_EXPIRE_SECONDS,
    JWT_REFRESH_EXPIRE_DAYS,
    APP_ENV,
)

logger = logging.getLogger(__name__)
IS_PRODUCTION = APP_ENV == "production"

# ---- JWT ----
JWT_AVAILABLE = False
try:
    from jose import jwt as _jose_jwt
    JWT_AVAILABLE = True
except ImportError:
    _jose_jwt = None
    if IS_PRODUCTION:
        raise RuntimeError("python-jose 未安装，生产环境不能降级到 UUID token。")
    logger.warning("python-jose 未安装，JWT 不可用，将使用 UUID token")

# ---- bcrypt ----
BCRYPT_AVAILABLE = False
pwd_context = None
try:
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    BCRYPT_AVAILABLE = True
except ImportError:
    if IS_PRODUCTION:
        raise RuntimeError("passlib[bcrypt] 未安装，生产环境不能降级到明文密码比较。")
    logger.warning("passlib[bcrypt] 未安装，密码将以明文比较（仅限开发环境）")


# ============ 密码工具 ============

def hash_password(plain: str) -> str:
    """哈希密码（bcrypt），降级时返回原文"""
    if BCRYPT_AVAILABLE:
        return pwd_context.hash(plain)
    return plain


def verify_password(plain: str, hashed: str) -> bool:
    """验证密码（bcrypt），降级时明文比较"""
    if not hashed:
        return False

    if BCRYPT_AVAILABLE:
        try:
            return pwd_context.verify(plain, hashed)
        except Exception:
            if IS_PRODUCTION:
                logger.warning("生产环境检测到非 bcrypt 密码哈希，已拒绝登录。")
                return False
            # 哈希格式不匹配时回退明文比较（兼容旧数据迁移期）
            return plain == hashed
    if IS_PRODUCTION:
        return False
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

def get_authorization(
    request: Request,
    authorization_header: Annotated[Optional[str], Header(alias="Authorization")] = None,
    legacy_authorization: Annotated[Optional[str], Query(alias="authorization")] = None,
) -> Optional[str]:
    """统一提取认证信息，优先标准 Authorization header，兼容旧 query 参数。"""
    return (
        authorization_header
        or legacy_authorization
        or request.headers.get("Authorization")
        or request.query_params.get("authorization")
    )


AuthorizationDep = Annotated[Optional[str], Depends(get_authorization)]

def extract_bearer_token(authorization: str) -> Optional[str]:
    """从 Bearer 头或兼容字符串中提取 token。"""
    if not authorization:
        return None

    token = authorization.strip()
    if token.lower().startswith("bearer "):
        token = token[7:].strip()
    return token or None


def get_user_id_from_refresh_token(authorization: str) -> Optional[str]:
    """校验 refresh token 并提取 user_id。"""
    token = extract_bearer_token(authorization)
    if not token:
        return None

    payload = decode_jwt_token(token)
    if payload and payload.get("refresh") is True and "sub" in payload:
        return payload["sub"]
    return None

def get_user_id_from_token(authorization: str) -> Optional[str]:
    """从 Authorization 提取 user_id（JWT 优先 → 内存 TOKENS_DB 回退）"""
    token = extract_bearer_token(authorization)
    if not token:
        return None

    # 先尝试 JWT 解码
    payload = decode_jwt_token(token)
    if payload and payload.get("refresh") is not True and "sub" in payload:
        return payload["sub"]

    if token.startswith("refresh_"):
        return None

    # 回退到内存 token 映射（兼容旧 token）
    from store import TOKENS_DB
    return TOKENS_DB.get(token)


def require_user(authorization: str = None) -> str:
    """验证 token 并返回 user_id，失败抛 401"""
    user_id = get_user_id_from_token(authorization or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="未提供认证Token或Token已过期")
    if not get_user_record(user_id):
        raise HTTPException(status_code=401, detail="用户不存在或账号已失效")
    return user_id


def get_user_record(user_id: str, db=None) -> Optional[dict]:
    """按 user_id 获取用户，优先数据库，开发环境兼容内存存储。"""
    session = db
    own_session = False

    if session is None:
        from database import DB_AVAILABLE, SessionLocal

        if DB_AVAILABLE and SessionLocal is not None:
            session = SessionLocal()
            own_session = True

    try:
        if session is not None:
            row = session.execute(
                text(
                    "SELECT id, phone, username, password_hash, user_type, "
                    "operator_num, balance, points, avatar_url, is_active "
                    "FROM users WHERE id = :id LIMIT 1"
                ),
                {"id": user_id},
            ).fetchone()
            if row:
                data = row._mapping
                if not data["is_active"]:
                    return None
                return {
                    "id": data["id"],
                    "phone": data["phone"],
                    "username": data["username"],
                    "password_hash": data.get("password_hash") or "",
                    "user_type": data["user_type"],
                    "operator_number": data.get("operator_num"),
                    "balance": float(data["balance"]),
                    "points": data["points"],
                    "avatar": data.get("avatar_url"),
                    "is_admin": data["user_type"] == "admin",
                }
        if IS_PRODUCTION:
            return None

        from store import USERS_DB

        user = USERS_DB.get(user_id)
        if not user:
            return None
        if not user.get("is_active", True):
            return None
        return {**user}
    finally:
        if own_session and session is not None:
            session.close()


def is_admin_user(user_id: str, db=None) -> bool:
    user = get_user_record(user_id, db)
    return bool(user and user.get("is_admin"))


def require_admin(authorization: str = None, db=None) -> str:
    """验证 admin 权限，返回 user_id"""
    user_id = require_user(authorization)
    if not is_admin_user(user_id, db):
        raise HTTPException(status_code=403, detail="需要管理员权限")
    return user_id
