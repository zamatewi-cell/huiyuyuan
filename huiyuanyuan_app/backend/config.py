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
APP_ENV = os.getenv("APP_ENV", "development")
DEBUG = os.getenv("DEBUG", "true").lower() in ("true", "1", "yes")

# ============ 数据库 ============
DATABASE_URL = os.getenv("DATABASE_URL", "")

# ============ Redis ============
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# ============ JWT ============
_jwt_secret = os.getenv("JWT_SECRET_KEY", "")
if not _jwt_secret:
    if APP_ENV == "production":
        raise RuntimeError(
            "? JWT_SECRET_KEY 未设置！生产环境必须配置。\n"
            "   生成方式: python -c \"import secrets; print(secrets.token_hex(32))\""
        )
    _jwt_secret = "dev_only_" + secrets.token_hex(16)
    logger.warning("??  JWT_SECRET_KEY 未配置，使用随机开发密钥（重启失效）")

JWT_SECRET_KEY = _jwt_secret
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_EXPIRE_SECONDS = int(os.getenv("JWT_ACCESS_EXPIRE_MINUTES", "120")) * 60
JWT_REFRESH_EXPIRE_DAYS = int(os.getenv("JWT_REFRESH_EXPIRE_DAYS", "7"))

# ============ CORS ============
_origins_raw = os.getenv("ALLOWED_ORIGINS", "")
if _origins_raw and _origins_raw != "*":
    ALLOWED_ORIGINS: list[str] = [o.strip() for o in _origins_raw.split(",") if o.strip()]
else:
    if APP_ENV == "production":
        ALLOWED_ORIGINS = [
            "http://47.112.98.191",
            "https://47.112.98.191",
        ]
        logger.warning("??  ALLOWED_ORIGINS 未配置，默认仅允许服务器 IP")
    else:
        ALLOWED_ORIGINS = ["*"]

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
