"""
认证路由 — 登录 / 短信验证 / 登出 / 刷新
安全修复:
  - 密码验证使用 bcrypt (verify_password)
  - SMS Redis 不可用时生产环境返回 503
  - JWT Token 替代简单 UUID Token
"""

import re
import uuid
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.auth import LoginRequest, SmsCodeRequest, SmsVerifyRequest
from schemas.user import UserResponse
from security import (
    verify_password,
    create_jwt_token,
    create_refresh_token,
    get_user_id_from_token,
    JWT_AVAILABLE,
)
from config import SMS_REAL_MODE, JWT_ACCESS_EXPIRE_SECONDS
from database import get_db, DB_AVAILABLE, SessionLocal
from store import USERS_DB, TOKENS_DB
from services.sms_service import (
    generate_and_store_code,
    verify_stored_code,
    send_aliyun_sms,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["认证"])


def _generate_compat_token() -> str:
    """生成兼容旧模式的 token"""
    return f"token_{uuid.uuid4().hex}"


def _db_find_user(db: Session, phone: str = None, username: str = None,
                   operator_num: int = None, user_type: str = None) -> Optional[dict]:
    """从 DB 查找用户，返回 dict 或 None"""
    try:
        conditions = []
        params: dict = {}
        if phone:
            conditions.append("phone = :phone")
            params["phone"] = phone
        if username:
            conditions.append("username = :username")
            params["username"] = username
        if operator_num is not None:
            conditions.append("operator_num = :op_num")
            params["op_num"] = operator_num
        if user_type:
            conditions.append("user_type = :utype")
            params["utype"] = user_type

        if not conditions:
            return None

        where = " AND ".join(conditions)
        row = db.execute(
            text(f"SELECT id, phone, username, password_hash, user_type, "
                 f"operator_num, balance, points, avatar_url, is_admin, is_active "
                 f"FROM users WHERE {where} LIMIT 1"),
            params,
        ).fetchone()
        if not row:
            return None
        m = row._mapping
        if not m["is_active"]:
            return None
        return {
            "id": m["id"],
            "phone": m["phone"],
            "username": m["username"],
            "password_hash": m.get("password_hash") or "",
            "user_type": m["user_type"],
            "operator_number": m.get("operator_num"),
            "balance": float(m["balance"]),
            "points": m["points"],
            "avatar": m.get("avatar_url"),
            "is_admin": m["user_type"] == "admin",
        }
    except Exception as e:
        logger.error(f"DB _db_find_user: {e}")
        return None


def _login_success(user_id: str, user_data: dict) -> dict:
    """生成登录成功的标准响应"""
    token = create_jwt_token(user_id)
    TOKENS_DB[token] = user_id
    return {
        "success": True,
        "token": token,
        "refresh_token": create_refresh_token(user_id),
        "expires_in": JWT_ACCESS_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
        "user": UserResponse(**user_data).model_dump(),
    }


