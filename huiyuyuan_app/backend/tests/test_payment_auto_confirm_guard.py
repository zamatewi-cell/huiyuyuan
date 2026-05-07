"""
Regression tests: payment safety guards.

1. The 0.01 auto-confirm shortcut must NOT be active in production.
2. The /orders/checkout endpoint must NOT return a live placeholder payment URL.

Run: pytest tests/test_payment_auto_confirm_guard.py -v
"""
import importlib
import re
import sys
import types
import unittest.mock as mock
from pathlib import Path

import pytest

BACKEND_ROOT = Path(__file__).parent.parent


class _TestOrder(dict):
    """Dict-shaped order that also supports attribute writes used by ORDERS_DB."""

    def __getattr__(self, name: str):
        try:
            return self[name]
        except KeyError as exc:
            raise AttributeError(name) from exc

    def __setattr__(self, name: str, value) -> None:
        self[name] = value


def _install_payment_create_fakes(monkeypatch, payments, order: _TestOrder):
    """Patch payment router dependencies for behavior-level auto-confirm tests."""
    created_record = {
        "payment_id": "pay-test-1",
        "order_id": "order-test-1",
        "user_id": "user-test-1",
        "status": payments.PAYMENT_STATUS_PENDING,
    }
    status_updates = []

    monkeypatch.setattr(payments, "IS_PRODUCTION", False)
    monkeypatch.setattr(payments, "ORDERS_DB", {"order-test-1": order})
    monkeypatch.setattr(payments, "require_user", lambda authorization: "user-test-1")
    monkeypatch.setattr(
        payments,
        "get_user_payments",
        lambda user_id, limit=100, db=None: [],
    )
    monkeypatch.setattr(
        payments,
        "create_payment_record",
        lambda **kwargs: {**created_record, "payment_method": kwargs["payment_method"]},
    )

    def fake_update_payment_status(payment_id, status, admin_id, admin_note, db=None):
        status_updates.append(
            {
                "payment_id": payment_id,
                "status": status,
                "admin_id": admin_id,
                "admin_note": admin_note,
            }
        )
        return {
            **created_record,
            "status": status,
            "admin_id": admin_id,
            "admin_note": admin_note,
        }

    monkeypatch.setattr(payments, "update_payment_status", fake_update_payment_status)
    return status_updates


# ---------------------------------------------------------------------------
# Helper: load payments router with a mocked IS_PRODUCTION value
# ---------------------------------------------------------------------------

def _load_payments_with_env(is_prod: bool):
    """Re-import the payments router module with IS_PRODUCTION patched."""
    # Remove cached modules so we get a clean import
    for key in list(sys.modules.keys()):
        if "payments" in key and "test" not in key:
            del sys.modules[key]

    with mock.patch.dict("sys.modules", {}):
        # Patch config.IS_PRODUCTION before the router imports it
        config_mock = types.ModuleType("config")
        config_mock.IS_PRODUCTION = is_prod  # type: ignore[attr-defined]
        config_mock.APP_ENV = "production" if is_prod else "development"
        sys.modules["config"] = config_mock

        # Minimal stubs for heavy dependencies
        for mod_name in [
            "database", "security", "models", "services.payment_service",
        ]:
            if mod_name not in sys.modules:
                sys.modules[mod_name] = types.ModuleType(mod_name)

        try:
            import routers.payments as pm  # noqa: PLC0415
            return pm
        finally:
            # Restore original config so other tests aren't affected
            if "config" in sys.modules and sys.modules["config"] is config_mock:
                del sys.modules["config"]


# ---------------------------------------------------------------------------
# Test 1 — 0.01 auto-confirm guard
# ---------------------------------------------------------------------------

