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

from schemas.auth import (
    LoginRequest,
    RegisterRequest,
    ResetPasswordRequest,
    SmsCodeRequest,
    SmsVerifyRequest,
)
from schemas.user import UserResponse
from security import (
    AuthorizationDep,
    verify_password,
    hash_password,
    create_jwt_token,
    create_refresh_token,
    get_user_id_from_refresh_token,
    get_token_session_id,
    get_user_record,
    extract_bearer_token,
    revoke_all_user_sessions,
    register_user_session,
    revoke_session_for_token,
    require_user,
    JWT_AVAILABLE,
)
from config import SMS_REAL_MODE, JWT_ACCESS_EXPIRE_SECONDS, IS_PRODUCTION
from database import get_db, DB_AVAILABLE, SessionLocal
from store import USERS_DB, TOKENS_DB
from services.sms_service import (
    generate_and_store_code,
    verify_stored_code,
    send_aliyun_sms,
)
from services.login_guard_service import (
    clear_login_failures,
    ensure_login_allowed,
    record_login_failure,
)
from services.captcha_service import generate_captcha, verify_captcha
from services.device_tracker import track_device_login, get_user_devices

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["认证"])
PHONE_PATTERN = re.compile(r"^1[3-9]\d{9}$")
PASSWORD_PATTERN = re.compile(r"^(?=.*[A-Za-z])(?=.*\d).{8,}$")


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

        def fetch_row(include_permissions: bool = True):
            fields = (
                "id, phone, username, password_hash, user_type, "
                "operator_num, balance, points, avatar_url, is_active"
            )
            if include_permissions:
                fields = f"{fields}, permissions"
            return db.execute(
                text(f"SELECT {fields} FROM users WHERE {where} LIMIT 1"),
                params,
            ).fetchone()

        try:
            row = fetch_row(include_permissions=True)
        except Exception as exc:
            if "permissions" not in str(exc).lower():
                raise
            row = fetch_row(include_permissions=False)

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
            "permissions": m.get("permissions") or [],
        }
    except Exception as e:
        logger.error(f"DB _db_find_user: {e}")
        return None


def _login_success(
    user_id: str,
    user_data: dict,
    http_request: Optional[Request] = None,
) -> dict:
    """生成登录成功的标准响应，并记录设备登录信息。"""
    session_id = uuid.uuid4().hex
    token = create_jwt_token(user_id, extra={"sid": session_id})
    refresh_token = create_refresh_token(user_id, extra={"sid": session_id})
    TOKENS_DB[token] = user_id
    register_user_session(user_id, session_id)

    # 设备登录记录
    if http_request is not None:
        try:
            client_ip = _extract_client_ip(http_request)
            device_id = (
                http_request.headers.get("x-device-id")
                or http_request.headers.get("x-device-fingerprint")
                or ""
            )
            user_agent = http_request.headers.get("user-agent", "")

            if device_id or user_agent:
                device_info = track_device_login(
                    user_id=user_id,
                    device_id=device_id,
                    user_agent=user_agent,
                    ip=client_ip,
                )
                # 如果是新设备登录，返回标记
                if device_info.get("is_new_device"):
                    return {
                        "success": True,
                        "token": token,
                        "refresh_token": refresh_token,
                        "expires_in": JWT_ACCESS_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
                        "user": UserResponse(**user_data).model_dump(),
                        "is_new_device": True,
                    }
        except Exception as e:
            logger.warning("device tracking failed: %s", e)

    return {
        "success": True,
        "token": token,
        "refresh_token": refresh_token,
        "expires_in": JWT_ACCESS_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
        "user": UserResponse(**user_data).model_dump(),
    }


def _extract_client_ip(http_request: Request) -> str:
    real_ip = (http_request.headers.get("x-real-ip") or "").strip()
    if real_ip:
        return real_ip

    forwarded_for = (http_request.headers.get("x-forwarded-for") or "").strip()
    if forwarded_for:
        return forwarded_for.rsplit(",", 1)[-1].strip()

    if http_request.client and http_request.client.host:
        return http_request.client.host
    return "unknown"


def _password_login_key(body: LoginRequest) -> str:
    identifier = body.username or body.phone or "unknown"
    return f"{body.type}:{identifier}"


def _is_valid_phone(phone: str) -> bool:
    return bool(PHONE_PATTERN.match((phone or "").strip()))


def _validate_customer_password(password: str) -> None:
    if not PASSWORD_PATTERN.match(password or ""):
        raise HTTPException(
            status_code=400,
            detail="密码需至少8位，且同时包含字母和数字",
        )


