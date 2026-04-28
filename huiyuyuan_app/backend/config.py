"""Backend configuration loaded from environment variables."""

import hashlib
import logging
import os
import secrets
from pathlib import Path
from urllib.parse import urlparse

try:
    from dotenv import load_dotenv

    _backend_env = Path(__file__).resolve().with_name(".env")
    _project_env = Path(__file__).resolve().parent.parent / ".env"
    load_dotenv(_project_env)
    load_dotenv(_backend_env)
except ImportError:
    pass

logger = logging.getLogger(__name__)


def _parse_bool(value: str, default: bool = False) -> bool:
    normalized = (value or "").strip().lower()
    if not normalized:
        return default
    return normalized in ("true", "1", "yes", "on")

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


def _normalize_host(raw_host: str) -> str:
    value = (raw_host or "").strip()
    if not value:
        return ""

    if "://" in value:
        parsed = urlparse(value)
        return (parsed.hostname or "").strip().lower()

    # TrustedHostMiddleware matches against host names rather than full URLs.
    if value.startswith("[") and "]" in value:
        host_part = value[1:value.index("]")]
    else:
        host_part = value.split(":", 1)[0]
    return host_part.strip().lower()


def _load_allowed_hosts() -> list[str]:
    raw_value = os.getenv("ALLOWED_HOSTS", "").strip()
    if raw_value:
        hosts = [_normalize_host(host) for host in raw_value.split(",")]
    elif ALLOWED_ORIGINS == ["*"]:
        hosts = ["*"]
    else:
        hosts = [_normalize_host(origin) for origin in ALLOWED_ORIGINS]

    hosts = [host for host in hosts if host]
    if "*" in hosts:
        if IS_PRODUCTION:
            raise RuntimeError("ALLOWED_HOSTS cannot contain * in production.")
        return ["*"]

    # Keep local health checks working even when the backend is protected
    # behind Nginx and only probed via 127.0.0.1 or localhost on the server.
    normalized: list[str] = []
    for host in hosts + ["127.0.0.1", "localhost"]:
        if host not in normalized:
            normalized.append(host)

    if not normalized:
        if IS_PRODUCTION:
            raise RuntimeError(
                "ALLOWED_HOSTS must be configured in production or derivable "
                "from ALLOWED_ORIGINS."
            )
        return ["*"]

    return normalized


ALLOWED_HOSTS = _load_allowed_hosts()
LOGIN_FAILURE_WINDOW_SECONDS = int(
    os.getenv("LOGIN_FAILURE_WINDOW_SECONDS", "900")
)
LOGIN_CREDENTIAL_FAILURE_LIMIT = int(
    os.getenv("LOGIN_CREDENTIAL_FAILURE_LIMIT", "8")
)
LOGIN_IP_FAILURE_LIMIT = int(os.getenv("LOGIN_IP_FAILURE_LIMIT", "20"))

# Aliyun SMS
ALIYUN_AK_ID = os.getenv("ALIYUN_ACCESS_KEY_ID", "")
ALIYUN_AK_SECRET = os.getenv("ALIYUN_ACCESS_KEY_SECRET", "")
SMS_SIGN_NAME = os.getenv("SMS_SIGN_NAME", "汇玉源")
SMS_TEMPLATE_CODE = os.getenv("SMS_TEMPLATE_CODE", "")
SMS_REAL_MODE = bool(ALIYUN_AK_ID and ALIYUN_AK_SECRET and SMS_TEMPLATE_CODE)

# Aliyun OSS
OSS_AK_ID = os.getenv("OSS_ACCESS_KEY_ID", "")
OSS_AK_SECRET = os.getenv("OSS_ACCESS_KEY_SECRET", "")
OSS_BUCKET = os.getenv("OSS_BUCKET", "huiyuyuan-images")
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


def _load_release_notes() -> list[str]:
    raw_value = os.getenv("APP_RELEASE_NOTES", "").strip()
    if raw_value:
        return [item.strip() for item in raw_value.split("|") if item.strip()]

    return [
        "管理员支持自定义角色模板保存、重命名与删除，整理权限更高效",
        "新增独立支付对账工作台，确认到账与异常标记可按权限拆分授权",
        "继续收紧管理员与操作员权限边界，并修复对账相关中英文混用文案",
    ]


def _load_download_urls(
    primary_env: str,
    list_env: str,
    default_url: str = "",
) -> list[str]:
    raw_values: list[str] = []
    raw_list = os.getenv(list_env, "").strip()
    raw_primary = os.getenv(primary_env, "").strip()

    if raw_list:
        raw_values.extend(raw_list.split("|"))
    if raw_primary:
        raw_values.append(raw_primary)
    if not raw_values and default_url:
        raw_values.append(default_url)

    normalized: list[str] = []
    for raw in raw_values:
        value = raw.strip()
        if value and value not in normalized:
            normalized.append(value)
    return normalized


