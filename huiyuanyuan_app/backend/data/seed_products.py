# -*- coding: utf-8 -*-
"""Backward-compatible Python adapter for the shared product seed JSON."""

from __future__ import annotations

from pathlib import Path

from services.product_seed_import_service import load_seed_payload_file

_SHARED_SEED_PATH = Path(__file__).resolve().with_name("product_seed_payloads.json")

SEED_PRODUCTS = load_seed_payload_file(_SHARED_SEED_PATH)
