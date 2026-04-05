# -*- coding: utf-8 -*-
"""Import seed product payloads into PostgreSQL."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from database import DB_AVAILABLE, SessionLocal
from services.product_seed_import_service import (
    DEFAULT_SHARED_SEED_PAYLOAD_PATH,
    load_default_seed_payloads,
    load_seed_payload_file,
    upsert_seed_products,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Import product seed payloads into the products table.",
    )
    source_group = parser.add_mutually_exclusive_group()
    source_group.add_argument(
        "--from-json",
        dest="json_path",
        help="Load frontend/exported seed payloads from a JSON file.",
    )
    source_group.add_argument(
        "--from-repo-seed",
        action="store_true",
        help="Load the checked-in shared JSON seed file from backend/data.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and print a short summary without writing to the database.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.json_path:
        payloads = load_seed_payload_file(args.json_path)
        source_label = args.json_path
    elif args.from_repo_seed:
        payloads = load_seed_payload_file(DEFAULT_SHARED_SEED_PAYLOAD_PATH)
        source_label = str(DEFAULT_SHARED_SEED_PAYLOAD_PATH)
    else:
        payloads = load_default_seed_payloads()
        source_label = str(DEFAULT_SHARED_SEED_PAYLOAD_PATH)

    if args.dry_run:
        preview = {
            "source": source_label,
            "total": len(payloads),
            "first_id": payloads[0]["id"] if payloads else None,
            "last_id": payloads[-1]["id"] if payloads else None,
        }
        print(json.dumps(preview, ensure_ascii=False, indent=2))
        return 0

    if not DB_AVAILABLE or SessionLocal is None:
        parser.error("Database is unavailable. Configure DATABASE_URL before importing seed products.")

    db = SessionLocal()
    try:
        imported_count = upsert_seed_products(db, payloads)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    print(
        json.dumps(
            {
                "source": source_label,
                "imported": imported_count,
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
