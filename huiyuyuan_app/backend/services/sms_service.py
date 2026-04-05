"""
短信服务 — 阿里云短信 + Redis 限流
安全修复: Redis 不可用时拒绝发送（返回 503），不再使用固定 8888
"""

import json
import logging
import random
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException

from config import (
    ALIYUN_AK_ID,
    ALIYUN_AK_SECRET,
    SMS_SIGN_NAME,
    SMS_TEMPLATE_CODE,
    SMS_REAL_MODE,
    APP_ENV,
)
from database import redis_client, REDIS_AVAILABLE

logger = logging.getLogger(__name__)
SMS_ALLOWED_ACTIONS = {"login", "register", "reset"}


# ---- Redis key helpers ----
def _normalize_action(action: str) -> str:
    normalized = (action or "login").strip().lower()
    if normalized not in SMS_ALLOWED_ACTIONS:
        raise HTTPException(status_code=400, detail="短信验证码动作不支持")
    return normalized


def _sms_code_key(phone: str, action: str) -> str:
    return f"sms:code:{action}:{phone}"


def _sms_cool_key(phone: str) -> str:
    return f"sms:cool:{phone}"


def _sms_day_key(phone: str) -> str:
    return f"sms:day:{phone}:{datetime.now(timezone.utc).strftime('%Y%m%d')}"


def _sms_err_key(phone: str, action: str) -> str:
    return f"sms:err:{action}:{phone}"


def send_aliyun_sms(phone: str, code: str) -> dict:
    """调用阿里云短信发送接口"""
    try:
        from aliyunsdkcore.client import AcsClient
        from aliyunsdkcore.request import CommonRequest

        client = AcsClient(ALIYUN_AK_ID, ALIYUN_AK_SECRET, "cn-hangzhou")
        req = CommonRequest()
        req.set_accept_format("json")
        req.set_domain("dysmsapi.aliyuncs.com")
        req.set_method("POST")
        req.set_protocol_type("https")
        req.set_version("2017-05-25")
        req.set_action_name("SendSms")
        req.add_query_param("RegionId", "cn-hangzhou")
        req.add_query_param("PhoneNumbers", phone)
        req.add_query_param("SignName", SMS_SIGN_NAME)
        req.add_query_param("TemplateCode", SMS_TEMPLATE_CODE)
        req.add_query_param("TemplateParam", json.dumps({"code": code}))
        resp = json.loads(client.do_action_with_exception(req))
        ok = resp.get("Code") == "OK"
        return {
            "success": ok,
            "biz_id": resp.get("BizId", ""),
            "message": resp.get("Message", ""),
        }
    except Exception as e:
        return {"success": False, "biz_id": "", "message": str(e)}


def generate_and_store_code(phone: str, action: str = "login") -> str:
    """生成验证码并存入 Redis（含限流），返回验证码

    安全修复: Redis 不可用时
      - 生产环境: 拒绝发送 (503)
      - 开发环境: 返回固定 888888 (仅用于本地开发)
    """
    action = _normalize_action(action)
    code = str(random.randint(100000, 999999))

    if REDIS_AVAILABLE and redis_client:
        # 60 秒冷却
        if redis_client.exists(_sms_cool_key(phone)):
            ttl = redis_client.ttl(_sms_cool_key(phone))
            raise HTTPException(
                status_code=429, detail=f"发送太频繁，请 {ttl} 秒后重试"
            )
        # 每日上限 10 次
        day_count = int(redis_client.get(_sms_day_key(phone)) or 0)
        if day_count >= 10:
            raise HTTPException(
                status_code=429, detail="今日发送次数已达上限（10次）"
            )
        # 存储验证码 5 分钟有效
        redis_client.setex(_sms_code_key(phone, action), 300, code)
        redis_client.setex(_sms_cool_key(phone), 60, "1")
        redis_client.incr(_sms_day_key(phone))
        redis_client.expire(_sms_day_key(phone), 86400)
        redis_client.delete(_sms_err_key(phone, action))
        return code

    # Redis 不可用
    if APP_ENV == "production":
        raise HTTPException(
            status_code=503,
            detail="验证码服务暂不可用，请稍后重试",
        )

    # 仅开发环境降级
    logger.warning(f"??  Redis 不可用，开发环境使用固定验证码 888888")
    return "888888"


def verify_stored_code(phone: str, code: str, action: str = "login") -> bool:
    """校验 Redis 中存储的验证码，成功后删除（一次性）

    Returns True 表示验证通过
    Raises HTTPException 表示验证失败
    """
    action = _normalize_action(action)
    if REDIS_AVAILABLE and redis_client:
        err_count = int(redis_client.get(_sms_err_key(phone, action)) or 0)
        if err_count >= 5:
            raise HTTPException(
                status_code=429, detail="错误次数过多，请重新获取验证码"
            )

        stored = redis_client.get(_sms_code_key(phone, action))
        if not stored:
            raise HTTPException(
                status_code=400, detail="验证码已过期或未发送"
            )
        if stored != code:
            redis_client.incr(_sms_err_key(phone, action))
            redis_client.expire(_sms_err_key(phone, action), 1800)
            raise HTTPException(status_code=400, detail="验证码错误")

        # 验证成功：删除验证码（一次性）
        redis_client.delete(_sms_code_key(phone, action))
        redis_client.delete(_sms_err_key(phone, action))
        return True

    # Redis 不可用降级: 开发环境接受 888888 或手机后4位
    if APP_ENV == "production":
        raise HTTPException(
            status_code=503,
            detail="验证码服务暂不可用，请稍后重试",
        )

    expected = phone[-4:] if len(phone) >= 4 else phone
    if code not in ("888888", expected):
        raise HTTPException(status_code=400, detail="验证码错误")
    return True
