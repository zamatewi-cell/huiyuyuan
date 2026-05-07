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
from services.product_media_service import sanitize_product_images

DEFAULT_SHARED_SEED_PAYLOAD_PATH = (
    Path(__file__).resolve().parents[1] / "data" / "product_seed_payloads.json"
)

SEED_METADATA_FIELDS = frozenset({
    "seed_id",
    "seed_source",
    "sort_order",
    "source_order",
})

PRODUCT_SEED_JSONB_FIELDS = frozenset({
    "images",
    "craft_highlights",
    "craft_highlights_en",
    "craft_highlights_zh_tw",
    "audience_tags",
    "audience_tags_en",
    "audience_tags_zh_tw",
    "flaw_notes",
    "flaw_notes_en",
    "flaw_notes_zh_tw",
    "gallery_detail",
    "gallery_hand",
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
    is_active,
    name_en, name_zh_tw,
    description_en, description_zh_tw,
    category_en, category_zh_tw,
    material_en, material_zh_tw,
    origin_en, origin_zh_tw,
    material_verify_en, material_verify_zh_tw,
    appraisal_note, appraisal_note_en, appraisal_note_zh_tw,
    craft_highlights, craft_highlights_en, craft_highlights_zh_tw,
    weight_g,
    dimensions,
    audience_tags, audience_tags_en, audience_tags_zh_tw,
    origin_story, origin_story_en, origin_story_zh_tw,
    flaw_notes, flaw_notes_en, flaw_notes_zh_tw,
    certificate_authority, certificate_authority_en, certificate_authority_zh_tw,
    certificate_image_url,
    certificate_verify_url,
    gallery_detail,
    gallery_hand
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
    :is_active,
    :name_en, :name_zh_tw,
    :description_en, :description_zh_tw,
    :category_en, :category_zh_tw,
    :material_en, :material_zh_tw,
    :origin_en, :origin_zh_tw,
    :material_verify_en, :material_verify_zh_tw,
    :appraisal_note, :appraisal_note_en, :appraisal_note_zh_tw,
    CAST(:craft_highlights AS JSONB), CAST(:craft_highlights_en AS JSONB), CAST(:craft_highlights_zh_tw AS JSONB),
    :weight_g,
    :dimensions,
    CAST(:audience_tags AS JSONB), CAST(:audience_tags_en AS JSONB), CAST(:audience_tags_zh_tw AS JSONB),
    :origin_story, :origin_story_en, :origin_story_zh_tw,
    CAST(:flaw_notes AS JSONB), CAST(:flaw_notes_en AS JSONB), CAST(:flaw_notes_zh_tw AS JSONB),
    :certificate_authority, :certificate_authority_en, :certificate_authority_zh_tw,
    :certificate_image_url,
    :certificate_verify_url,
    CAST(:gallery_detail AS JSONB),
    CAST(:gallery_hand AS JSONB)
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
    name_en = COALESCE(EXCLUDED.name_en, products.name_en),
    name_zh_tw = COALESCE(EXCLUDED.name_zh_tw, products.name_zh_tw),
    description_en = COALESCE(EXCLUDED.description_en, products.description_en),
    description_zh_tw = COALESCE(EXCLUDED.description_zh_tw, products.description_zh_tw),
    category_en = COALESCE(EXCLUDED.category_en, products.category_en),
    category_zh_tw = COALESCE(EXCLUDED.category_zh_tw, products.category_zh_tw),
    material_en = COALESCE(EXCLUDED.material_en, products.material_en),
    material_zh_tw = COALESCE(EXCLUDED.material_zh_tw, products.material_zh_tw),
    origin_en = COALESCE(EXCLUDED.origin_en, products.origin_en),
    origin_zh_tw = COALESCE(EXCLUDED.origin_zh_tw, products.origin_zh_tw),
    material_verify_en = COALESCE(EXCLUDED.material_verify_en, products.material_verify_en),
    material_verify_zh_tw = COALESCE(EXCLUDED.material_verify_zh_tw, products.material_verify_zh_tw),
    appraisal_note = COALESCE(EXCLUDED.appraisal_note, products.appraisal_note),
    appraisal_note_en = COALESCE(EXCLUDED.appraisal_note_en, products.appraisal_note_en),
    appraisal_note_zh_tw = COALESCE(EXCLUDED.appraisal_note_zh_tw, products.appraisal_note_zh_tw),
    craft_highlights = COALESCE(EXCLUDED.craft_highlights, products.craft_highlights),
    craft_highlights_en = COALESCE(EXCLUDED.craft_highlights_en, products.craft_highlights_en),
    craft_highlights_zh_tw = COALESCE(EXCLUDED.craft_highlights_zh_tw, products.craft_highlights_zh_tw),
    weight_g = COALESCE(EXCLUDED.weight_g, products.weight_g),
    dimensions = COALESCE(EXCLUDED.dimensions, products.dimensions),
    audience_tags = COALESCE(EXCLUDED.audience_tags, products.audience_tags),
    audience_tags_en = COALESCE(EXCLUDED.audience_tags_en, products.audience_tags_en),
    audience_tags_zh_tw = COALESCE(EXCLUDED.audience_tags_zh_tw, products.audience_tags_zh_tw),
    origin_story = COALESCE(EXCLUDED.origin_story, products.origin_story),
    origin_story_en = COALESCE(EXCLUDED.origin_story_en, products.origin_story_en),
    origin_story_zh_tw = COALESCE(EXCLUDED.origin_story_zh_tw, products.origin_story_zh_tw),
    flaw_notes = COALESCE(EXCLUDED.flaw_notes, products.flaw_notes),
    flaw_notes_en = COALESCE(EXCLUDED.flaw_notes_en, products.flaw_notes_en),
    flaw_notes_zh_tw = COALESCE(EXCLUDED.flaw_notes_zh_tw, products.flaw_notes_zh_tw),
    certificate_authority = COALESCE(EXCLUDED.certificate_authority, products.certificate_authority),
    certificate_authority_en = COALESCE(EXCLUDED.certificate_authority_en, products.certificate_authority_en),
    certificate_authority_zh_tw = COALESCE(EXCLUDED.certificate_authority_zh_tw, products.certificate_authority_zh_tw),
    certificate_image_url = COALESCE(EXCLUDED.certificate_image_url, products.certificate_image_url),
    certificate_verify_url = COALESCE(EXCLUDED.certificate_verify_url, products.certificate_verify_url),
    gallery_detail = COALESCE(EXCLUDED.gallery_detail, products.gallery_detail),
    gallery_hand = COALESCE(EXCLUDED.gallery_hand, products.gallery_hand),
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
    normalized["images"] = sanitize_product_images(
        normalized.get("images"),
        normalized.get("material"),
    )
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
        row = dict(normalized)
        for field in PRODUCT_SEED_JSONB_FIELDS:
            row[field] = _serialize_jsonb_param(
                row.get(field),
                empty_list_when_none=field == "images",
            )
        rows.append(row)
    return rows


def _serialize_jsonb_param(
    value: Any,
    *,
    empty_list_when_none: bool = False,
) -> str | None:
    if value is None:
        if empty_list_when_none:
            return json.dumps([], ensure_ascii=False)
        return None
    return json.dumps(value, ensure_ascii=False)


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
