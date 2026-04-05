"""支付记录与审计服务。

负责：
- 支付记录创建与状态流转
- 支付凭证上传与管理
- 支付审计日志记录
- 超时未付订单检测
"""

import logging
import time
import uuid
from datetime import datetime, timedelta
from typing import Optional

from config import APP_ENV, IS_PRODUCTION
from database import REDIS_AVAILABLE, redis_client, DB_AVAILABLE, SessionLocal
from sqlalchemy import text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

# Redis key 模板
_REDIS_PAYMENT_RECORD = "payment:record:{payment_id}"
_REDIS_PAYMENT_AUDIT = "payment:audit:{user_id}"
_REDIS_PAYMENT_TTL = 86400 * 90  # 90 天

# 内存兜底
_memory_payments: dict[str, dict] = {}
_memory_audit_logs: dict[str, list[dict]] = {}


# ── 支付记录状态机 ─────────────────────────────────────────────────────

PAYMENT_STATUS_PENDING = "pending"
PAYMENT_STATUS_AWAITING_CONFIRMATION = "awaiting_confirmation"
PAYMENT_STATUS_CONFIRMED = "confirmed"
PAYMENT_STATUS_CANCELLED = "cancelled"
PAYMENT_STATUS_TIMEOUT = "timeout"
PAYMENT_STATUS_DISPUTED = "disputed"

VALID_TRANSITIONS = {
    PAYMENT_STATUS_PENDING: [PAYMENT_STATUS_AWAITING_CONFIRMATION, PAYMENT_STATUS_CANCELLED, PAYMENT_STATUS_TIMEOUT],
    PAYMENT_STATUS_AWAITING_CONFIRMATION: [PAYMENT_STATUS_CONFIRMED, PAYMENT_STATUS_CANCELLED, PAYMENT_STATUS_DISPUTED],
    PAYMENT_STATUS_CONFIRMED: [],  # 终态，只能通过退款/撤销变更
    PAYMENT_STATUS_CANCELLED: [],  # 终态
    PAYMENT_STATUS_TIMEOUT: [],    # 终态
    PAYMENT_STATUS_DISPUTED: [PAYMENT_STATUS_CONFIRMED, PAYMENT_STATUS_CANCELLED],
}


def create_payment_record(
    order_id: str,
    user_id: str,
    amount: float,
    payment_account_id: Optional[str] = None,
    payment_method: str = "wechat",
    remark: Optional[str] = None,
    db: Optional[Session] = None,
) -> dict:
    """创建支付记录。"""
    payment_id = f"pay_{uuid.uuid4().hex[:12]}"
    now_ts = int(time.time())
    now_dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    record = {
        "payment_id": payment_id,
        "order_id": order_id,
        "user_id": user_id,
        "amount": amount,
        "payment_account_id": payment_account_id,
        "payment_method": payment_method,
        "status": PAYMENT_STATUS_PENDING,
        "remark": remark or "",
        "voucher_url": None,
        "admin_note": None,
        "confirmed_by": None,
        "confirmed_at": None,
        "created_at": now_dt,
        "created_at_ts": now_ts,
        "updated_at": now_dt,
    }

    # 写入 Redis
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_PAYMENT_RECORD.format(payment_id=payment_id)
        redis_client.hset(key, mapping={k: str(v) for k, v in record.items()})
        redis_client.expire(key, _REDIS_PAYMENT_TTL)
    else:
        _memory_payments[payment_id] = record.copy()

    # 异步写入数据库
    if DB_AVAILABLE and SessionLocal and db is None:
        try:
            with SessionLocal() as session:
                session.execute(
                    text(
                        "INSERT INTO payment_records "
                        "(payment_id, order_id, user_id, amount, payment_account_id, "
                        "payment_method, status, remark, voucher_url, admin_note, "
                        "confirmed_by, confirmed_at, created_at, updated_at) "
                        "VALUES (:pid, :oid, :uid, :amt, :paid, :pm, :st, :rmk, "
                        ":vu, :an, :cb, :ca, :cr, :up) "
                        "ON CONFLICT(payment_id) DO NOTHING"
                    ),
                    {
                        "pid": payment_id,
                        "oid": order_id,
                        "uid": user_id,
                        "amt": amount,
                        "paid": payment_account_id,
                        "pm": payment_method,
                        "st": PAYMENT_STATUS_PENDING,
                        "rmk": remark or "",
                        "vu": None,
                        "an": None,
                        "cb": None,
                        "ca": None,
                        "cr": now_dt,
                        "up": now_dt,
                    },
                )
                session.commit()
        except Exception as e:
            logger.warning("payment record DB write failed: %s", e)

    # 记录审计日志
    _write_audit_log(
        user_id=user_id,
        payment_id=payment_id,
        order_id=order_id,
        action="payment_created",
        detail=f"创建支付记录，金额 ¥{amount:.2f}",
        db=db,
    )

    return record