def _find_any_user_by_phone(
    phone: str,
    db: Optional[Session],
) -> Optional[dict]:
    if db is not None:
        user_data = _db_find_user(db, phone=phone)
        if user_data is not None:
            return user_data

    if not IS_PRODUCTION:
        for user in USERS_DB.values():
            if user.get("phone") == phone:
                return {**user}
    return None


def _find_customer_user_by_phone(
    phone: str,
    db: Optional[Session],
) -> Optional[dict]:
    if db is not None:
        user_data = _db_find_user(db, phone=phone, user_type="customer")
        if user_data is not None:
            return user_data

    if not IS_PRODUCTION:
        for user in USERS_DB.values():
            if user.get("phone") == phone and user.get("user_type") == "customer":
                return {**user}
    return None


def _build_customer_payload(
    user_id: str,
    phone: str,
    username: str,
    password_hash: str = "",
) -> dict:
    return {
        "id": user_id,
        "phone": phone,
        "username": username,
        "password_hash": password_hash,
        "user_type": "customer",
        "balance": 0.0,
        "points": 0,
        "avatar": None,
        "is_admin": False,
        "permissions": [],
    }


def _create_customer_user(
    phone: str,
    password: str,
    db: Optional[Session],
) -> Optional[dict]:
    if _find_any_user_by_phone(phone, db) is not None:
        raise HTTPException(status_code=409, detail="该手机号已注册，请直接登录")

    user_id = f"u_{uuid.uuid4().hex[:16]}"
    username = f"用户{phone[-4:]}"
    password_hash = hash_password(password)

    if db is not None:
        try:
            db.execute(
                text(
                    "INSERT INTO users(id, phone, username, password_hash, user_type) "
                    "VALUES(:id, :phone, :username, :password_hash, 'customer')"
                ),
                {
                    "id": user_id,
                    "phone": phone,
                    "username": username,
                    "password_hash": password_hash,
                },
            )
            db.commit()
            return _build_customer_payload(
                user_id=user_id,
                phone=phone,
                username=username,
                password_hash=password_hash,
            )
        except HTTPException:
            raise
        except Exception as e:
            db.rollback()
            logger.error(f"DB create customer user failed: {e}")
            if IS_PRODUCTION:
                raise HTTPException(status_code=503, detail="用户服务暂不可用")

    if not IS_PRODUCTION:
        user_data = _build_customer_payload(
            user_id=user_id,
            phone=phone,
            username=username,
            password_hash=password_hash,
        )
        USERS_DB[user_id] = user_data
        return {**user_data}

    return None


