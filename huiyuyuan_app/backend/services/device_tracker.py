"""设备登录记录与会话管理服务。

记录每次成功登录的设备和 IP 信息，提供查询和主动退出其他设备的能力。
"""

import hashlib
import logging
import time
from typing import Optional

from config import APP_ENV, IS_PRODUCTION
from database import REDIS_AVAILABLE, redis_client, DB_AVAILABLE, SessionLocal
from sqlalchemy import text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

_REDIS_DEVICE_LIST = "auth:devices:{user_id}"
_REDIS_DEVICE_TTL = 86400 * 30  # 30 天

# 开发环境内存兜底
_memory_devices: dict[str, list[dict]] = {}


def _fingerprint(device_id: str, user_agent: str, ip: str) -> str:
    """生成设备指纹哈希。"""
    raw = f"{device_id}|{user_agent}|{ip}"
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def _guess_device_type(user_agent: str) -> str:
    """根据 UA 粗略判断设备类型。"""
    ua_lower = (user_agent or "").lower()
    if "mobile" in ua_lower or "android" in ua_lower or "iphone" in ua_lower:
        return "mobile"
    if "windows" in ua_lower or "macintosh" in ua_lower or "linux" in ua_lower:
        return "desktop"
    return "unknown"


def _guess_location(ip: str) -> str:
    """简易 IP 地理标识（当前仅返回 IP 段，后续可接入 GeoIP）。"""
    parts = ip.split(".")
    if len(parts) == 4:
        return f"{parts[0]}.{parts[1]}.*.*"
    return "unknown"


def track_device_login(
    user_id: str,
    device_id: str,
    user_agent: str = "",
    ip: str = "",
    db: Optional[Session] = None,
) -> dict:
    """记录一次成功登录的设备信息。

    返回设备记录，包含 is_new_device 标识。
    """
    fp = _fingerprint(device_id, user_agent, ip)
    device_type = _guess_device_type(user_agent)
    location = _guess_location(ip)
    now_ts = int(time.time())
    now_dt = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(now_ts))

    record = {
        "device_id": device_id,
        "fingerprint": fp,
        "device_type": device_type,
        "ip": ip,
        "location": location,
        "user_agent": user_agent[:500],
        "last_login": now_dt,
        "last_login_ts": now_ts,
        "is_new_device": False,
    }

    # 写入 Redis
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_DEVICE_LIST.format(user_id=user_id)
        # 检查是否为新设备
        existing = redis_client.hget(key, fp)
        if existing is None:
            record["is_new_device"] = True
        redis_client.hset(key, fp, str(record))
        redis_client.expire(key, _REDIS_DEVICE_TTL)
    else:
        # 内存兜底
        if user_id not in _memory_devices:
            _memory_devices[user_id] = []
            record["is_new_device"] = True
        else:
            existing_fps = {d["fingerprint"] for d in _memory_devices[user_id]}
            if fp not in existing_fps:
                record["is_new_device"] = True
            else:
                # 更新已有设备的登录时间
                for d in _memory_devices[user_id]:
                    if d["fingerprint"] == fp:
                        d["last_login"] = now_dt
                        d["last_login_ts"] = now_ts
                        d["ip"] = ip
                        break
                else:
                    record["is_new_device"] = True
        _memory_devices[user_id].append(record)

    # 异步写入数据库（不阻塞）
    if DB_AVAILABLE and SessionLocal and db is None:
        try:
            with SessionLocal() as session:
                session.execute(
                    text(
                        "INSERT INTO device_logins(user_id, device_id, fingerprint, "
                        "device_type, ip, location, user_agent, last_login) "
                        "VALUES(:uid, :did, :fp, :dtype, :ip, :loc, :ua, :lt) "
                        "ON CONFLICT(fingerprint) DO UPDATE SET "
                        "last_login=:lt, ip=:ip"
                    ),
                    {
                        "uid": user_id,
                        "did": device_id,
                        "fp": fp,
                        "dtype": device_type,
                        "ip": ip,
                        "loc": location,
                        "ua": user_agent[:500],
                        "lt": now_dt,
                    },
                )
                session.commit()
        except Exception as e:
            logger.warning("device login DB write failed: %s", e)

    return record


def get_user_devices(user_id: str) -> list[dict]:
    """获取用户的所有登录设备列表。"""
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_DEVICE_LIST.format(user_id=user_id)
        data = redis_client.hgetall(key)
        devices = []
        for fp, val in data.items():
            try:
                # 简单解析（实际应该用 json.loads）
                devices.append(eval(val))
            except Exception:
                continue
        return sorted(devices, key=lambda d: d.get("last_login_ts", 0), reverse=True)

    return _memory_devices.get(user_id, [])


def revoke_device(user_id: str, fingerprint: str) -> bool:
    """撤销指定设备的登录状态。"""
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_DEVICE_LIST.format(user_id=user_id)
        return redis_client.hdel(key, fingerprint) > 0

    if user_id in _memory_devices:
        _memory_devices[user_id] = [
            d for d in _memory_devices[user_id] if d["fingerprint"] != fingerprint
        ]
        return True
    return False


def revoke_all_other_devices(user_id: str, current_fingerprint: str) -> int:
    """退出其他所有设备，返回被踢出的设备数。"""
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_DEVICE_LIST.format(user_id=user_id)
        all_devices = redis_client.hgetall(key)
        count = 0
        for fp in all_devices:
            if fp != current_fingerprint:
                redis_client.hdel(key, fp)
                count += 1
        return count

    before = len(_memory_devices.get(user_id, []))
    _memory_devices[user_id] = [
        d for d in _memory_devices.get(user_id, [])
        if d["fingerprint"] == current_fingerprint
    ]
    return before - len(_memory_devices.get(user_id, []))


def remove_device(user_id: str, fingerprint: str) -> bool:
    """移除指定设备记录（别名，供路由层调用）。"""
    return revoke_device(user_id, fingerprint)


def logout_other_devices(user_id: str, current_token: str = "") -> int:
    """退出其他所有设备（别名，供路由层调用）。

    同时清理 TOKENS_DB 中其他设备对应的 token。
    """
    from store import TOKENS_DB

    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_DEVICE_LIST.format(user_id=user_id)
        all_devices = redis_client.hgetall(key)
        count = len(all_devices)
        redis_client.delete(key)
        # 清理内存中的 tokens（除当前 token 外）
        tokens_to_remove = [
            tok for tok, uid in TOKENS_DB.items()
            if uid == user_id and tok != current_token
        ]
        for tok in tokens_to_remove:
            TOKENS_DB.pop(tok, None)
        return max(count - 1, len(tokens_to_remove))

    # 内存兜底
    count_before = len(_memory_devices.get(user_id, []))
    _memory_devices[user_id] = []
    tokens_to_remove = [
        tok for tok, uid in TOKENS_DB.items()
        if uid == user_id and tok != current_token
    ]
    for tok in tokens_to_remove:
        TOKENS_DB.pop(tok, None)
    return max(count_before, len(tokens_to_remove))

    if user_id in _memory_devices:
        before = len(_memory_devices[user_id])
        _memory_devices[user_id] = [
            d for d in _memory_devices[user_id] if d["fingerprint"] == current_fingerprint
        ]
        return before - len(_memory_devices[user_id])
    return 0