def get_payment_record(payment_id: str, db: Optional[Session] = None) -> Optional[dict]:
    """获取支付记录。"""
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_PAYMENT_RECORD.format(payment_id=payment_id)
        data = redis_client.hgetall(key)
        if data:
            return _parse_payment_record(data)

    if payment_id in _memory_payments:
        return _memory_payments[payment_id].copy()

    if DB_AVAILABLE and SessionLocal and db is None:
        try:
            with SessionLocal() as session:
                row = session.execute(
                    text("SELECT * FROM payment_records WHERE payment_id = :pid LIMIT 1"),
                    {"pid": payment_id},
                ).fetchone()
                if row:
                    m = dict(row._mapping)
                    return {
                        "payment_id": m.get("payment_id"),
                        "order_id": m.get("order_id"),
                        "user_id": m.get("user_id"),
                        "amount": float(m.get("amount", 0)),
                        "payment_account_id": m.get("payment_account_id"),
                        "payment_method": m.get("payment_method"),
                        "status": m.get("status"),
                        "remark": m.get("remark", ""),
                        "voucher_url": m.get("voucher_url"),
                        "admin_note": m.get("admin_note"),
                        "confirmed_by": m.get("confirmed_by"),
                        "confirmed_at": _ts_str(m.get("confirmed_at")),
                        "created_at": _ts_str(m.get("created_at")),
                        "created_at_ts": _to_ts(m.get("created_at")),
                        "updated_at": _ts_str(m.get("updated_at")),
                    }
        except Exception as e:
            logger.warning("payment record DB read failed: %s", e)

    return None


def update_payment_status(
    payment_id: str,
    new_status: str,
    user_id: Optional[str] = None,
    admin_id: Optional[str] = None,
    admin_note: Optional[str] = None,
    db: Optional[Session] = None,
) -> Optional[dict]:
    """更新支付状态。"""
    record = get_payment_record(payment_id, db=db)
    if record is None:
        return None

    current_status = record["status"]
    allowed = VALID_TRANSITIONS.get(current_status, [])
    if new_status not in allowed:
        logger.warning(
            "invalid payment transition: %s -> %s for %s",
            current_status,
            new_status,
            payment_id,
        )
        return None

    now_dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    record["status"] = new_status
    record["updated_at"] = now_dt

    if admin_note:
        record["admin_note"] = admin_note

    if new_status == PAYMENT_STATUS_CONFIRMED:
        record["confirmed_by"] = admin_id
        record["confirmed_at"] = now_dt

    # 写入 Redis
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_PAYMENT_RECORD.format(payment_id=payment_id)
        redis_client.hset(key, mapping={k: str(v) for k, v in record.items()})

    # 写入内存
    if payment_id in _memory_payments:
        _memory_payments[payment_id].update(record)

    # 写入数据库
    if DB_AVAILABLE and SessionLocal and db is None:
        try:
            with SessionLocal() as session:
                session.execute(
                    text(
                        "UPDATE payment_records SET status=:st, updated_at=:up, "
                        "admin_note=:an, confirmed_by=:cb, confirmed_at=:ca "
                        "WHERE payment_id=:pid"
                    ),
                    {
                        "st": new_status,
                        "up": now_dt,
                        "an": admin_note,
                        "cb": admin_id,
                        "ca": record.get("confirmed_at"),
                        "pid": payment_id,
                    },
                )
                session.commit()
        except Exception as e:
            logger.warning("payment status DB update failed: %s", e)

    # 审计日志
    actor = admin_id or user_id or "system"
    _write_audit_log(
        user_id=actor,
        payment_id=payment_id,
        order_id=record.get("order_id"),
        action=f"payment_status_{new_status}",
        detail=f"状态变更: {current_status} -> {new_status}",
        db=db,
    )

    return record