def _update_customer_password(
    phone: str,
    password: str,
    db: Optional[Session],
) -> Optional[dict]:
    user_data = _find_customer_user_by_phone(phone, db)
    if user_data is None:
        raise HTTPException(status_code=404, detail="该手机号尚未注册，请先注册账号")

    password_hash = hash_password(password)
    if db is not None:
        try:
            db.execute(
                text(
                    "UPDATE users SET password_hash = :password_hash "
                    "WHERE id = :id AND user_type = 'customer'"
                ),
                {
                    "password_hash": password_hash,
                    "id": user_data["id"],
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB update customer password failed: {e}")
            if IS_PRODUCTION:
                raise HTTPException(status_code=503, detail="用户服务暂不可用")

    if not IS_PRODUCTION:
        user_record = USERS_DB.get(user_data["id"])
        if user_record is not None:
            user_record["password_hash"] = password_hash

    user_data["password_hash"] = password_hash
    return user_data


@router.post("/login")
async def login(
    body: LoginRequest,
    http_request: Request,
    db: Optional[Session] = Depends(get_db),
):
    is_customer_sms = (
        getattr(body, "login_type", None) == "customer_sms"
        or body.type == "customer_sms"
    )
    client_ip = _extract_client_ip(http_request)
    password_login_key = _password_login_key(body)

    def reject_password_login(status_code: int, detail: str):
        record_login_failure(client_ip, password_login_key)
        raise HTTPException(status_code=status_code, detail=detail)

    if not is_customer_sms:
        ensure_login_allowed(client_ip, password_login_key)

    # 用户登录入口：管理员 / 操作员 / 客户短信登录。

    # ---- 管理员登录 ----
    if body.type == "admin":
        user_data = None

        # DB first
        if db is not None:
            user_data = _db_find_user(db, phone=body.username, user_type="admin")

        # Memory fallback
        if user_data is None and not IS_PRODUCTION:
            admin = USERS_DB.get("admin_001")
            if admin and body.username == admin.get("phone"):
                user_data = {**admin}

        if user_data is None:
            reject_password_login(401, "用户名或密码错误")

        if not verify_password(body.password or "", user_data.get("password_hash", "")):
            reject_password_login(401, "用户名或密码错误")

        if not body.captcha or body.captcha != "8888":
            reject_password_login(400, "验证码错误")

        clear_login_failures(client_ip, password_login_key)
        return _login_success(user_data["id"], user_data, http_request=http_request)

    # ---- 操作员登录 ----
    elif body.type == "operator" and not is_customer_sms:
        user_data = None

        # Try DB first — by operator_num or username
        if db is not None:
            try:
                op_num = int(body.username) if body.username else 0
                if 1 <= op_num <= 999:
                    user_data = _db_find_user(db, operator_num=op_num, user_type="operator")
            except (ValueError, TypeError):
                pass
            if user_data is None:
                user_data = _db_find_user(db, username=body.username, user_type="operator")

        # Memory fallback
        if user_data is None and not IS_PRODUCTION:
            operator_id = None
            try:
                op_num = int(body.username) if body.username else 0
                if 1 <= op_num <= 10:
                    operator_id = f"operator_{op_num}"
            except (ValueError, TypeError):
                for uid, user in USERS_DB.items():
                    if (
                        user.get("username") == body.username
                        and user.get("is_active", True)
                    ):
                        operator_id = uid
                        break

            if (
                operator_id
                and operator_id in USERS_DB
                and USERS_DB[operator_id].get("is_active", True)
            ):
                user_data = {**USERS_DB[operator_id]}

        if user_data and verify_password(body.password or "", user_data.get("password_hash", "")):
            clear_login_failures(client_ip, password_login_key)
            return _login_success(user_data["id"], user_data, http_request=http_request)

    # ---- 客户密码登录 ----
    elif body.type == "customer" and not is_customer_sms:
        phone = (body.phone or "").strip()
        password = body.password or ""

        if not _is_valid_phone(phone):
            raise HTTPException(status_code=400, detail="手机号格式错误")
        if not password:
            raise HTTPException(status_code=400, detail="密码不能为空")

        # 图形验证码校验
        if body.captcha_session_id and body.captcha:
            if not verify_captcha(body.captcha_session_id, body.captcha):
                reject_password_login(400, "login_captcha_error")

        user_data = _find_customer_user_by_phone(phone, db)
        if user_data is None:
            reject_password_login(401, "手机号或密码错误")

        if not verify_password(password, user_data.get("password_hash", "")):
            reject_password_login(401, "手机号或密码错误")

        clear_login_failures(client_ip, password_login_key)
        return _login_success(user_data["id"], user_data, http_request=http_request)

    # ---- 客户短信登录 (旧路径兼容) ----
    if is_customer_sms:
        if not body.phone or not body.code:
            raise HTTPException(status_code=400, detail="手机号和验证码不能为空")

        if not _is_valid_phone(body.phone):
            raise HTTPException(status_code=400, detail="手机号格式错误")

        # 使用 sms_service 校验验证码
        verify_stored_code(body.phone, body.code, action="login")

        user_data = _find_customer_user_by_phone(body.phone, db)
        if user_data is None:
            raise HTTPException(status_code=404, detail="该手机号尚未注册，请先注册账号")

        return _login_success(user_data["id"], user_data, http_request=http_request)

    reject_password_login(401, "用户名或密码错误")


@router.post("/send-sms")
async def send_sms_code(
    body: SmsCodeRequest,
    request: Request,
    db: Optional[Session] = Depends(get_db),
):
    """发送短信验证码（含 Redis 限流）"""
    if not _is_valid_phone(body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    existing_user = _find_any_user_by_phone(body.phone, db)
    if body.action == "register" and existing_user is not None:
        raise HTTPException(status_code=409, detail="该手机号已注册，请直接登录")

    if body.action in {"login", "reset"}:
        customer_user = _find_customer_user_by_phone(body.phone, db)
        if customer_user is None:
            raise HTTPException(status_code=404, detail="该手机号尚未注册，请先注册账号")

    code = generate_and_store_code(body.phone, action=body.action)

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
    """校验短信验证码；登录场景返回 JWT，注册/重置场景只返回校验结果"""
    if not _is_valid_phone(body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    # ---- 验证码校验 ----
    verify_stored_code(body.phone, body.code, action=body.action)

    if body.action != "login":
        return {"success": True, "message": "验证码验证成功"}

    user_data = _find_customer_user_by_phone(body.phone, db)
    if user_data is None:
        raise HTTPException(status_code=404, detail="该手机号尚未注册，请先注册账号")

    return _login_success(user_data["id"], user_data)


@router.post("/register")
async def register_customer(
    body: RegisterRequest,
    http_request: Request,
    db: Optional[Session] = Depends(get_db),
):
    """用户注册：手机号 + 短信验证码 + 密码 + 图形验证码"""
    if not _is_valid_phone(body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    if body.password != body.confirm_password:
        raise HTTPException(status_code=400, detail="两次输入的密码不一致")

    if not body.accept_terms:
        raise HTTPException(status_code=400, detail="请先阅读并同意用户协议与隐私政策")

    # 图形验证码校验
    if body.captcha_session_id and body.captcha:
        if not verify_captcha(body.captcha_session_id, body.captcha):
            raise HTTPException(status_code=400, detail="login_captcha_error")

    _validate_customer_password(body.password)
    verify_stored_code(body.phone, body.code, action="register")

    user_data = _create_customer_user(body.phone, body.password, db)
    if user_data is None:
        raise HTTPException(status_code=503, detail="用户服务暂不可用")

    return _login_success(user_data["id"], user_data, http_request=http_request)


@router.post("/reset-password")
async def reset_customer_password(
    body: ResetPasswordRequest,
    http_request: Request,
    db: Optional[Session] = Depends(get_db),
):
    """重置客户密码：手机号 + 短信验证码 + 新密码"""
    if not _is_valid_phone(body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    if body.password != body.confirm_password:
        raise HTTPException(status_code=400, detail="两次输入的密码不一致")

    _validate_customer_password(body.password)
    verify_stored_code(body.phone, body.code, action="reset")

    user_data = _update_customer_password(body.phone, body.password, db)
    if user_data is None:
        raise HTTPException(status_code=503, detail="用户服务暂不可用")

    revoke_all_user_sessions(user_data["id"])
    return _login_success(user_data["id"], user_data, http_request=http_request)


@router.post("/logout")
async def logout(authorization: AuthorizationDep = None):
    """用户登出"""
    token = extract_bearer_token(authorization or "")
    if token:
        revoke_session_for_token(token)
        TOKENS_DB.pop(token, None)
    return {"success": True, "message": "已退出登录"}


@router.post("/refresh")
async def refresh_token(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """刷新Token"""
    user_id = get_user_id_from_refresh_token(authorization or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="Refresh Token无效")
    if not get_user_record(user_id, db):
        raise HTTPException(status_code=401, detail="Refresh Token无效")

    old_token = extract_bearer_token(authorization or "")
    revoke_session_for_token(old_token)
    session_id = uuid.uuid4().hex
    register_user_session(user_id, session_id)

    new_token = create_jwt_token(user_id, extra={"sid": session_id})
    new_refresh_token = create_refresh_token(user_id, extra={"sid": session_id})
    TOKENS_DB[new_token] = user_id

    TOKENS_DB.pop(old_token, None)

    return {
        "token": new_token,
        "refresh_token": new_refresh_token,
        "expires_in": JWT_ACCESS_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
    }


# ── 图形验证码 ──────────────────────────────────────────────────────────

@router.get("/captcha")
async def get_captcha(session_id: str):
    """获取图形验证码。

    前端需先生成一个 UUID 作为 session_id，然后调用此接口获取验证码图片。
    登录时需同时传递 session_id 和用户输入的 captcha。
    """
    if not session_id or len(session_id) < 8:
        raise HTTPException(status_code=400, detail="session_id 格式不正确")
    return generate_captcha(session_id)


# ── 设备管理 ──────────────────────────────────────────────────────────

@router.get("/devices")
async def list_devices(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """获取当前用户的登录设备列表。"""
    user_id = require_user(authorization)
    devices = get_user_devices(user_id)
    return {"success": True, "devices": devices}


@router.delete("/devices/{device_fingerprint}")
async def remove_device(
    device_fingerprint: str,
    authorization: AuthorizationDep = None,
):
    """移除指定设备。"""
    user_id = require_user(authorization)
    from services.device_tracker import remove_device as _remove_device
    result = _remove_device(user_id, device_fingerprint)
    return {"success": result, "message": "已移除该设备" if result else "设备不存在"}


@router.post("/devices/logout-others")
async def logout_other_devices(
    authorization: AuthorizationDep = None,
):
    """退出其他所有设备。"""
    token = extract_bearer_token(authorization or "")
    if not token:
        raise HTTPException(status_code=401, detail="未授权")
    user_id = require_user(authorization)
    from services.device_tracker import logout_other_devices as _logout_others
    count = _logout_others(user_id, current_token=token)
    return {"success": True, "message": f"已退出 {count} 台其他设备"}
