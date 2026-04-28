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
from database import REDIS_AVAILABLE, redis_client

logger = logging.getLogger(__name__)
IS_PRODUCTION = APP_ENV == "production"
_SESSION_TTL_SECONDS = max(JWT_ACCESS_EXPIRE_SECONDS, JWT_REFRESH_EXPIRE_DAYS * 86400)
_REDIS_ACTIVE_SESSIONS = "auth:user_sessions:{user_id}"
_REDIS_REVOKED_SESSION = "auth:revoked_session:{session_id}"

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
def _now_ts() -> int:
    return int(datetime.now(timezone.utc).timestamp())


def _session_key(user_id: str) -> str:
    return _REDIS_ACTIVE_SESSIONS.format(user_id=user_id)


def _revoked_session_key(session_id: str) -> str:
    return _REDIS_REVOKED_SESSION.format(session_id=session_id)


def get_token_session_id(token: str) -> Optional[str]:
    payload = decode_jwt_token(token)
    if not payload:
        return None
    session_id = payload.get("sid")
    return session_id if isinstance(session_id, str) and session_id else None


def register_user_session(user_id: str, session_id: Optional[str]) -> None:
    if not user_id or not session_id:
        return

    if REDIS_AVAILABLE and redis_client:
        key = _session_key(user_id)
        redis_client.sadd(key, session_id)
        redis_client.expire(key, _SESSION_TTL_SECONDS)
        return

    from store import ACTIVE_SESSIONS_DB

    ACTIVE_SESSIONS_DB.setdefault(user_id, set()).add(session_id)


def is_session_revoked(session_id: Optional[str]) -> bool:
    if not session_id:
        return False

    if REDIS_AVAILABLE and redis_client:
        return bool(redis_client.exists(_revoked_session_key(session_id)))

    from store import REVOKED_SESSIONS_DB

    expires_at = REVOKED_SESSIONS_DB.get(session_id)
    if not expires_at:
        return False
    if expires_at <= _now_ts():
        REVOKED_SESSIONS_DB.pop(session_id, None)
        return False
    return True


def revoke_user_session(user_id: str, session_id: Optional[str]) -> bool:
    if not user_id or not session_id:
        return False

    if REDIS_AVAILABLE and redis_client:
        redis_client.setex(_revoked_session_key(session_id), _SESSION_TTL_SECONDS, "1")
        redis_client.srem(_session_key(user_id), session_id)
        return True

    from store import ACTIVE_SESSIONS_DB, REVOKED_SESSIONS_DB

    REVOKED_SESSIONS_DB[session_id] = _now_ts() + _SESSION_TTL_SECONDS
    sessions = ACTIVE_SESSIONS_DB.get(user_id)
    if sessions and session_id in sessions:
        sessions.discard(session_id)
        if not sessions:
            ACTIVE_SESSIONS_DB.pop(user_id, None)
    return True


def revoke_session_for_token(token: Optional[str]) -> bool:
    if not token:
        return False

    payload = decode_jwt_token(token)
    if payload and payload.get("sub"):
        session_id = payload.get("sid")
        if session_id:
            return revoke_user_session(payload["sub"], session_id)

    from store import TOKENS_DB

    return TOKENS_DB.pop(token, None) is not None


def revoke_other_user_sessions(user_id: str, current_token: str = "") -> int:
    current_session_id = get_token_session_id(current_token)
    from store import TOKENS_DB

    if REDIS_AVAILABLE and redis_client:
        session_ids = [
            sid for sid in redis_client.smembers(_session_key(user_id))
            if sid and sid != current_session_id
        ]
        for session_id in session_ids:
            revoke_user_session(user_id, session_id)
        tokens_to_remove = [
            token for token, uid in TOKENS_DB.items()
            if uid == user_id and token != current_token
        ]
        for token in tokens_to_remove:
            TOKENS_DB.pop(token, None)
        return max(len(session_ids), len(tokens_to_remove))

    from store import ACTIVE_SESSIONS_DB

    session_ids = [
        sid for sid in ACTIVE_SESSIONS_DB.get(user_id, set())
        if sid and sid != current_session_id
    ]
    for session_id in session_ids:
        revoke_user_session(user_id, session_id)
    tokens_to_remove = [
        token for token, uid in TOKENS_DB.items()
        if uid == user_id and token != current_token
    ]
    for token in tokens_to_remove:
        TOKENS_DB.pop(token, None)
    return max(len(session_ids), len(tokens_to_remove))


def revoke_all_user_sessions(user_id: str) -> int:
    if not user_id:
        return 0
    from store import TOKENS_DB

    if REDIS_AVAILABLE and redis_client:
        session_ids = [sid for sid in redis_client.smembers(_session_key(user_id)) if sid]
        for session_id in session_ids:
            revoke_user_session(user_id, session_id)
        tokens_to_remove = [token for token, uid in TOKENS_DB.items() if uid == user_id]
        for token in tokens_to_remove:
            TOKENS_DB.pop(token, None)
        return max(len(session_ids), len(tokens_to_remove))

    from store import ACTIVE_SESSIONS_DB

    session_ids = [sid for sid in ACTIVE_SESSIONS_DB.get(user_id, set()) if sid]
    for session_id in session_ids:
        revoke_user_session(user_id, session_id)
    tokens_to_remove = [token for token, uid in TOKENS_DB.items() if uid == user_id]
    for token in tokens_to_remove:
        TOKENS_DB.pop(token, None)
    return max(len(session_ids), len(tokens_to_remove))


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
    if (
        payload
        and payload.get("refresh") is True
        and "sub" in payload
        and not is_session_revoked(payload.get("sid"))
    ):
        return payload["sub"]
    return None

def get_user_id_from_token(authorization: str) -> Optional[str]:
    """从 Authorization 提取 user_id（JWT 优先 → 内存 TOKENS_DB 回退）"""
    token = extract_bearer_token(authorization)
    if not token:
        return None

    # 先尝试 JWT 解码
    payload = decode_jwt_token(token)
    if payload and payload.get("refresh") is True:
        return None
    if payload and payload.get("refresh") is not True and "sub" in payload:
        if is_session_revoked(payload.get("sid")):
            return None
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


def has_permission(
    user_id: str,
    permission: str,
    db=None,
    *,
    allow_non_operator: bool = True,
) -> bool:
    user = get_user_record(user_id, db)
    if not user:
        return False
    if user.get("is_admin"):
        return True
    if user.get("user_type") != "operator":
        return allow_non_operator
    return permission in (user.get("permissions") or [])


def require_permission(
    authorization: str = None,
    permission: str = "",
    db=None,
    *,
    allow_non_operator: bool = True,
) -> str:
    user_id = require_user(authorization)
    if not has_permission(
        user_id,
        permission,
        db,
        allow_non_operator=allow_non_operator,
    ):
        raise HTTPException(status_code=403, detail="没有权限执行该操作")
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
            def fetch_row(include_permissions: bool = True):
                fields = (
                    "id, phone, username, password_hash, user_type, "
                    "operator_num, balance, points, avatar_url, is_active"
                )
                if include_permissions:
                    fields = f"{fields}, permissions"
                return session.execute(
                    text(f"SELECT {fields} FROM users WHERE id = :id LIMIT 1"),
                    {"id": user_id},
                ).fetchone()

            try:
                row = fetch_row(include_permissions=True)
            except Exception as exc:
                if "permissions" not in str(exc).lower():
                    raise
                row = fetch_row(include_permissions=False)

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
                    "permissions": data.get("permissions") or [],
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