class TestAutoConfirmGuard:
    """The `amount == 0.01` auto-confirm block must check IS_PRODUCTION."""

    def _auto_confirm_guard_source(self) -> str:
        source = (BACKEND_ROOT / "routers" / "payments.py").read_text(encoding="utf-8")
        match = re.search(
            r"auto_confirm_eligible\s*=\s*\((?P<guard>.*?)\)\s*# Auto-confirm",
            source,
            re.DOTALL,
        )
        assert match, "Could not locate the auto_confirm_eligible guard block"
        return match.group("guard")

    def test_guard_present_in_source(self) -> None:
        """Source code must contain the IS_PRODUCTION guard around amount==0.01."""
        guard = self._auto_confirm_guard_source()
        assert "not IS_PRODUCTION" in guard and "amount == 0.01" in guard, (
            "The 0.01 auto-confirm block in payments.py must be guarded by "
            "`not IS_PRODUCTION`. Found no such guard. This is a P0 security risk: "
            "a production payment of exactly ¥0.01 would be auto-confirmed without "
            "admin review."
        )

    def test_guard_is_negated(self) -> None:
        """The guard must use `not IS_PRODUCTION` (not `IS_PRODUCTION`)."""
        guard = self._auto_confirm_guard_source()
        assert "not IS_PRODUCTION" in guard, (
            "The IS_PRODUCTION guard for 0.01 auto-confirm must use `not IS_PRODUCTION`. "
            "A bare `IS_PRODUCTION` check would activate the shortcut only in production "
            "(the opposite of what we want)."
        )

    def test_guard_requires_test_payment_method_in_source(self) -> None:
        """Source code must limit the shortcut to explicit test payment methods."""
        source = (BACKEND_ROOT / "routers" / "payments.py").read_text(encoding="utf-8")
        assert "TEST_PAYMENT_METHODS" in source
        assert "test_alipay" in source
        assert "test_wechat" in source

    def test_guard_requires_explicit_test_order_in_source(self) -> None:
        """Source code must require an explicit test-order marker."""
        source = (BACKEND_ROOT / "routers" / "payments.py").read_text(encoding="utf-8")
        assert "_is_explicit_test_order(order)" in source

    @pytest.mark.asyncio
    async def test_normal_payment_method_does_not_auto_confirm_in_development(
        self,
        monkeypatch,
    ) -> None:
        """A real manual-voucher method must not auto-confirm even for amount 0.01."""
        from routers import payments

        order = _TestOrder(
            order_id="order-test-1",
            user_id="user-test-1",
            total_amount=0.01,
            is_test_order=True,
            status="pending",
        )
        status_updates = _install_payment_create_fakes(monkeypatch, payments, order)

        result = await payments.create_payment(
            order_id="order-test-1",
            payment_method="wechat",
            authorization="Bearer test",
            db=None,
        )

        assert result["payment"]["status"] == payments.PAYMENT_STATUS_PENDING
        assert "auto_confirmed" not in result["payment"]
        assert status_updates == []

    @pytest.mark.asyncio
    async def test_test_payment_method_requires_test_order_flag(
        self,
        monkeypatch,
    ) -> None:
        """A test method alone is not enough; the order must be marked as test."""
        from routers import payments

        order = _TestOrder(
            order_id="order-test-1",
            user_id="user-test-1",
            total_amount=0.01,
            status="pending",
        )
        status_updates = _install_payment_create_fakes(monkeypatch, payments, order)

        result = await payments.create_payment(
            order_id="order-test-1",
            payment_method="test_alipay",
            authorization="Bearer test",
            db=None,
        )

        assert result["payment"]["status"] == payments.PAYMENT_STATUS_PENDING
        assert "auto_confirmed" not in result["payment"]
        assert status_updates == []

    @pytest.mark.asyncio
    async def test_explicit_test_order_with_test_method_auto_confirms(
        self,
        monkeypatch,
    ) -> None:
        """The dev shortcut still works when both explicit test guards are present."""
        from routers import payments

        order = _TestOrder(
            order_id="order-test-1",
            user_id="user-test-1",
            total_amount=0.01,
            is_test_order=True,
            status="pending",
        )
        status_updates = _install_payment_create_fakes(monkeypatch, payments, order)

        result = await payments.create_payment(
            order_id="order-test-1",
            payment_method="test_alipay",
            authorization="Bearer test",
            db=None,
        )

        assert result["payment"]["status"] == payments.PAYMENT_STATUS_CONFIRMED
        assert result["payment"]["auto_confirmed"] is True
        assert order.status == "paid"
        assert len(status_updates) == 1

    def test_no_placeholder_payment_url_in_checkout(self) -> None:
        """The /checkout endpoint must not return a hardcoded pay.example.com URL."""
        source = (BACKEND_ROOT / "routers" / "orders.py").read_text(encoding="utf-8")
        bad_url = re.search(r"pay\.example\.com", source)
        assert bad_url is None, (
            "orders.py still contains a hardcoded placeholder payment URL "
            "(pay.example.com). This is a redirection risk. "
            "Replace with payment_url=None until a real gateway is integrated."
        )

    def test_checkout_payment_url_is_none(self) -> None:
        """The checkout endpoint's payment_url must be None (not a placeholder)."""
        source = (BACKEND_ROOT / "routers" / "orders.py").read_text(encoding="utf-8")
        # Find the checkout endpoint return statement
        checkout_block = re.search(
            r"async def checkout.*?return\s+\{[^}]+\}",
            source,
            re.DOTALL,
        )
        assert checkout_block, "Could not locate the checkout endpoint return block"
        block_text = checkout_block.group()
        assert '"payment_url": None' in block_text or "'payment_url': None" in block_text, (
            "checkout() must return payment_url=None. Found:\n" + block_text
        )


# ---------------------------------------------------------------------------
# Test 2 — backup files are gone (belt-and-suspenders, also in test_no_mojibake)
# ---------------------------------------------------------------------------

def test_no_live_payment_stub_url_anywhere() -> None:
    """No .py file should reference pay.example.com."""
    skip_dirs = {"venv", ".venv", "__pycache__", "migrations", ".git", "tests"}
    violations = []
    for path in BACKEND_ROOT.rglob("*.py"):
        if any(part in skip_dirs for part in path.parts):
            continue
        content = path.read_text(encoding="utf-8", errors="replace")
        if "pay.example.com" in content:
            violations.append(str(path.relative_to(BACKEND_ROOT)))
    assert not violations, (
        "pay.example.com placeholder URL found in:\n"
        + "\n".join(f"  • {v}" for v in violations)
    )
