"""
汇玉源后端配置 — 所有配置从环境变量读取
生产环境强制必填项 (JWT_SECRET_KEY)
"""

import os
import logging
import secrets
from pathlib import Path

try:
    from dotenv import load_dotenv

    _backend_env = Path(__file__).resolve().with_name(".env")
    _project_env = Path(__file__).resolve().parent.parent / ".env"
    load_dotenv(_project_env)
    load_dotenv(_backend_env)
except ImportError:
    pass

logger = logging.getLogger(__name__)

# ============ 应用 ============
APP_ENV = os.getenv("APP_ENV", "development").strip().lower()
DEBUG = os.getenv("DEBUG", "true").lower() in ("true", "1", "yes")
IS_PRODUCTION = APP_ENV == "production"

# ============ 数据库 ============
DATABASE_URL = os.getenv("DATABASE_URL", "")

# ============ Redis ============
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# ============ JWT ============
def _load_jwt_secret() -> str:
    secret = os.getenv("JWT_SECRET_KEY", "").strip()
    if secret:
        return secret

    if IS_PRODUCTION:
        raise RuntimeError(
            "JWT_SECRET_KEY 未设置。生产环境必须显式配置。\n"
            "生成方式: python -c \"import secrets; print(secrets.token_hex(32))\""
        )

    fallback = "dev_only_" + secrets.token_hex(16)
    logger.warning("JWT_SECRET_KEY 未配置，使用临时开发密钥；服务重启后会失效。")
    return fallback


JWT_SECRET_KEY = _load_jwt_secret()
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_EXPIRE_SECONDS = int(os.getenv("JWT_ACCESS_EXPIRE_MINUTES", "120")) * 60
JWT_REFRESH_EXPIRE_DAYS = int(os.getenv("JWT_REFRESH_EXPIRE_DAYS", "7"))

# ============ CORS ============
def _load_allowed_origins() -> list[str]:
    raw_value = os.getenv("ALLOWED_ORIGINS", "").strip()
    if not raw_value:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_ORIGINS 未设置。生产环境必须显式配置白名单。")
        logger.warning("ALLOWED_ORIGINS 未配置，开发环境放宽为 *。")
        return ["*"]

    origins = [origin.strip() for origin in raw_value.split(",") if origin.strip()]
    if not origins:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_ORIGINS 未设置有效来源。")
        return ["*"]

    if "*" in origins:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_ORIGINS 不能在生产环境使用通配符 *。")
        return ["*"]

    normalized: list[str] = []
    for origin in origins:
        if origin not in normalized:
            normalized.append(origin)
    return normalized


ALLOWED_ORIGINS = _load_allowed_origins()

# ============ 阿里云短信 ============
ALIYUN_AK_ID = os.getenv("ALIYUN_ACCESS_KEY_ID", "")
ALIYUN_AK_SECRET = os.getenv("ALIYUN_ACCESS_KEY_SECRET", "")
SMS_SIGN_NAME = os.getenv("SMS_SIGN_NAME", "汇玉源")
SMS_TEMPLATE_CODE = os.getenv("SMS_TEMPLATE_CODE", "")
SMS_REAL_MODE = bool(ALIYUN_AK_ID and ALIYUN_AK_SECRET and SMS_TEMPLATE_CODE)

# ============ 阿里云 OSS ============
OSS_AK_ID = os.getenv("OSS_ACCESS_KEY_ID", "")
OSS_AK_SECRET = os.getenv("OSS_ACCESS_KEY_SECRET", "")
OSS_BUCKET = os.getenv("OSS_BUCKET", "huiyuanyuan-images")
OSS_ENDPOINT = os.getenv("OSS_ENDPOINT", "oss-cn-hangzhou.aliyuncs.com")
OSS_REGION = os.getenv("OSS_REGION", "cn-hangzhou")
OSS_AVAILABLE = bool(OSS_AK_ID and OSS_AK_SECRET)

# ============ AI ============
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
OPENROUTER_MODEL = os.getenv(
    "OPENROUTER_MODEL",
    "nvidia/nemotron-nano-12b-v2-vl:free",
)
OPENROUTER_SITE_URL = os.getenv("OPENROUTER_SITE_URL", "https://huiyuanyuan.local")
OPENROUTER_APP_NAME = os.getenv("OPENROUTER_APP_NAME", "汇玉源")

# ============ 上传目录 ============
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
