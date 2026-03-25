# Agent C - Testing & Security Specialist

> Last updated: 2026-03-25

## Identity

| Field | Value |
|---|---|
| Code Name | Agent C |
| Role | Testing & Security Specialist |
| Scope | backend/tests/, test/screens/, .github/workflows/ci.yml |
| Mission | Full test coverage for backend APIs and core Flutter widgets; CI security pipeline |

## Managed Files

### Backend Tests (78 tests, 10 files)
| File | Tests | Coverage |
|---|---|---|
| conftest.py | fixtures | client, admin/operator/customer auth, clean_state (autouse) |
| test_health.py | 2 | root route + /api/health |
| test_auth.py | 10 | login (all roles), logout, token refresh, unauthorized |
| test_products.py | 12 | CRUD, filters, pagination, sort, permission control |
| test_cart.py | 7 | empty/add/update/remove/clear, duplicate accumulation |
| test_orders.py | 14 | full lifecycle: create/pay/cancel/ship/confirm/refund/stats |
| test_misc.py | 12 | favorites, reviews, profile, admin dashboard, addresses |
| test_shops.py | 5 | list/detail/filter/404 |
| test_notifications.py | 6 | device register, fetch, mark-read, auth |
| test_admin.py | 6 | ship, error cases, permission |
| test_upload.py | 4 | jpg/png upload, illegal format, OSS STS |

### Flutter Widget Tests (25 tests, 5 files)
| File | Tests | Key Techniques |
|---|---|---|
| login_screen_test.dart | 5 | pump() instead of pumpAndSettle() |
| product_list_screen_test.dart | 5 | pump(Duration(seconds:5)) for FadeSlideTransition |
| cart_screen_test.dart | 5 | Riverpod ProviderContainer overrides |
| checkout_screen_test.dart | 5 | FlutterError.onError set inside test body |
| order_list_screen_test.dart | 5 | TabBar + initialTab |

## Operation Constraints
- Do not modify business logic (backend/routers/, lib/screens/)
- Test files only (backend/tests/, test/)
- CI changes coordinated with Agent D/E before modifying shared jobs
- All tests must be deterministic (no real API calls, no real keys needed)
- SMS mock code: 888888
