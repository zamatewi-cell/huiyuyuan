"""
User router: profile, address management, and payment accounts.
DB-first with development-only in-memory fallback.
"""

import logging
import re
import uuid
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from database import get_db, handle_database_error, require_database
from schemas.user import (
    Address,
    AddressCreate,
    ChangePasswordRequest,
    DeactivateAccountRequest,
    PaymentAccountCreate,
    PaymentAccountResponse,
    PaymentAccountUpdate,
    UserResponse,
)
from security import (
    AuthorizationDep,
    get_user_record,
    hash_password,
    require_user,
    verify_password,
)
from store import ADDRESSES_DB, PAYMENT_ACCOUNTS_DB, TOKENS_DB, USERS_DB

logger = logging.getLogger(__name__)
PASSWORD_PATTERN = re.compile(r"^(?=.*[A-Za-z])(?=.*\d).{8,}$")

router = APIRouter(prefix="/api/users", tags=["Users"])


def _validate_password_strength(password: str) -> None:
    if not PASSWORD_PATTERN.match(password or ""):
        raise HTTPException(
            status_code=400,
            detail="密码需至少8位，且同时包含字母和数字",
        )


def _clear_tokens_for_user(user_id: str) -> None:
    for token, mapped_user_id in list(TOKENS_DB.items()):
        if mapped_user_id == user_id:
            TOKENS_DB.pop(token, None)


def _row_to_address(mapping) -> Address:
    return Address(
        id=mapping["id"],
        user_id=mapping["user_id"],
        recipient_name=mapping["recipient_name"],
        phone_number=mapping["phone_number"],
        province=mapping["province"],
        city=mapping["city"],
        district=mapping["district"],
        detail_address=mapping["detail_address"],
        is_default=mapping["is_default"],
        postal_code=mapping.get("postal_code"),
        tag=mapping.get("tag"),
    )


def _row_to_payment_account(mapping) -> PaymentAccountResponse:
    return PaymentAccountResponse(
        id=mapping["id"],
        user_id=mapping["user_id"],
        name=mapping["account_name"],
        type=mapping["account_type"],
        account_number=mapping.get("account_number"),
        bank_name=mapping.get("bank_name"),
        qr_code_url=mapping.get("qr_code_url"),
        is_active=mapping["is_active"],
        is_default=mapping["is_default"],
        created_at=mapping["created_at"],
        updated_at=mapping["updated_at"],
    )


def _get_default_payment_account_id(user_id: str, db: Optional[Session]) -> Optional[str]:
    if db is not None:
        try:
            row = db.execute(
                text(
                    "SELECT id FROM payment_accounts "
                    "WHERE user_id = :uid AND is_default = true "
                    "ORDER BY updated_at DESC LIMIT 1"
                ),
                {"uid": user_id},
            ).fetchone()
            if row:
                return row._mapping["id"]
        except Exception:
            logger.debug("payment_accounts table not available yet for user %s", user_id)

    for account in PAYMENT_ACCOUNTS_DB.values():
        if account.user_id == user_id and account.is_default:
            return account.id
    return None


@router.get("/profile")
async def get_profile(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            user = get_user_record(user_id, db)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            return UserResponse(
                **user,
                payment_account_id=_get_default_payment_account_id(user_id, db),
            ).model_dump()
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "read user profile", exc)

    require_database(db, "read user profile")

    user = USERS_DB.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse(
        **user,
        payment_account_id=_get_default_payment_account_id(user_id, None),
    ).model_dump()


@router.put("/profile")
async def update_profile(
    data: dict,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    allowed = {"username", "avatar"}
    updates = {key: value for key, value in data.items() if key in allowed}

    if db is not None:
        try:
            if updates:
                set_parts = []
                params: dict[str, object] = {"id": user_id}
                if "username" in updates:
                    set_parts.append("username = :username")
                    params["username"] = updates["username"]
                if "avatar" in updates:
                    set_parts.append("avatar_url = :avatar")
                    params["avatar"] = updates["avatar"]

                result = db.execute(
                    text(f"UPDATE users SET {', '.join(set_parts)} WHERE id = :id"),
                    params,
                )
                if result.rowcount == 0:
                    raise HTTPException(status_code=404, detail="User not found")
                db.commit()

            user = get_user_record(user_id, db)
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            return {
                "success": True,
                "user": UserResponse(
                    **user,
                    payment_account_id=_get_default_payment_account_id(user_id, db),
                ).model_dump(),
            }
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "update user profile", exc)

    require_database(db, "update user profile")

    user = USERS_DB.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    for key, value in updates.items():
        user[key] = value
    return {
        "success": True,
        "user": UserResponse(
            **user,
            payment_account_id=_get_default_payment_account_id(user_id, None),
        ).model_dump(),
    }