@router.post("/login")
async def login(request: LoginRequest, db: Optional[Session] = Depends(get_db)):
    """用户登录（管理员/操作员/客户短信）"""

    # ---- 管理员登录 ----
    if request.type == "admin":
        user_data = None

        # DB first
        if db is not None:
            user_data = _db_find_user(db, phone=request.username, user_type="admin")

        # Memory fallback
        if user_data is None:
            admin = USERS_DB.get("admin_001")
            if admin and request.username == admin.get("phone"):
                user_data = {**admin}

        if user_data is None:
            raise HTTPException(status_code=401, detail="用户名或密码错误")

        if not verify_password(request.password or "", user_data.get("password_hash", "")):
            raise HTTPException(status_code=401, detail="用户名或密码错误")

        if request.captcha and request.captcha != "8888":
            raise HTTPException(status_code=400, detail="验证码错误")

        return _login_success(user_data["id"], user_data)

    # ---- 操作员登录 ----
    elif request.type == "operator" and getattr(request, "login_type", None) != "customer_sms":
        user_data = None

        # Try DB first — by operator_num or username
        if db is not None:
            try:
                op_num = int(request.username) if request.username else 0
                if 1 <= op_num <= 999:
                    user_data = _db_find_user(db, operator_num=op_num, user_type="operator")
            except (ValueError, TypeError):
                pass
            if user_data is None:
                user_data = _db_find_user(db, username=request.username, user_type="operator")

        # Memory fallback
        if user_data is None:
            operator_id = None
            try:
                op_num = int(request.username) if request.username else 0
                if 1 <= op_num <= 10:
                    operator_id = f"operator_{op_num}"
            except (ValueError, TypeError):
                for uid, user in USERS_DB.items():
                    if user.get("username") == request.username:
                        operator_id = uid
                        break

            if operator_id and operator_id in USERS_DB:
                user_data = {**USERS_DB[operator_id]}

        if user_data and verify_password(request.password or "", user_data.get("password_hash", "")):
            return _login_success(user_data["id"], user_data)

    # ---- 客户短信登录 (旧路径兼容) ----
    if getattr(request, "login_type", None) == "customer_sms" or request.type == "customer_sms":
        if not request.phone or not request.code:
            raise HTTPException(status_code=400, detail="手机号和验证码不能为空")

        # 使用 sms_service 校验验证码
        verify_stored_code(request.phone, request.code)

        # 查找或创建用户 — DB first
        user_data = None
        if db is not None:
            user_data = _db_find_user(db, phone=request.phone)
            if user_data is None:
                # 在 DB 中创建新用户
                try:
                    new_id = f"customer_{int(datetime.now().timestamp() * 1000)}"
                    uname = f"用户_{request.phone[-4:]}" if len(request.phone) >= 4 else f"用户_{request.phone}"
                    db.execute(
                        text("INSERT INTO users(id, phone, username, user_type) "
                             "VALUES(:id, :phone, :uname, 'customer')"),
                        {"id": new_id, "phone": request.phone, "uname": uname},
                    )
                    db.commit()
                    user_data = {
                        "id": new_id, "phone": request.phone, "username": uname,
                        "user_type": "customer", "balance": 0.0, "points": 0,
                        "avatar": None, "is_admin": False,
                    }
                except Exception as e:
                    db.rollback()
                    logger.error(f"DB create customer: {e}")

        # Memory fallback
        if user_data is None:
            for uid, user in USERS_DB.items():
                if user.get("phone") == request.phone:
                    user_data = {**user}
                    break

        if user_data is None:
            from security import hash_password
            new_id = f"customer_{int(datetime.now().timestamp() * 1000)}"
            expected_code = request.phone[-4:] if len(request.phone) >= 4 else request.phone
            user_data = {
                "id": new_id,
                "username": f"用户_{expected_code}",
                "phone": request.phone,
                "password_hash": hash_password(""),
                "is_admin": False,
                "balance": 0.0,
                "points": 0,
                "avatar": None,
                "user_type": "customer",
            }
            USERS_DB[new_id] = user_data

        return _login_success(user_data["id"], user_data)

    raise HTTPException(status_code=401, detail="用户名或密码错误")


