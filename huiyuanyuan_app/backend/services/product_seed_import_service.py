# -*- coding: utf-8 -*-
"""Helpers for importing product seed payloads into memory or PostgreSQL."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

from sqlalchemy import text
from sqlalchemy.orm import Session

from schemas.product import Product

DEFAULT_SHARED_SEED_PAYLOAD_PATH = (
    Path(__file__).resolve().parents[1] / "data" / "product_seed_payloads.json"
)

SEED_METADATA_FIELDS = frozenset({
    "seed_id",
    "seed_source",
    "sort_order",
    "source_order",
})

DEFAULT_BACKEND_SEED_SOURCE = "backend_legacy"

PRODUCT_SEED_UPSERT_SQL = """
INSERT INTO products (
    id,
    name,
    description,
    price,
    original_price,
    category,
    material,
    images,
    stock,
    rating,
    sales_count,
    is_hot,
    is_new,
    is_welfare,
    origin,
    certificate,
    blockchain_hash,
    material_verify,
    is_active
) VALUES (
    :id,
    :name,
    :description,
    :price,
    :original_price,
    :category,
    :material,
    CAST(:images AS JSONB),
    :stock,
    :rating,
    :sales_count,
    :is_hot,
    :is_new,
    :is_welfare,
    :origin,
    :certificate,
    :blockchain_hash,
    :material_verify,
    :is_active
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    category = EXCLUDED.category,
    material = EXCLUDED.material,
    images = EXCLUDED.images,
    stock = EXCLUDED.stock,
    rating = EXCLUDED.rating,
    sales_count = EXCLUDED.sales_count,
    is_hot = EXCLUDED.is_hot,
    is_new = EXCLUDED.is_new,
    is_welfare = EXCLUDED.is_welfare,
    origin = EXCLUDED.origin,
    certificate = EXCLUDED.certificate,
    blockchain_hash = COALESCE(EXCLUDED.blockchain_hash, products.blockchain_hash),
    material_verify = EXCLUDED.material_verify,
    is_active = EXCLUDED.is_active,
    updated_at = NOW()
"""


def strip_seed_metadata(payload: Mapping[str, Any]) -> dict[str, Any]:
    return {
        key: value
        for key, value in payload.items()
        if key not in SEED_METADATA_FIELDS
    }


def build_backend_seed_import_payloads(
    seed_products: Sequence[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    payloads: list[dict[str, Any]] = []
    for index, product in enumerate(seed_products, start=1):
        payload = dict(product)
        payload.setdefault("seed_id", str(product["id"]))
        payload.setdefault("seed_source", DEFAULT_BACKEND_SEED_SOURCE)
        payload.setdefault("sort_order", index)
        payload.setdefault("source_order", index)
        payloads.append(payload)
    return payloads


def build_seed_blockchain_hash(product_id: str) -> str:
    return f"0x{hashlib.sha1(product_id.encode('utf-8')).hexdigest()}"


def normalize_seed_payload(
    payload: Mapping[str, Any],
    *,
    ensure_blockchain_hash: bool = False,
) -> dict[str, Any]:
    product_data = strip_seed_metadata(payload)
    normalized = Product(**product_data).model_dump()
    normalized["is_active"] = bool(product_data.get("is_active", True))

    if ensure_blockchain_hash and not normalized.get("blockchain_hash"):
        normalized["blockchain_hash"] = build_seed_blockchain_hash(normalized["id"])

    return normalized


def normalize_seed_payloads(
    payloads: Iterable[Mapping[str, Any]],
    *,
    ensure_blockchain_hash: bool = False,
) -> list[dict[str, Any]]:
    return [
        normalize_seed_payload(
            payload,
            ensure_blockchain_hash=ensure_blockchain_hash,
        )
        for payload in payloads
    ]


def prepare_upsert_rows(
    payloads: Iterable[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for payload in payloads:
        normalized = normalize_seed_payload(
            payload,
            ensure_blockchain_hash=True,
        )
        rows.append({
            **normalized,
            "images": json.dumps(normalized["images"], ensure_ascii=False),
        })
    return rows


def upsert_seed_products(
    db: Session,
    payloads: Iterable[Mapping[str, Any]],
) -> int:
    rows = prepare_upsert_rows(payloads)
    if not rows:
        return 0

    db.execute(text(PRODUCT_SEED_UPSERT_SQL), rows)
    return len(rows)


def load_seed_payload_file(path: str | Path) -> list[dict[str, Any]]:
    raw_content = Path(path).read_text(encoding="utf-8")
    parsed = json.loads(raw_content)

    if isinstance(parsed, dict):
        if isinstance(parsed.get("products"), list):
            parsed = parsed["products"]
        elif isinstance(parsed.get("items"), list):
            parsed = parsed["items"]
        else:
            raise ValueError("Seed payload JSON must contain a list or a products/items list field.")

    if not isinstance(parsed, list):
        raise ValueError("Seed payload JSON must resolve to a list of products.")

    return normalize_seed_payloads(parsed)


def load_default_seed_payloads(
    path: str | Path | None = None,
) -> list[dict[str, Any]]:
    seed_path = Path(path) if path is not None else DEFAULT_SHARED_SEED_PAYLOAD_PATH
    if not seed_path.exists():
        raise FileNotFoundError(
            f"Shared product seed payload file not found: {seed_path}",
        )
    return load_seed_payload_file(seed_path)


def load_backend_seed_payloads() -> list[dict[str, Any]]:
    return load_default_seed_payloads()


def build_in_memory_seed_products(
    payloads: Iterable[Mapping[str, Any]] | None = None,
) -> list[Product]:
    source_payloads = (
        list(payloads) if payloads is not None else load_default_seed_payloads()
    )
    return [
        Product(**payload)
        for payload in normalize_seed_payloads(
            source_payloads,
            ensure_blockchain_hash=True,
        )
    ]