@router.post("/account/change-password")
async def change_password(
    payload: ChangePasswordRequest,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    user = get_user_record(user_id, db)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(payload.current_password, user.get("password_hash", "")):
        raise HTTPException(status_code=400, detail="当前密码错误")

    if payload.new_password != payload.confirm_password:
        raise HTTPException(status_code=400, detail="两次输入的新密码不一致")

    if payload.current_password == payload.new_password:
        raise HTTPException(status_code=400, detail="新密码不能与当前密码相同")

    _validate_password_strength(payload.new_password)
    new_password_hash = hash_password(payload.new_password)

    if db is not None:
        try:
            result = db.execute(
                text(
                    "UPDATE users SET password_hash = :password_hash, updated_at = NOW() "
                    "WHERE id = :id AND is_active = true"
                ),
                {
                    "id": user_id,
                    "password_hash": new_password_hash,
                },
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="User not found")
            db.commit()
            return {"success": True, "message": "密码已更新"}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "change account password", exc)

    require_database(db, "change account password")

    stored = USERS_DB.get(user_id)
    if not stored:
        raise HTTPException(status_code=404, detail="User not found")
    stored["password_hash"] = new_password_hash
    return {"success": True, "message": "密码已更新"}


@router.post("/account/deactivate")
async def deactivate_account(
    payload: DeactivateAccountRequest,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    user = get_user_record(user_id, db)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.get("user_type") != "customer":
        raise HTTPException(status_code=403, detail="仅普通用户可注销账号")

    if not verify_password(payload.current_password, user.get("password_hash", "")):
        raise HTTPException(status_code=400, detail="当前密码错误")

    deactivated_name = f"已注销用户{user_id[-6:]}"
    replacement_password = hash_password(uuid.uuid4().hex)

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM addresses WHERE user_id = :uid"),
                {"uid": user_id},
            )
            db.execute(
                text("DELETE FROM payment_accounts WHERE user_id = :uid"),
                {"uid": user_id},
            )
            result = db.execute(
                text(
                    "UPDATE users SET "
                    "phone = NULL, username = :username, password_hash = :password_hash, "
                    "avatar_url = NULL, is_active = false, updated_at = NOW() "
                    "WHERE id = :id AND user_type = 'customer'"
                ),
                {
                    "id": user_id,
                    "username": deactivated_name,
                    "password_hash": replacement_password,
                },
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="User not found")
            db.commit()
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "deactivate account", exc)
    else:
        require_database(db, "deactivate account")

        stored = USERS_DB.get(user_id)
        if not stored:
            raise HTTPException(status_code=404, detail="User not found")
        stored["phone"] = None
        stored["username"] = deactivated_name
        stored["password_hash"] = replacement_password
        stored["avatar"] = None
        stored["is_active"] = False

        for address_id, address in list(ADDRESSES_DB.items()):
            if address.user_id == user_id:
                ADDRESSES_DB.pop(address_id, None)

        for account_id, account in list(PAYMENT_ACCOUNTS_DB.items()):
            if account.user_id == user_id:
                PAYMENT_ACCOUNTS_DB.pop(account_id, None)

    _clear_tokens_for_user(user_id)
    return {"success": True, "message": "账号已注销"}