def upload_voucher(
    payment_id: str,
    user_id: str,
    voucher_url: str,
    db: Optional[Session] = None,
) -> Optional[dict]:
    """上传支付凭证。"""
    record = get_payment_record(payment_id, db=db)
    if record is None:
        return None

    now_dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    record["voucher_url"] = voucher_url
    record["updated_at"] = now_dt

    # 如果原来是 pending，上传凭证后变为 awaiting_confirmation
    if record["status"] == PAYMENT_STATUS_PENDING:
        record["status"] = PAYMENT_STATUS_AWAITING_CONFIRMATION

    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_PAYMENT_RECORD.format(payment_id=payment_id)
        redis_client.hset(key, mapping={k: str(v) for k, v in record.items()})

    if payment_id in _memory_payments:
        _memory_payments[payment_id].update(record)

    if DB_AVAILABLE and SessionLocal and db is None:
        try:
            with SessionLocal() as session:
                session.execute(
                    text(
                        "UPDATE payment_records SET voucher_url=:vu, status=:st, "
                        "updated_at=:up WHERE payment_id=:pid"
                    ),
                    {
                        "vu": voucher_url,
                        "st": record["status"],
                        "up": now_dt,
                        "pid": payment_id,
                    },
                )
                session.commit()
        except Exception as e:
            logger.warning("voucher DB update failed: %s", e)

    _write_audit_log(
        user_id=user_id,
        payment_id=payment_id,
        order_id=record.get("order_id"),
        action="voucher_uploaded",
        detail=f"上传支付凭证: {voucher_url}",
        db=db,
    )

    return record


def get_user_payments(user_id: str, limit: int = 50) -> list[dict]:
    """获取用户的支付记录列表。"""
    results = []

    if REDIS_AVAILABLE and redis_client:
        # Redis 没有索引查询，需要扫描（生产环境应使用数据库）
        cursor = 0
        while True:
            cursor, keys = redis_client.scan(cursor, match="payment:record:pay_*", count=100)
            for key in keys:
                data = redis_client.hgetall(key)
                if data.get("user_id") == user_id:
                    results.append(_parse_payment_record(data))
            if cursor == 0:
                break
    else:
        for pid, record in _memory_payments.items():
            if record.get("user_id") == user_id:
                results.append(record.copy())

    # 按创建时间倒序
    results.sort(key=lambda x: x.get("created_at_ts", 0), reverse=True)
    return results[:limit]


