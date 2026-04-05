"""Allowed host configuration tests."""

from importlib import util
from pathlib import Path
from uuid import uuid4

import pytest


CONFIG_PATH = Path(__file__).resolve().parents[1] / "config.py"


def _load_config_module():
    module_name = f"config_hosts_under_test_{uuid4().hex}"
    spec = util.spec_from_file_location(module_name, CONFIG_PATH)
    module = util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_production_derives_allowed_hosts_from_cors_origins(
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv(
        "ALLOWED_ORIGINS",
        "https://app.example.com,https://admin.example.com",
    )
    monkeypatch.delenv("ALLOWED_HOSTS", raising=False)

    module = _load_config_module()
    assert module.ALLOWED_HOSTS == [
        "app.example.com",
        "admin.example.com",
        "127.0.0.1",
        "localhost",
    ]


def test_explicit_allowed_hosts_are_normalized(
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("ALLOWED_ORIGINS", "https://app.example.com")
    monkeypatch.setenv(
        "ALLOWED_HOSTS",
        " https://app.example.com,admin.example.com:443,app.example.com ",
    )

    module = _load_config_module()
    assert module.ALLOWED_HOSTS == [
        "app.example.com",
        "admin.example.com",
        "127.0.0.1",
        "localhost",
    ]
