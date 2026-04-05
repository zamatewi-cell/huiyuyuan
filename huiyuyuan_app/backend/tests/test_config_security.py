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


def test_dashscope_key_rejects_openrouter_style_key(
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setenv("APP_ENV", "development")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("ALLOWED_ORIGINS", "https://app.example.com")
    monkeypatch.setenv("DASHSCOPE_API_KEY", "")
    monkeypatch.setenv("OPENROUTER_API_KEY", "sk-or-legacy-key")

    module = _load_config_module()
    assert module.DASHSCOPE_API_KEY == ""
    assert "OpenRouter key" in module.DASHSCOPE_API_KEY_ISSUE


def test_dashscope_key_accepts_legacy_env_name_with_dashscope_value(
    monkeypatch: pytest.MonkeyPatch,
):
    monkeypatch.setenv("APP_ENV", "development")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("ALLOWED_ORIGINS", "https://app.example.com")
    monkeypatch.setenv("DASHSCOPE_API_KEY", "")
    monkeypatch.setenv("OPENROUTER_API_KEY", "sk-dashscope-legacy-alias")

    module = _load_config_module()
    assert module.DASHSCOPE_API_KEY == "sk-dashscope-legacy-alias"
    assert module.DASHSCOPE_API_KEY_ISSUE is None
