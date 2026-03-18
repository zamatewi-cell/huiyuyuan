"""Configuration security tests."""

from importlib import util
from pathlib import Path
from uuid import uuid4

import pytest


CONFIG_PATH = Path(__file__).resolve().parents[1] / "config.py"


def _load_config_module():
    module_name = f"config_under_test_{uuid4().hex}"
    spec = util.spec_from_file_location(module_name, CONFIG_PATH)
    module = util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_production_requires_jwt_secret(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET_KEY", "")
    monkeypatch.setenv("ALLOWED_ORIGINS", "https://app.example.com")

    with pytest.raises(RuntimeError, match="JWT_SECRET_KEY"):
        _load_config_module()


def test_production_rejects_wildcard_cors(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("ALLOWED_ORIGINS", "*")

    with pytest.raises(RuntimeError, match="ALLOWED_ORIGINS"):
        _load_config_module()


def test_explicit_cors_origins_are_normalized(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv(
        "ALLOWED_ORIGINS",
        " https://app.example.com,https://admin.example.com,https://app.example.com ",
    )

    module = _load_config_module()
    assert module.ALLOWED_ORIGINS == [
        "https://app.example.com",
        "https://admin.example.com",
    ]