def _compute_file_metadata(file_path: str) -> tuple[int | None, str]:
    path = Path(file_path)
    if not path.exists() or not path.is_file():
        return None, ""

    size_bytes = path.stat().st_size
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return size_bytes, digest.hexdigest()


APP_LATEST_VERSION = os.getenv("APP_LATEST_VERSION", "3.0.4").strip() or "3.0.4"
APP_LATEST_BUILD_NUMBER = int(os.getenv("APP_LATEST_BUILD_NUMBER", "6"))
APP_MIN_SUPPORTED_BUILD_NUMBER = int(
    os.getenv("APP_MIN_SUPPORTED_BUILD_NUMBER", "2")
)
APP_FORCE_UPDATE = _parse_bool(os.getenv("APP_FORCE_UPDATE", "false"))
APP_RELEASE_NOTES = _load_release_notes()
APP_RELEASED_AT = (
    os.getenv("APP_RELEASED_AT", "2026-04-16T11:10:00+08:00").strip()
    or "2026-04-16T11:10:00+08:00"
)
APP_ANDROID_DOWNLOAD_URLS = _load_download_urls(
    primary_env="APP_ANDROID_DOWNLOAD_URL",
    list_env="APP_ANDROID_DOWNLOAD_URLS",
    default_url="https://xn--lsws2cdzg.top/downloads/huiyuyuan-latest.apk",
)
APP_ANDROID_DOWNLOAD_URL = APP_ANDROID_DOWNLOAD_URLS[0] if APP_ANDROID_DOWNLOAD_URLS else ""
APP_IOS_DOWNLOAD_URL = os.getenv("APP_IOS_DOWNLOAD_URL", "").strip()
APP_WEB_DOWNLOAD_URL = (
    os.getenv("APP_WEB_DOWNLOAD_URL", "https://xn--lsws2cdzg.top").strip()
)
APP_ANDROID_DOWNLOAD_FILE_PATH = os.getenv(
    "APP_ANDROID_DOWNLOAD_FILE_PATH",
    "/var/www/huiyuyuan/downloads/huiyuyuan-latest.apk",
).strip()
APP_ANDROID_DOWNLOAD_CONTENT_TYPE = os.getenv(
    "APP_ANDROID_DOWNLOAD_CONTENT_TYPE",
    "application/vnd.android.package-archive",
).strip() or "application/vnd.android.package-archive"
APP_ANDROID_DOWNLOAD_SIZE_BYTES = (
    int(os.getenv("APP_ANDROID_DOWNLOAD_SIZE_BYTES", "").strip())
    if os.getenv("APP_ANDROID_DOWNLOAD_SIZE_BYTES", "").strip()
    else None
)
APP_ANDROID_DOWNLOAD_SHA256 = (
    os.getenv("APP_ANDROID_DOWNLOAD_SHA256", "").strip().lower()
    or ""
)

_ANDROID_DOWNLOAD_METADATA_CACHE_KEY: tuple[str, int, int] | None = None
_ANDROID_DOWNLOAD_METADATA_CACHE_VALUE: tuple[int | None, str] = (
    APP_ANDROID_DOWNLOAD_SIZE_BYTES,
    APP_ANDROID_DOWNLOAD_SHA256,
)


def get_android_download_metadata() -> tuple[int | None, str]:
    size_override = APP_ANDROID_DOWNLOAD_SIZE_BYTES
    sha_override = APP_ANDROID_DOWNLOAD_SHA256
    if size_override is not None and sha_override:
        return size_override, sha_override

    path = Path(APP_ANDROID_DOWNLOAD_FILE_PATH)
    if not path.exists() or not path.is_file():
        return size_override, sha_override

    stat = path.stat()
    cache_key = (
        str(path.resolve()),
        stat.st_size,
        getattr(stat, "st_mtime_ns", int(stat.st_mtime * 1_000_000_000)),
    )

    global _ANDROID_DOWNLOAD_METADATA_CACHE_KEY
    global _ANDROID_DOWNLOAD_METADATA_CACHE_VALUE
    if cache_key != _ANDROID_DOWNLOAD_METADATA_CACHE_KEY:
        computed_size, computed_sha256 = _compute_file_metadata(APP_ANDROID_DOWNLOAD_FILE_PATH)
        _ANDROID_DOWNLOAD_METADATA_CACHE_KEY = cache_key
        _ANDROID_DOWNLOAD_METADATA_CACHE_VALUE = (
            size_override if size_override is not None else computed_size,
            sha_override or computed_sha256,
        )

    return _ANDROID_DOWNLOAD_METADATA_CACHE_VALUE

# Uploads
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
