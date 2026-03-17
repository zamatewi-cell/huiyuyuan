"""
User router - profile + address management
DB-first with in-memory fallback
"""

import uuid
import logging
from typing import Optional, List

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.user import UserResponse, Address, AddressCreate
from security import require_user
from database import get_db
from store import USERS_DB, ADDRESSES_DB

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/users", tags=["Users"])


# ============ Profile ============

@router.get("/profile")
async def get_profile(authorization: str = None, db: Optional[Session] = Depends(get_db)):
    user_id = require_user(authorization)

    if db is not None:
        try:
            row = db.execute(
                text(
                    "SELECT id, username, phone, user_type, balance, points, "
                    "avatar_url, operator_num "
                    "FROM users WHERE id = :id"
                ),
                {"id": user_id},
            ).fetchone()
            if row:
                m = row._mapping
                return UserResponse(
                    id=m["id"], username=m["username"], phone=m["phone"],
                    user_type=m["user_type"],
                    is_admin=(m["user_type"] == "admin"),
                    balance=float(m["balance"]),
                    points=m["points"],
                    avatar=m["avatar_url"],
                    operator_number=m["operator_num"],
                ).model_dump()
        except Exception as e:
            logger.error(f"DB get_profile: {e}")

    if user_id not in USERS_DB:
        raise HTTPException(status_code=404, detail="用户不存在")
    return UserResponse(**USERS_DB[user_id]).model_dump()


@router.put("/profile")
async def update_profile(
    data: dict, authorization: str = None, db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    allowed = {"username", "avatar"}
    updates = {k: v for k, v in data.items() if k in allowed}

    if db is not None and updates:
        try:
            set_parts = []
            params: dict = {"id": user_id}
            if "username" in updates:
                set_parts.append("username = :username")
                params["username"] = updates["username"]
            if "avatar" in updates:
                set_parts.append("avatar_url = :avatar")
                params["avatar"] = updates["avatar"]
            if set_parts:
                db.execute(
                    text(f"UPDATE users SET {', '.join(set_parts)} WHERE id = :id"),
                    params,
                )
                db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB update_profile: {e}")

    # Also update memory
    if user_id in USERS_DB:
        for key, value in updates.items():
            USERS_DB[user_id][key] = value
        return {"success": True, "user": UserResponse(**USERS_DB[user_id]).model_dump()}

    raise HTTPException(status_code=404, detail="用户不存在")


# ============ Addresses ============

def _row_to_address(m) -> Address:
    return Address(
        id=m["id"], user_id=m["user_id"],
        recipient_name=m["recipient_name"],
        phone_number=m["phone_number"],
        province=m["province"], city=m["city"],
        district=m["district"],
        detail_address=m["detail_address"],
        is_default=m["is_default"],
        postal_code=m.get("postal_code"),
        tag=m.get("tag"),
    )


@router.get("/addresses", response_model=List[Address])
async def get_addresses(authorization: str = None, db: Optional[Session] = Depends(get_db)):
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
            return [_row_to_address(r._mapping) for r in rows]
        except Exception as e:
            logger.error(f"DB get_addresses: {e}")

    addresses = [a for a in ADDRESSES_DB.values() if a.user_id == user_id]
    addresses.sort(key=lambda x: x.is_default, reverse=True)
    return addresses


@router.post("/addresses", response_model=Address)
async def create_address(
    address: AddressCreate, authorization: str = None,
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
                    " district, detail_address, postal_code, tag, is_default) "
                    "VALUES (:id,:uid,:name,:phone,:prov,:city,:dist,:detail,:zip,:tag,:def)"
                ),
                {
                    "id": address_id, "uid": user_id,
                    "name": address.recipient_name,
                    "phone": address.phone_number,
                    "prov": address.province, "city": address.city,
                    "dist": address.district, "detail": address.detail_address,
                    "zip": address.postal_code, "tag": address.tag,
                    "def": address.is_default,
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB create_address: {e}")

    # Memory write-through
    if address.is_default:
        for addr in ADDRESSES_DB.values():
            if addr.user_id == user_id:
                ADDRESSES_DB[addr.id] = Address(**{**addr.model_dump(), "is_default": False})

    new_address = Address(id=address_id, user_id=user_id, **address.model_dump())
    ADDRESSES_DB[address_id] = new_address
    return new_address


@router.put("/addresses/{address_id}", response_model=Address)
async def update_address(
    address_id: str, address: AddressCreate,
    authorization: str = None, db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    # Permission check (memory or DB)
    if address_id in ADDRESSES_DB:
        if ADDRESSES_DB[address_id].user_id != user_id:
            raise HTTPException(status_code=403, detail="没有权限")
    elif db is not None:
        row = db.execute(
            text("SELECT user_id FROM addresses WHERE id = :id"), {"id": address_id}
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="地址不存在")
        if row._mapping["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="没有权限")
    else:
        raise HTTPException(status_code=404, detail="地址不存在")

    if db is not None:
        try:
            if address.is_default:
                db.execute(
                    text("UPDATE addresses SET is_default = false WHERE user_id = :uid AND id != :id"),
                    {"uid": user_id, "id": address_id},
                )
            db.execute(
                text(
                    "UPDATE addresses SET "
                    "recipient_name=:name, phone_number=:phone, province=:prov, "
                    "city=:city, district=:dist, detail_address=:detail, "
                    "postal_code=:zip, tag=:tag, is_default=:def "
                    "WHERE id = :id AND user_id = :uid"
                ),
                {
                    "id": address_id, "uid": user_id,
                    "name": address.recipient_name, "phone": address.phone_number,
                    "prov": address.province, "city": address.city,
                    "dist": address.district, "detail": address.detail_address,
                    "zip": address.postal_code, "tag": address.tag,
                    "def": address.is_default,
                },
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB update_address: {e}")

    # Memory write-through
    if address.is_default:
        for addr in ADDRESSES_DB.values():
            if addr.user_id == user_id and addr.id != address_id:
                ADDRESSES_DB[addr.id] = Address(**{**addr.model_dump(), "is_default": False})

    updated = Address(id=address_id, user_id=user_id, **address.model_dump())
    ADDRESSES_DB[address_id] = updated
    return updated


@router.delete("/addresses/{address_id}")
async def delete_address(
    address_id: str, authorization: str = None, db: Optional[Session] = Depends(get_db),
):
    user_id = require_user(authorization)

    if address_id in ADDRESSES_DB:
        if ADDRESSES_DB[address_id].user_id != user_id:
            raise HTTPException(status_code=403, detail="没有权限")
    elif db is not None:
        row = db.execute(
            text("SELECT user_id FROM addresses WHERE id = :id"), {"id": address_id}
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="地址不存在")
        if row._mapping["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="没有权限")
    else:
        raise HTTPException(status_code=404, detail="地址不存在")

    if db is not None:
        try:
            db.execute(
                text("DELETE FROM addresses WHERE id = :id AND user_id = :uid"),
                {"id": address_id, "uid": user_id},
            )
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"DB delete_address: {e}")

    ADDRESSES_DB.pop(address_id, None)
    return {"success": True, "message": "地址已删除"}