@router.post("/send-sms")
async def send_sms_code(body: SmsCodeRequest, request: Request):
    """发送短信验证码（含 Redis 限流）"""
    if not re.match(r"^1[3-9]\d{9}$", body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    code = generate_and_store_code(body.phone)

    # 记录发送日志
    biz_id = ""
    if SMS_REAL_MODE:
        result = send_aliyun_sms(body.phone, code)
        biz_id = result.get("biz_id", "")
        if not result["success"]:
            logger.error(f"SMS send failed for {body.phone}: {result['message']}")
            raise HTTPException(
                status_code=502, detail="短信发送失败，请稍后重试"
            )

    # 写入数据库日志（可选）
    if DB_AVAILABLE and SessionLocal:
        try:
            db: Session = SessionLocal()
            ip_addr = request.client.host if request.client else None
            db.execute(
                text(
                    "INSERT INTO sms_logs(phone, action, biz_id, ip_addr) "
                    "VALUES(:phone, :action, :biz_id, :ip)"
                ),
                {"phone": body.phone, "action": body.action, "biz_id": biz_id, "ip": ip_addr},
            )
            db.commit()
            db.close()
        except Exception as e:
            logger.warning(f"SMS log write failed: {e}")

    if SMS_REAL_MODE:
        return {"success": True, "message": "验证码已发送，5分钟内有效"}
    else:
        return {"success": True, "message": f"（测试模式）验证码：{code}"}


@router.post("/verify-sms")
async def verify_sms_code(body: SmsVerifyRequest, db: Optional[Session] = Depends(get_db)):
    """校验短信验证码，自动注册新用户并返回 JWT"""
    if not re.match(r"^1[3-9]\d{9}$", body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    # ---- 验证码校验 ----
    verify_stored_code(body.phone, body.code)

    # ---- 查找或创建用户 ----
    user_id = None
    user_data = None

    if db is not None:
        try:
            row = db.execute(
                text(
                    "SELECT id, phone, username, user_type, balance, points, avatar_url "
                    "FROM users WHERE phone = :phone"
                ),
                {"phone": body.phone},
            ).fetchone()
            if row:
                user_id = row[0]
                user_data = {
                    "id": row[0],
                    "phone": row[1],
                    "username": row[2],
                    "user_type": row[3],
                    "balance": float(row[4]),
                    "points": row[5],
                    "avatar": row[6],
                    "is_admin": row[3] == "admin",
                }
            else:
                user_id = f"u_{uuid.uuid4().hex[:16]}"
                uname = f"用户{body.phone[-4:]}"
                db.execute(
                    text(
                        "INSERT INTO users(id, phone, username, user_type) "
                        "VALUES(:id, :phone, :username, 'customer')"
                    ),
                    {"id": user_id, "phone": body.phone, "username": uname},
                )
                db.commit()
                user_data = {
                    "id": user_id,
                    "phone": body.phone,
                    "username": uname,
                    "user_type": "customer",
                    "balance": 0.0,
                    "points": 0,
                    "avatar": None,
                    "is_admin": False,
                }
        except Exception as e:
            logger.error(f"DB error in verify_sms: {e}")
            db.rollback()

    # ---- 降级：内存数据库 ----
    if user_data is None:
        for uid, u in USERS_DB.items():
            if u.get("phone") == body.phone:
                user_id = uid
                user_data = {**u, "avatar": u.get("avatar")}
                break
        if not user_data:
            user_id = f"customer_{int(datetime.now().timestamp() * 1000)}"
            user_data = {
                "id": user_id,
                "phone": body.phone,
                "username": f"用户{body.phone[-4:]}",
                "user_type": "customer",
                "balance": 0.0,
                "points": 0,
                "avatar": None,
                "is_admin": False,
            }
            from security import hash_password
            USERS_DB[user_id] = {**user_data, "password_hash": hash_password("")}

    # ---- 生成 Token ----
    token = create_jwt_token(user_id, {"phone": body.phone})
    refresh = create_refresh_token(user_id, {"phone": body.phone})
    TOKENS_DB[token] = user_id

    return {
        "success": True,
        "token": token,
        "refresh_token": refresh,
        "expires_in": JWT_ACCESS_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
        "user": UserResponse(**user_data).model_dump(),
    }


@router.post("/logout")
async def logout(authorization: str = None):
    """用户登出"""
    if authorization:
        token = authorization.replace("Bearer ", "")
        TOKENS_DB.pop(token, None)
    return {"success": True, "message": "已退出登录"}


@router.post("/refresh")
async def refresh_token(authorization: str = None):
    """刷新Token"""
    user_id = get_user_id_from_token(authorization or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token无效")

    new_token = create_jwt_token(user_id)
    TOKENS_DB[new_token] = user_id

    old_token = (authorization or "").replace("Bearer ", "")
    TOKENS_DB.pop(old_token, None)

    return {
        "token": new_token,
        "refresh_token": create_refresh_token(user_id),
        "expires_in": JWT_ACCESS_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
    }