@router.get("/addresses", response_model=List[Address])
async def get_addresses(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT * FROM addresses WHERE user_id = :uid "
                    "ORDER BY is_default DESC, created_at DESC"
                ),
                {"uid": user_id},
            ).fetchall()
            return [_row_to_address(row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "read addresses", exc)

    require_database(db, "read addresses")

    addresses = [address for address in ADDRESSES_DB.values() if address.user_id == user_id]
    addresses.sort(key=lambda item: item.is_default, reverse=True)
    return addresses


@router.post("/addresses", response_model=Address)
async def create_address(
    address: AddressCreate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    address_id = f"addr_{uuid.uuid4().hex[:8]}"

    if db is not None:
        try:
            if address.is_default:
                db.execute(
                    text("UPDATE addresses SET is_default = false WHERE user_id = :uid"),
                    {"uid": user_id},
                )
            db.execute(
                text(
                    "INSERT INTO addresses "
                    "(id, user_id, recipient_name, phone_number, province, city, "
                    "district, detail_address, postal_code, tag, is_default) "
                    "VALUES (:id, :uid, :name, :phone, :prov, :city, :dist, :detail, :zip, :tag, :default)"
                ),
                {
                    "id": address_id,
                    "uid": user_id,
                    "name": address.recipient_name,
                    "phone": address.phone_number,
                    "prov": address.province,
                    "city": address.city,
                    "dist": address.district,
                    "detail": address.detail_address,
                    "zip": address.postal_code,
                    "tag": address.tag,
                    "default": address.is_default,
                },
            )
            db.commit()
            return Address(id=address_id, user_id=user_id, **address.model_dump())
        except Exception as exc:
            handle_database_error(db, "create address", exc)

    require_database(db, "create address")

    if address.is_default:
        for stored in list(ADDRESSES_DB.values()):
            if stored.user_id == user_id:
                ADDRESSES_DB[stored.id] = Address(
                    **{**stored.model_dump(), "is_default": False}
                )

    new_address = Address(id=address_id, user_id=user_id, **address.model_dump())
    ADDRESSES_DB[address_id] = new_address
    return new_address


@router.put("/addresses/{address_id}", response_model=Address)
async def update_address(
    address_id: str,
    address: AddressCreate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            row = db.execute(
                text("SELECT user_id FROM addresses WHERE id = :id"),
                {"id": address_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Address not found")
            if row._mapping["user_id"] != user_id:
                raise HTTPException(status_code=403, detail="Forbidden")

            if address.is_default:
                db.execute(
                    text(
                        "UPDATE addresses SET is_default = false "
                        "WHERE user_id = :uid AND id != :id"
                    ),
                    {"uid": user_id, "id": address_id},
                )

            result = db.execute(
                text(
                    "UPDATE addresses SET "
                    "recipient_name = :name, phone_number = :phone, province = :prov, "
                    "city = :city, district = :dist, detail_address = :detail, "
                    "postal_code = :zip, tag = :tag, is_default = :default "
                    "WHERE id = :id AND user_id = :uid"
                ),
                {
                    "id": address_id,
                    "uid": user_id,
                    "name": address.recipient_name,
                    "phone": address.phone_number,
                    "prov": address.province,
                    "city": address.city,
                    "dist": address.district,
                    "detail": address.detail_address,
                    "zip": address.postal_code,
                    "tag": address.tag,
                    "default": address.is_default,
                },
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="Address not found")

            db.commit()
            return Address(id=address_id, user_id=user_id, **address.model_dump())
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "update address", exc)

    require_database(db, "update address")

    stored = ADDRESSES_DB.get(address_id)
    if not stored:
        raise HTTPException(status_code=404, detail="Address not found")
    if stored.user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    if address.is_default:
        for other in list(ADDRESSES_DB.values()):
            if other.user_id == user_id and other.id != address_id:
                ADDRESSES_DB[other.id] = Address(
                    **{**other.model_dump(), "is_default": False}
                )

    updated = Address(id=address_id, user_id=user_id, **address.model_dump())
    ADDRESSES_DB[address_id] = updated
    return updated


@router.delete("/addresses/{address_id}")
async def delete_address(
    address_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            row = db.execute(
                text("SELECT user_id FROM addresses WHERE id = :id"),
                {"id": address_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Address not found")
            if row._mapping["user_id"] != user_id:
                raise HTTPException(status_code=403, detail="Forbidden")

            result = db.execute(
                text("DELETE FROM addresses WHERE id = :id AND user_id = :uid"),
                {"id": address_id, "uid": user_id},
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="Address not found")
            db.commit()
            return {"success": True, "message": "Address deleted"}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "delete address", exc)

    require_database(db, "delete address")

    stored = ADDRESSES_DB.get(address_id)
    if not stored:
        raise HTTPException(status_code=404, detail="Address not found")
    if stored.user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    ADDRESSES_DB.pop(address_id, None)
    return {"success": True, "message": "Address deleted"}


@router.get("/payment-accounts", response_model=List[PaymentAccountResponse])
async def list_payment_accounts(
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            rows = db.execute(
                text(
                    "SELECT * FROM payment_accounts WHERE user_id = :uid "
                    "ORDER BY is_default DESC, updated_at DESC, created_at DESC"
                ),
                {"uid": user_id},
            ).fetchall()
            return [_row_to_payment_account(row._mapping) for row in rows]
        except Exception as exc:
            handle_database_error(db, "read payment accounts", exc)

    require_database(db, "read payment accounts")

    accounts = [
        account
        for account in PAYMENT_ACCOUNTS_DB.values()
        if account.user_id == user_id
    ]
    accounts.sort(key=lambda item: (not item.is_default, -item.updated_at.timestamp()))
    return accounts


@router.post("/payment-accounts", response_model=PaymentAccountResponse)
async def create_payment_account(
    account: PaymentAccountCreate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)
    account_id = f"payacc_{uuid.uuid4().hex[:8]}"

    if db is not None:
        try:
            if account.is_default:
                db.execute(
                    text("UPDATE payment_accounts SET is_default = false WHERE user_id = :uid"),
                    {"uid": user_id},
                )

            db.execute(
                text(
                    "INSERT INTO payment_accounts ("
                    "id, user_id, account_type, account_name, account_number, "
                    "bank_name, qr_code_url, is_active, is_default"
                    ") VALUES ("
                    ":id, :uid, :type, :name, :number, :bank_name, :qr_code_url, "
                    ":is_active, :is_default"
                    ")"
                ),
                {
                    "id": account_id,
                    "uid": user_id,
                    "type": account.type,
                    "name": account.name,
                    "number": account.account_number,
                    "bank_name": account.bank_name,
                    "qr_code_url": account.qr_code_url,
                    "is_active": account.is_active,
                    "is_default": account.is_default,
                },
            )
            db.commit()
            row = db.execute(
                text("SELECT * FROM payment_accounts WHERE id = :id"),
                {"id": account_id},
            ).fetchone()
            return _row_to_payment_account(row._mapping)
        except Exception as exc:
            handle_database_error(db, "create payment account", exc)

    require_database(db, "create payment account")

    if account.is_default:
        for existing in list(PAYMENT_ACCOUNTS_DB.values()):
            if existing.user_id == user_id and existing.is_default:
                PAYMENT_ACCOUNTS_DB[existing.id] = existing.model_copy(
                    update={"is_default": False, "updated_at": datetime.now(timezone.utc)}
                )

    now = datetime.now(timezone.utc)
    created = PaymentAccountResponse(
        id=account_id,
        user_id=user_id,
        created_at=now,
        updated_at=now,
        **account.model_dump(),
    )
    PAYMENT_ACCOUNTS_DB[account_id] = created
    return created


@router.put("/payment-accounts/{account_id}", response_model=PaymentAccountResponse)
async def update_payment_account(
    account_id: str,
    account: PaymentAccountUpdate,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            row = db.execute(
                text("SELECT user_id FROM payment_accounts WHERE id = :id"),
                {"id": account_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Payment account not found")
            if row._mapping["user_id"] != user_id:
                raise HTTPException(status_code=403, detail="Forbidden")

            if account.is_default:
                db.execute(
                    text(
                        "UPDATE payment_accounts SET is_default = false "
                        "WHERE user_id = :uid AND id != :id"
                    ),
                    {"uid": user_id, "id": account_id},
                )

            result = db.execute(
                text(
                    "UPDATE payment_accounts SET "
                    "account_type = :type, account_name = :name, account_number = :number, "
                    "bank_name = :bank_name, qr_code_url = :qr_code_url, "
                    "is_active = :is_active, is_default = :is_default, updated_at = NOW() "
                    "WHERE id = :id AND user_id = :uid"
                ),
                {
                    "id": account_id,
                    "uid": user_id,
                    "type": account.type,
                    "name": account.name,
                    "number": account.account_number,
                    "bank_name": account.bank_name,
                    "qr_code_url": account.qr_code_url,
                    "is_active": account.is_active,
                    "is_default": account.is_default,
                },
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="Payment account not found")

            db.commit()
            updated_row = db.execute(
                text("SELECT * FROM payment_accounts WHERE id = :id"),
                {"id": account_id},
            ).fetchone()
            return _row_to_payment_account(updated_row._mapping)
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "update payment account", exc)

    require_database(db, "update payment account")

    stored = PAYMENT_ACCOUNTS_DB.get(account_id)
    if not stored:
        raise HTTPException(status_code=404, detail="Payment account not found")
    if stored.user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    if account.is_default:
        for existing in list(PAYMENT_ACCOUNTS_DB.values()):
            if existing.user_id == user_id and existing.id != account_id and existing.is_default:
                PAYMENT_ACCOUNTS_DB[existing.id] = existing.model_copy(
                    update={"is_default": False, "updated_at": datetime.now(timezone.utc)}
                )

    updated = PaymentAccountResponse(
        id=account_id,
        user_id=user_id,
        created_at=stored.created_at,
        updated_at=datetime.now(timezone.utc),
        **account.model_dump(),
    )
    PAYMENT_ACCOUNTS_DB[account_id] = updated
    return updated


@router.delete("/payment-accounts/{account_id}")
async def delete_payment_account(
    account_id: str,
    authorization: AuthorizationDep = None,
    db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if db is not None:
        try:
            row = db.execute(
                text("SELECT user_id FROM payment_accounts WHERE id = :id"),
                {"id": account_id},
            ).fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Payment account not found")
            if row._mapping["user_id"] != user_id:
                raise HTTPException(status_code=403, detail="Forbidden")

            result = db.execute(
                text("DELETE FROM payment_accounts WHERE id = :id AND user_id = :uid"),
                {"id": account_id, "uid": user_id},
            )
            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="Payment account not found")
            db.commit()
            return {"success": True}
        except HTTPException:
            raise
        except Exception as exc:
            handle_database_error(db, "delete payment account", exc)

    require_database(db, "delete payment account")

    stored = PAYMENT_ACCOUNTS_DB.get(account_id)
    if not stored:
        raise HTTPException(status_code=404, detail="Payment account not found")
    if stored.user_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    PAYMENT_ACCOUNTS_DB.pop(account_id, None)
    return {"success": True}