def get_admin_reconciliation(
    status_filter: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> list[dict]:
    """管理员对账视图：获取所有支付记录（可按状态过滤）。"""
    results = []

    if REDIS_AVAILABLE and redis_client:
        cursor = 0
        while True:
            cursor, keys = redis_client.scan(cursor, match="payment:record:pay_*", count=100)
            for key in keys:
                data = redis_client.hgetall(key)
                rec = _parse_payment_record(data)
                if status_filter is None or rec.get("status") == status_filter:
                    results.append(rec)
            if cursor == 0:
                break
    else:
        for pid, record in _memory_payments.items():
            if status_filter is None or record.get("status") == status_filter:
                results.append(record.copy())

    results.sort(key=lambda x: x.get("created_at_ts", 0), reverse=True)
    return results[offset:offset + limit]


def check_timeout_payments(timeout_minutes: int = 30) -> list[str]:
    """检测超时未付的支付记录。"""
    timeout_ids = []
    cutoff = int(time.time()) - timeout_minutes * 60

    records_to_check = {}
    if REDIS_AVAILABLE and redis_client:
        cursor = 0
        while True:
            cursor, keys = redis_client.scan(cursor, match="payment:record:pay_*", count=100)
            for key in keys:
                data = redis_client.hgetall(key)
                if data.get("status") == PAYMENT_STATUS_PENDING:
                    records_to_check[data.get("payment_id")] = data
            if cursor == 0:
                break
    else:
        for pid, record in _memory_payments.items():
            if record.get("status") == PAYMENT_STATUS_PENDING:
                records_to_check[pid] = record

    for pid, data in records_to_check.items():
        created_ts = int(data.get("created_at_ts", 0))
        if created_ts < cutoff:
            timeout_ids.append(pid)
            # 自动标记为超时
            update_payment_status(pid, PAYMENT_STATUS_TIMEOUT)

    return timeout_ids


def get_audit_logs(user_id: str, limit: int = 50) -> list[dict]:
    """获取用户的支付审计日志。"""
    if REDIS_AVAILABLE and redis_client:
        key = _REDIS_PAYMENT_AUDIT.format(user_id=user_id)
        data = redis_client.lrange(key, 0, limit - 1)
        logs = []
        for item in data:
            try:
                import json
                logs.append(json.loads(item))
            except Exception:
                continue
        return logs

    return _memory_audit_logs.get(user_id, [])[:limit]


# ── 内部辅助函数 ─────────────────────────────────────────────────────

def _write_audit_log(
    user_id: str,
    payment_id: str,
    order_id: str,
    action: str,
    detail: str,
    db: Optional[Session] = None,
):
    """写入支付审计日志。"""
    now_dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = {
        "log_id": f"log_{uuid.uuid4().hex[:8]}",
        "user_id": user_id,
        "payment_id": payment_id,
        "order_id": order_id,
        "action": action,
        "detail": detail,
        "created_at": now_dt,
    }

    if REDIS_AVAILABLE and redis_client:
        import json
        key = _REDIS_PAYMENT_AUDIT.format(user_id=user_id)
        redis_client.lpush(key, json.dumps(log_entry, ensure_ascii=False))
        redis_client.ltrim(key, 0, 499)  # 最多保留500条
        redis_client.expire(key, _REDIS_PAYMENT_TTL)
    else:
        if user_id not in _memory_audit_logs:
            _memory_audit_logs[user_id] = []
        _memory_audit_logs[user_id].insert(0, log_entry)
        _memory_audit_logs[user_id] = _memory_audit_logs[user_id][:500]

    # 异步写入数据库
    if DB_AVAILABLE and SessionLocal and db is None:
        try:
            with SessionLocal() as session:
                session.execute(
                    text(
                        "INSERT INTO payment_audit_logs "
                        "(log_id, user_id, payment_id, order_id, action, detail, created_at) "
                        "VALUES (:lid, :uid, :pid, :oid, :act, :det, :cr)"
                    ),
                    {
                        "lid": log_entry["log_id"],
                        "uid": user_id,
                        "pid": payment_id,
                        "oid": order_id,
                        "act": action,
                        "det": detail,
                        "cr": now_dt,
                    },
                )
                session.commit()
        except Exception as e:
            logger.warning("audit log DB write failed: %s", e)


def _parse_payment_record(data: dict) -> dict:
    """解析 Redis 中的支付记录。"""
    try:
        amount = float(data.get("amount", 0))
    except (ValueError, TypeError):
        amount = 0.0

    try:
        created_at_ts = int(data.get("created_at_ts", 0))
    except (ValueError, TypeError):
        created_at_ts = 0

    return {
        "payment_id": data.get("payment_id"),
        "order_id": data.get("order_id"),
        "user_id": data.get("user_id"),
        "amount": amount,
        "payment_account_id": data.get("payment_account_id"),
        "payment_method": data.get("payment_method"),
        "status": data.get("status"),
        "remark": data.get("remark", ""),
        "voucher_url": data.get("voucher_url"),
        "admin_note": data.get("admin_note"),
        "confirmed_by": data.get("confirmed_by"),
        "confirmed_at": data.get("confirmed_at"),
        "created_at": data.get("created_at"),
        "created_at_ts": created_at_ts,
        "updated_at": data.get("updated_at"),
    }


def _ts_str(value) -> Optional[str]:
    """将数据库时间转为字符串。"""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    return str(value)


def _to_ts(value) -> int:
    """将数据库时间转为时间戳。"""
    if value is None:
        return 0
    if isinstance(value, datetime):
        return int(value.timestamp())
    if isinstance(value, str):
        try:
            dt = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
            return int(dt.timestamp())
        except ValueError:
            return 0
    return 0
