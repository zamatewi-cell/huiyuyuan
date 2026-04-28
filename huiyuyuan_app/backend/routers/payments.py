"""支付记录与对账路由。

提供支付记录创建、凭证上传、状态管理、管理员对账等功能。
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.orm import Session

from database import get_db
from security import (
    AuthorizationDep,
    has_permission,
    is_admin_user,
    require_admin,
    require_user,
)
from store import ORDERS_DB
from services.payment_service import (
    create_payment_record,
    get_payment_record,
    update_payment_status,
    upload_voucher,
    get_user_payments,
    get_admin_reconciliation,
    check_timeout_payments,
    get_audit_logs,
    PAYMENT_STATUS_PENDING,
    PAYMENT_STATUS_AWAITING_CONFIRMATION,
    PAYMENT_STATUS_CONFIRMED,
    PAYMENT_STATUS_CANCELLED,
    PAYMENT_STATUS_TIMEOUT,
    PAYMENT_STATUS_DISPUTED,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/payments", tags=["Payments"])


def _require_payment_review_access(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = None,
) -> str:
    user_id = require_user(authorization)
    if is_admin_user(user_id, db):
        return user_id
    if has_permission(
        user_id,
        "payment_reconcile",
        db,
        allow_non_operator=False,
    ) or has_permission(
        user_id,
        "payment_exception_mark",
        db,
        allow_non_operator=False,
    ):
        return user_id
    raise HTTPException(status_code=403, detail="需要支付处理权限")


def _require_payment_reconcile_access(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = None,
) -> str:
    user_id = require_user(authorization)
    if is_admin_user(user_id, db) or has_permission(
        user_id,
        "payment_reconcile",
        db,
        allow_non_operator=False,
    ):
        return user_id
    raise HTTPException(status_code=403, detail="需要支付对账权限")


def _require_payment_exception_access(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = None,
) -> str:
    user_id = require_user(authorization)
    if is_admin_user(user_id, db) or has_permission(
        user_id,
        "payment_exception_mark",
        db,
        allow_non_operator=False,
    ):
        return user_id
    raise HTTPException(status_code=403, detail="需要支付异常处理权限")


@router.post("")
async def create_payment(
    order_id: str,
    payment_account_id: Optional[str] = None,
    payment_method: str = "wechat",
    remark: Optional[str] = None,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """创建支付记录（下单后调用）。"""
    user_id = require_user(authorization)

    # 验证订单存在且属于当前用户
    order = None
    if ORDERS_DB:
        order = ORDERS_DB.get(order_id)
    if db and order is None:
        from sqlalchemy import text
        row = db.execute(
            text("SELECT * FROM orders WHERE id = :id LIMIT 1"),
            {"id": order_id},
        ).fetchone()
        if row:
            order = dict(row._mapping)

    if order is None:
        raise HTTPException(status_code=404, detail="订单不存在")

    if order.get("user_id") != user_id:
        raise HTTPException(status_code=403, detail="无权操作该订单")

    # 检查是否已有进行中的支付记录
    existing = get_user_payments(user_id, limit=100, db=db)
    for ep in existing:
        if ep.get("order_id") == order_id and ep.get("status") in (
            PAYMENT_STATUS_PENDING,
            PAYMENT_STATUS_AWAITING_CONFIRMATION,
        ):
            return {
                "success": True,
                "payment": ep,
                "message": "该订单已有进行中的支付记录",
            }

    amount = float(order.get("total_amount", 0))
    record = create_payment_record(
        order_id=order_id,
        user_id=user_id,
        amount=amount,
        payment_account_id=payment_account_id,
        payment_method=payment_method,
        remark=remark,
        db=db,
    )

    # Auto-confirm for 0.01 test orders (skip admin confirmation)
    if amount == 0.01 and record:
        from datetime import datetime
        updated = update_payment_status(
            record["payment_id"],
            PAYMENT_STATUS_CONFIRMED,
            admin_id="system",
            admin_note="测试商品自动确认支付",
            db=db,
        )
        # Sync order status to paid
        if updated and order_id:
            if ORDERS_DB and order_id in ORDERS_DB:
                ORDERS_DB[order_id].status = "paid"
                ORDERS_DB[order_id].paid_at = datetime.now().isoformat()
            if db:
                try:
                    db.execute(
                        text(
                            "UPDATE orders SET status='paid', paid_at=CURRENT_TIMESTAMP "
                            "WHERE id=:oid"
                        ),
                        {"oid": order_id},
                    )
                    db.commit()
                except Exception as e:
                    logger.warning("test order status sync failed: %s", e)
        if updated:
            record = updated
            record["auto_confirmed"] = True

    if db is not None:
        db.commit()

    return {"success": True, "payment": record}


@router.get("/{payment_id}")
async def get_payment(
    payment_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """获取支付记录详情。"""
    user_id = require_user(authorization)

    record = get_payment_record(payment_id, db=db)
    if record is None:
        raise HTTPException(status_code=404, detail="支付记录不存在")

    if record.get("user_id") != user_id:
        # 管理员可以查看所有支付记录
        try:
            require_admin(authorization)
        except HTTPException:
            raise HTTPException(status_code=403, detail="无权查看该支付记录")

    return {"success": True, "payment": record}


@router.post("/{payment_id}/upload-voucher")
async def upload_payment_voucher(
    payment_id: str,
    voucher_url: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """上传支付凭证。"""
    user_id = require_user(authorization)

    record = get_payment_record(payment_id, db=db)
    if record is None:
        raise HTTPException(status_code=404, detail="支付记录不存在")

    if record.get("user_id") != user_id:
        raise HTTPException(status_code=403, detail="无权操作该支付记录")

    if record.get("status") not in (PAYMENT_STATUS_PENDING, PAYMENT_STATUS_AWAITING_CONFIRMATION):
        raise HTTPException(status_code=400, detail="当前状态不允许上传凭证")

    updated = upload_voucher(payment_id, user_id, voucher_url, db=db)
    if db is not None:
        db.commit()
    return {"success": True, "payment": updated}


@router.post("/{payment_id}/cancel")
async def cancel_payment(
    payment_id: str,
    reason: Optional[str] = None,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """取消支付。"""
    user_id = require_user(authorization)

    record = get_payment_record(payment_id, db=db)
    if record is None:
        raise HTTPException(status_code=404, detail="支付记录不存在")

    if record.get("user_id") != user_id:
        raise HTTPException(status_code=403, detail="无权操作该支付记录")

    if record.get("status") not in (PAYMENT_STATUS_PENDING, PAYMENT_STATUS_AWAITING_CONFIRMATION):
        raise HTTPException(status_code=400, detail="当前状态不允许取消")

    note = f"用户取消: {reason}" if reason else "用户取消"
    updated = update_payment_status(
        payment_id,
        PAYMENT_STATUS_CANCELLED,
        user_id=user_id,
        admin_note=note,
        db=db,
    )
    if db is not None:
        db.commit()
    return {"success": True, "payment": updated}


@router.get("")
async def list_my_payments(
    limit: int = Query(default=20, le=100),
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """获取当前用户的支付记录列表。"""
    user_id = require_user(authorization)

    payments = get_user_payments(user_id, limit=limit, db=db)
    return {"success": True, "payments": payments, "total": len(payments)}


# ── 管理员对账与支付处理 ─────────────────────────────────────────────

@router.get("/admin/reconciliation")
async def admin_reconciliation(
    status: Optional[str] = Query(default=None, description="按状态过滤"),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """管理员对账视图：查看所有支付记录。"""
    _require_payment_review_access(authorization, db)

    payments = get_admin_reconciliation(status_filter=status, limit=limit, offset=offset, db=db)
    return {"success": True, "payments": payments, "total": len(payments)}


@router.post("/admin/{payment_id}/confirm")
async def admin_confirm_payment(
    payment_id: str,
    note: Optional[str] = None,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """管理员确认到账。"""
    admin_id = _require_payment_reconcile_access(authorization, db)

    record = get_payment_record(payment_id, db=db)
    if record is None:
        raise HTTPException(status_code=404, detail="支付记录不存在")

    if record.get("status") not in (
        PAYMENT_STATUS_PENDING,
        PAYMENT_STATUS_AWAITING_CONFIRMATION,
        PAYMENT_STATUS_DISPUTED,
    ):
        raise HTTPException(status_code=400, detail="当前状态不允许确认")

    updated = update_payment_status(
        payment_id,
        PAYMENT_STATUS_CONFIRMED,
        admin_id=admin_id,
        admin_note=note,
        db=db,
    )

    # 同步更新订单状态为 paid
    if updated:
        order_id = record.get("order_id")
        if ORDERS_DB and order_id:
            order = ORDERS_DB.get(order_id)
            if order:
                order.status = "paid"
                from datetime import datetime
                order.paid_at = datetime.now().isoformat()
        if db and order_id:
            from sqlalchemy import text
            try:
                db.execute(
                    text(
                        "UPDATE orders SET status='paid', paid_at=CURRENT_TIMESTAMP "
                        "WHERE id=:oid"
                    ),
                    {"oid": order_id},
                )
                db.commit()
            except Exception as e:
                logger.warning("order status sync failed: %s", e)

    return {"success": True, "payment": updated}


@router.post("/admin/{payment_id}/dispute")
async def admin_dispute_payment(
    payment_id: str,
    reason: Optional[str] = None,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """管理员标记支付异常/争议。"""
    admin_id = _require_payment_exception_access(authorization, db)

    record = get_payment_record(payment_id, db=db)
    if record is None:
        raise HTTPException(status_code=404, detail="支付记录不存在")

    if record.get("status") != PAYMENT_STATUS_AWAITING_CONFIRMATION:
        raise HTTPException(status_code=400, detail="当前状态不允许标记异常")

    note = f"管理员标记异常: {reason}" if reason else "管理员标记异常"
    updated = update_payment_status(
        payment_id,
        PAYMENT_STATUS_DISPUTED,
        admin_id=admin_id,
        admin_note=note,
        db=db,
    )
    if db is not None:
        db.commit()
    return {"success": True, "payment": updated}


@router.post("/admin/check-timeout")
async def admin_check_timeout(
    timeout_minutes: int = Query(default=30, ge=5, le=1440),
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """管理员手动检查超时支付。"""
    require_admin(authorization)

    timeout_ids = check_timeout_payments(timeout_minutes=timeout_minutes, db=db)
    if db is not None:
        db.commit()
    return {
        "success": True,
        "timed_out": timeout_ids,
        "count": len(timeout_ids),
    }


@router.get("/admin/audit/{user_id}")
async def get_user_audit_logs(
    user_id: str,
    limit: int = Query(default=50, le=200),
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    """获取用户的支付审计日志（管理员）。"""
    require_admin(authorization)

    logs = get_audit_logs(user_id, limit=limit, db=db)
    return {"success": True, "logs": logs, "total": len(logs)}
