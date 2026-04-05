"""Password-login throttling helpers."""

import hashlib
import logging
import time

from fastapi import HTTPException

from config import (
    LOGIN_CREDENTIAL_FAILURE_LIMIT,
    LOGIN_FAILURE_WINDOW_SECONDS,
    LOGIN_IP_FAILURE_LIMIT,
)
from database import REDIS_AVAILABLE, redis_client


logger = logging.getLogger(__name__)
_MEMORY_FAILURES: dict[str, tuple[int, float]] = {}


def _safe_identifier(value: str) -> str:
    normalized = (value or "unknown").strip().lower()
    if not normalized:
        normalized = "unknown"
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()
    return digest[:32]


def _ip_key(client_ip: str) -> str:
    return f"auth:login:ip:{client_ip or 'unknown'}"


def _credential_key(client_ip: str, credential: str) -> str:
    return f"auth:login:credential:{client_ip or 'unknown'}:{_safe_identifier(credential)}"


def _throttle_error() -> HTTPException:
    return HTTPException(
        status_code=429,
        detail="登录失败次数过多，请稍后 15 分钟再试",
    )


def _memory_get(key: str) -> int:
    record = _MEMORY_FAILURES.get(key)
    if not record:
        return 0

    count, expires_at = record
    if expires_at <= time.time():
        _MEMORY_FAILURES.pop(key, None)
        return 0
    return count


def _memory_increment(key: str) -> None:
    current = _memory_get(key)
    _MEMORY_FAILURES[key] = (
        current + 1,
        time.time() + LOGIN_FAILURE_WINDOW_SECONDS,
    )


def _memory_delete(key: str) -> None:
    _MEMORY_FAILURES.pop(key, None)


def _redis_count(key: str) -> int:
    if not (REDIS_AVAILABLE and redis_client):
        return 0
    return int(redis_client.get(key) or 0)


def _redis_increment(key: str) -> None:
    if not (REDIS_AVAILABLE and redis_client):
        return
    next_value = redis_client.incr(key)
    if next_value == 1:
        redis_client.expire(key, LOGIN_FAILURE_WINDOW_SECONDS)


def _redis_delete(key: str) -> None:
    if REDIS_AVAILABLE and redis_client:
        redis_client.delete(key)


def ensure_login_allowed(client_ip: str, credential: str) -> None:
    ip_key = _ip_key(client_ip)
    credential_key = _credential_key(client_ip, credential)

    ip_failures = _redis_count(ip_key) if REDIS_AVAILABLE and redis_client else _memory_get(ip_key)
    if ip_failures >= LOGIN_IP_FAILURE_LIMIT:
        raise _throttle_error()

    credential_failures = (
        _redis_count(credential_key)
        if REDIS_AVAILABLE and redis_client
        else _memory_get(credential_key)
    )
    if credential_failures >= LOGIN_CREDENTIAL_FAILURE_LIMIT:
        raise _throttle_error()


def record_login_failure(client_ip: str, credential: str) -> None:
    ip_key = _ip_key(client_ip)
    credential_key = _credential_key(client_ip, credential)

    if REDIS_AVAILABLE and redis_client:
        _redis_increment(ip_key)
        _redis_increment(credential_key)
        return

    _memory_increment(ip_key)
    _memory_increment(credential_key)
    logger.warning("login throttling is using in-memory fallback for %s", client_ip)


def clear_login_failures(client_ip: str, credential: str) -> None:
    credential_key = _credential_key(client_ip, credential)

    if REDIS_AVAILABLE and redis_client:
        _redis_delete(credential_key)
        return

    _memory_delete(credential_key)
