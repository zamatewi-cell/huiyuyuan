"""Database bootstrap and runtime security tests."""

from importlib import util
from pathlib import Path
from types import ModuleType
from uuid import uuid4
import sys

import pytest
from httpx import AsyncClient

import database
from main import app
from store import TOKENS_DB


DATABASE_PATH = Path(__file__).resolve().parents[1] / "database.py"


def _make_config(*, database_url: str, is_production: bool) -> ModuleType:
    module = ModuleType("config")
    module.DATABASE_URL = database_url
    module.REDIS_URL = "redis://localhost:6379/0"
    module.IS_PRODUCTION = is_production
    return module


def _load_database_module(config_module: ModuleType):
    module_name = f"database_under_test_{uuid4().hex}"
    spec = util.spec_from_file_location(module_name, DATABASE_PATH)
    module = util.module_from_spec(spec)
    assert spec.loader is not None

    previous = sys.modules.get("config")
    sys.modules["config"] = config_module
    try:
        spec.loader.exec_module(module)
        return module
    finally:
        if previous is not None:
            sys.modules["config"] = previous
        else:
            sys.modules.pop("config", None)


class BrokenSession:
    def __init__(self):
        self.rolled_back = False

    def execute(self, *_args, **_kwargs):
        raise RuntimeError("db exploded")

    def rollback(self):
        self.rolled_back = True


@pytest.fixture
def production_auth() -> str:
    token = "prod-guard-token"
    TOKENS_DB[token] = "admin_001"
    return f"Bearer {token}"


@pytest.fixture
def force_production_without_database(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setattr(database, "IS_PRODUCTION", True)
    app.dependency_overrides[database.get_db] = lambda: None
    try:
        yield
    finally:
        app.dependency_overrides.pop(database.get_db, None)


def test_production_requires_database_url():
    config_module = _make_config(database_url="", is_production=True)

    with pytest.raises(RuntimeError, match="DATABASE_URL"):
        _load_database_module(config_module)


def test_development_allows_missing_database_url():
    config_module = _make_config(database_url="", is_production=False)

    module = _load_database_module(config_module)
    assert module.DB_AVAILABLE is False
    assert module.SessionLocal is None


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("method", "url", "payload"),
    [
        ("get", "/api/products", None),
        ("get", "/api/products/HYY-HT001", None),
        ("get", "/api/shops", None),
        ("get", "/api/shops/SHOP_PROD_TEST", None),
        ("get", "/api/cart", None),
        ("post", "/api/favorites/HYY-HT001", None),
        ("get", "/api/orders", None),
        (
            "post",
            "/api/orders",
            {
                "items": [{"product_id": "HYY-HT001", "quantity": 1}],
                "address_id": "addr_prod_only",
                "payment_method": "wechat",
            },
        ),
        ("post", "/api/admin/orders/ORD_PROD_TEST/ship", {"carrier": "SF"}),
        (
            "post",
            "/api/products",
            {
                "name": "Prod Only",
                "description": "guarded",
                "price": 100.0,
                "category": "手链",
                "material": "和田玉",
                "stock": 10,
            },
        ),
        ("get", "/api/products/HYY-HT001/reviews", None),
        (
            "post",
            "/api/reviews",
            {
                "product_id": "HYY-HT001",
                "order_id": "ORD_PROD_REVIEW",
                "rating": 5,
                "content": "guarded",
                "images": [],
            },
        ),
        ("put", "/api/users/profile", {"username": "Prod Name"}),
        (
            "post",
            "/api/users/addresses",
            {
                "recipient_name": "Zhang San",
                "phone_number": "13800001234",
                "province": "Zhejiang",
                "city": "Hangzhou",
                "district": "Xihu",
                "detail_address": "No.100 Test Road",
                "is_default": True,
            },
        ),
        ("get", "/api/notifications", None),
    ],
)
async def test_runtime_routes_refuse_memory_fallback_in_production(
    client: AsyncClient,
    production_auth: str,
    force_production_without_database,
    method: str,
    url: str,
    payload: dict | None,
):
    request = getattr(client, method)
    kwargs = {"headers": {"Authorization": production_auth}}
    if payload is not None:
        kwargs["json"] = payload

    response = await request(url, **kwargs)

    assert response.status_code == 503
    assert "数据库" in response.json()["detail"]


@pytest.mark.asyncio
async def test_database_exceptions_return_503_in_production(
    client: AsyncClient,
    production_auth: str,
    monkeypatch: pytest.MonkeyPatch,
):
    broken_session = BrokenSession()
    monkeypatch.setattr(database, "IS_PRODUCTION", True)
    app.dependency_overrides[database.get_db] = lambda: broken_session

    try:
        response = await client.get(
            "/api/cart",
            headers={"Authorization": production_auth},
        )
    finally:
        app.dependency_overrides.pop(database.get_db, None)

    assert response.status_code == 503
    assert response.json()["detail"] == "读取购物车失败，请稍后重试"
    assert broken_session.rolled_back is True
