# -*- coding: utf-8 -*-
"""Tests for backend seed import helpers."""

import json
import pytest

from pathlib import Path

from data.seed_products import SEED_PRODUCTS
from services.product_seed_import_service import (
    DEFAULT_SHARED_SEED_PAYLOAD_PATH,
    DEFAULT_BACKEND_SEED_SOURCE,
    build_backend_seed_import_payloads,
    build_in_memory_seed_products,
    load_default_seed_payloads,
    load_seed_payload_file,
    normalize_seed_payload,
    prepare_upsert_rows,
)


def _sample_payload(**overrides):
    payload = {
        "id": "HYY-T001",
        "name": "Test Product",
        "description": "Seed import test product",
        "price": 199.0,
        "original_price": 299.0,
        "category": "bracelet",
        "material": "jade",
        "images": ["https://example.com/p1.png"],
        "stock": 12,
        "rating": 4.8,
        "sales_count": 34,
        "is_hot": True,
        "is_new": False,
        "is_welfare": True,
        "origin": "CN",
        "certificate": "CERT-001",
        "blockchain_hash": None,
        "material_verify": "verified",
    }
    payload.update(overrides)
    return payload


def test_normalize_seed_payload_strips_frontend_metadata():
    payload = _sample_payload(
        seed_id="HYY-T001",
        seed_source="base",
        sort_order=1,
        source_order=1,
        is_active=False,
    )

    normalized = normalize_seed_payload(payload)

    assert "seed_id" not in normalized
    assert "seed_source" not in normalized
    assert normalized["id"] == "HYY-T001"
    assert normalized["images"] == ["https://example.com/p1.png"]
    assert normalized["is_active"] is False
    assert normalized["blockchain_hash"] is None


def test_build_backend_seed_import_payloads_adds_sequential_metadata():
    payloads = build_backend_seed_import_payloads([
        _sample_payload(id="HYY-T001"),
        _sample_payload(id="HYY-T002"),
    ])

    assert [item["seed_source"] for item in payloads] == [
        DEFAULT_BACKEND_SEED_SOURCE,
        DEFAULT_BACKEND_SEED_SOURCE,
    ]
    assert [item["seed_id"] for item in payloads] == ["HYY-T001", "HYY-T002"]
    assert [item["sort_order"] for item in payloads] == [1, 2]
    assert [item["source_order"] for item in payloads] == [1, 2]


def test_build_in_memory_seed_products_assigns_stable_blockchain_hash():
    payloads = build_backend_seed_import_payloads([
        _sample_payload(id="HYY-T001", blockchain_hash=None),
    ])

    first_pass = build_in_memory_seed_products(payloads)
    second_pass = build_in_memory_seed_products(payloads)

    assert first_pass[0].blockchain_hash
    assert first_pass[0].blockchain_hash.startswith("0x")
    assert len(first_pass[0].blockchain_hash) == 42
    assert first_pass[0].blockchain_hash == second_pass[0].blockchain_hash


def test_prepare_upsert_rows_serializes_images_json():
    rows = prepare_upsert_rows([
        _sample_payload(seed_id="HYY-T001", seed_source="base"),
    ])

    assert len(rows) == 1
    assert rows[0]["is_active"] is True
    assert rows[0]["blockchain_hash"].startswith("0x")
    assert rows[0]["images"] == json.dumps(
        ["https://example.com/p1.png"],
        ensure_ascii=False,
    )


def test_load_seed_payload_file_supports_frontend_export_shape(tmp_path):
    seed_file = tmp_path / "seed.json"
    seed_file.write_text(
        json.dumps(
            {
                "products": [
                    _sample_payload(
                        seed_id="HYY-T001",
                        seed_source="base",
                        sort_order=1,
                        source_order=1,
                    ),
                ],
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    payloads = load_seed_payload_file(seed_file)

    assert len(payloads) == 1
    assert payloads[0]["id"] == "HYY-T001"
    assert "seed_id" not in payloads[0]


def test_load_default_seed_payloads_prefers_repo_json(tmp_path, monkeypatch):
    seed_file = tmp_path / "repo-seed.json"
    seed_file.write_text(
        json.dumps([
            _sample_payload(
                seed_id="HYY-T001",
                seed_source="base",
                sort_order=1,
                source_order=1,
            ),
        ], ensure_ascii=False),
        encoding="utf-8",
    )

    monkeypatch.setattr(
        "services.product_seed_import_service.DEFAULT_SHARED_SEED_PAYLOAD_PATH",
        seed_file,
    )

    payloads = load_default_seed_payloads()

    assert payloads[0]["id"] == "HYY-T001"


def test_load_default_seed_payloads_requires_shared_json(monkeypatch):
    monkeypatch.setattr(
        "services.product_seed_import_service.DEFAULT_SHARED_SEED_PAYLOAD_PATH",
        DEFAULT_SHARED_SEED_PAYLOAD_PATH.with_name("missing_seed.json"),
    )

    with pytest.raises(FileNotFoundError) as exc_info:
        load_default_seed_payloads()

    assert "missing_seed.json" in str(exc_info.value)


def test_data_seed_products_adapter_reads_shared_json():
    assert isinstance(SEED_PRODUCTS, list)
    assert len(SEED_PRODUCTS) > 0
    assert "seed_id" not in SEED_PRODUCTS[0]
    assert SEED_PRODUCTS[0]["id"] == "HYY-HT001"
    assert Path(DEFAULT_SHARED_SEED_PAYLOAD_PATH).exists()
