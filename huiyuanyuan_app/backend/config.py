"""Backend configuration loaded from environment variables."""

import logging
import os
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

# Application
APP_ENV = os.getenv("APP_ENV", "development").strip().lower()
DEBUG = os.getenv("DEBUG", "true").lower() in ("true", "1", "yes")
IS_PRODUCTION = APP_ENV == "production"

# Database
DATABASE_URL = os.getenv("DATABASE_URL", "")

# Redis
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")


def _load_jwt_secret() -> str:
    secret = os.getenv("JWT_SECRET_KEY", "").strip()
    if secret:
        return secret

    if IS_PRODUCTION:
        raise RuntimeError(
            "JWT_SECRET_KEY is required in production. "
            "Generate one with: python -c \"import secrets; print(secrets.token_hex(32))\""
        )

    fallback = "dev_only_" + secrets.token_hex(16)
    logger.warning(
        "JWT_SECRET_KEY is not configured; using a temporary development secret."
    )
    return fallback


JWT_SECRET_KEY = _load_jwt_secret()
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_EXPIRE_SECONDS = int(os.getenv("JWT_ACCESS_EXPIRE_MINUTES", "120")) * 60
JWT_REFRESH_EXPIRE_DAYS = int(os.getenv("JWT_REFRESH_EXPIRE_DAYS", "7"))


def _load_allowed_origins() -> list[str]:
    raw_value = os.getenv("ALLOWED_ORIGINS", "").strip()
    if not raw_value:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_ORIGINS must be configured in production.")
        logger.warning("ALLOWED_ORIGINS is not configured; allowing all origins in dev.")
        return ["*"]

    origins = [origin.strip() for origin in raw_value.split(",") if origin.strip()]
    if not origins:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_ORIGINS did not contain any valid origins.")
        return ["*"]

    if "*" in origins:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_ORIGINS cannot contain * in production.")
        return ["*"]

    normalized: list[str] = []
    for origin in origins:
        if origin not in normalized:
            normalized.append(origin)
    return normalized


ALLOWED_ORIGINS = _load_allowed_origins()

# Aliyun SMS
ALIYUN_AK_ID = os.getenv("ALIYUN_ACCESS_KEY_ID", "")
ALIYUN_AK_SECRET = os.getenv("ALIYUN_ACCESS_KEY_SECRET", "")
SMS_SIGN_NAME = os.getenv("SMS_SIGN_NAME", "汇玉源")
SMS_TEMPLATE_CODE = os.getenv("SMS_TEMPLATE_CODE", "")
SMS_REAL_MODE = bool(ALIYUN_AK_ID and ALIYUN_AK_SECRET and SMS_TEMPLATE_CODE)

# Aliyun OSS
OSS_AK_ID = os.getenv("OSS_ACCESS_KEY_ID", "")
OSS_AK_SECRET = os.getenv("OSS_ACCESS_KEY_SECRET", "")
OSS_BUCKET = os.getenv("OSS_BUCKET", "huiyuanyuan-images")
OSS_ENDPOINT = os.getenv("OSS_ENDPOINT", "oss-cn-hangzhou.aliyuncs.com")
OSS_REGION = os.getenv("OSS_REGION", "cn-hangzhou")
OSS_AVAILABLE = bool(OSS_AK_ID and OSS_AK_SECRET)

# AI
def _load_dashscope_api_key() -> tuple[str, str | None]:
    primary = os.getenv("DASHSCOPE_API_KEY", "").strip()
    legacy = os.getenv("OPENROUTER_API_KEY", "").strip()
    key = primary or legacy

    if not key:
        return "", None

    if key.startswith("sk-or-"):
        issue = (
            "DASHSCOPE_API_KEY appears to be an OpenRouter key. "
            "Provide a DashScope key that starts with sk-."
        )
        logger.warning(issue)
        return "", issue

    if not key.startswith("sk-"):
        issue = "DASHSCOPE_API_KEY must start with sk-."
        logger.warning(issue)
        return "", issue

    return key, None


DASHSCOPE_API_KEY, DASHSCOPE_API_KEY_ISSUE = _load_dashscope_api_key()
DASHSCOPE_BASE_URL = os.getenv(
    "DASHSCOPE_BASE_URL",
    "https://dashscope.aliyuncs.com/compatible-mode/v1",
).strip()
DASHSCOPE_VISION_MODEL = os.getenv(
    "DASHSCOPE_VISION_MODEL",
    "qwen-vl-plus-latest",
).strip()

# Uploads
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
