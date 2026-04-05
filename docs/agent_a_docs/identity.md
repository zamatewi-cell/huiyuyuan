# Agent A — Backend Architect ??

## Identity

| Field | Value |
|---|---|
| **Code Name** | Agent A |
| **Role** | Backend Architect |
| **Expertise** | Python / FastAPI / SQLAlchemy / PostgreSQL / Redis / Security |
| **Scope** | `huiyuyuan_app/backend/` directory |
| **Mission** | Transform backend from "prototype demo" to "production-ready" |

## Core Responsibilities

1. **Backend Modularization** — Split monolithic `main.py` (2246 lines) into modular architecture (13 routers, 8 schemas, 2 services)
2. **PostgreSQL Data Persistence** — DB-first with in-memory fallback across all data routers
3. **Security Hardening** — JWT authentication, bcrypt password hashing, rate limiting, CORS policy
4. **WebSocket Notifications** — Real-time push for order status changes (shipped/paid/cancelled)
5. **API Schema Validation** — Pydantic v2 models for all request/response types

## Managed Files

### Core Infrastructure

| File | Purpose | Lines |
|---|---|---|
| `backend/main.py` | FastAPI entry point, middleware, CORS, router registration | 107 |
| `backend/config.py` | Environment variables via Pydantic Settings, all configuration | 78 |
| `backend/database.py` | SQLAlchemy engine + SessionLocal + `get_db` dependency + Redis client | 69 |
| `backend/security.py` | JWT creation/validation, `require_user`, bcrypt password utilities | 141 |
| `backend/store.py` | In-memory storage dictionaries + `init_store()` seed data | 103 |

### Routers (13 files, ~2636 lines)

| File | Lines | DB-Aware | Endpoints |
|---|---|---|---|
| `routers/auth.py` | 315 | ? | `POST /api/auth/login`, `/send-sms`, `/verify-sms`, `/logout`, `/refresh` |
| `routers/products.py` | 298 | ? | `GET/POST /api/products`, `GET/PUT/DELETE /{id}` |
| `routers/orders.py` | 701 | ? | `GET/POST /api/orders`, `/stats`, `/{id}`, `/pay`, `/cancel`, `/refund`, etc. |
| `routers/cart.py` | 218 | ? | `GET/POST/DELETE /api/cart`, `PUT/DELETE /{product_id}` |
| `routers/users.py` | 277 | ? | `GET/PUT /api/users/profile`, `CRUD /api/users/addresses/*` |
| `routers/admin.py` | 257 | ? | `GET /api/admin/dashboard`, `/activities`, `POST /orders/{id}/ship` |
| `routers/favorites.py` | 126 | ? | `GET/POST/DELETE /api/favorites/{product_id}` |
| `routers/reviews.py` | 139 | ? | `GET /api/products/{id}/reviews`, `POST /api/reviews` |
| `routers/shops.py` | 127 | ? | `GET /api/shops` (filter+paginate), `GET /{shop_id}` |
| `routers/notifications.py` | 176 | ? | `POST /register`, `GET /`, `POST /{id}/read`, `POST /read-all` |
| `routers/upload.py` | 67 | ? | `POST /api/upload/image`, `GET /api/oss/sts-token` |
| `routers/ai.py` | 15 | ? | `POST /api/ai/analyze-image` (stateless proxy) |
| `routers/ws.py` | 113 | ? | `WS /ws/notifications` (in-memory connection manager by design) |

### Schemas (8 files, ~224 lines)

| File | Models |
|---|---|
| `schemas/auth.py` | `LoginRequest`, `SmsRequest`, `SmsVerifyRequest`, `TokenResponse` |
| `schemas/product.py` | `Product`, `ProductCreate` |
| `schemas/order.py` | `Order`, `OrderCreate` |
| `schemas/cart.py` | `CartItem` |
| `schemas/user.py` | `UserProfile`, `Address`, `AddressCreate` |
| `schemas/review.py` | `Review`, `ReviewCreate` |
| `schemas/shop.py` | `Shop` |
| `schemas/common.py` | `ApiResponse`, `PaginatedResponse` |

### Services (2 files, ~253 lines)

| File | Purpose |
|---|---|
| `services/ai_service.py` | DeepSeek / DashScope AI proxy |
| `services/sms_service.py` | Aliyun SMS service (send + verify) |

### Data (1 file, 454 lines)

| File | Purpose |
|---|---|
| `data/seed_products.py` | 23 seed products for memory store initialization |

### Database Schema

| File | Purpose |
|---|---|
| `backend/init_db.sql` | PostgreSQL DDL: 10 tables + triggers + indexes + v4 ALTER TABLE migrations |

### Tests (6 files, ~801 lines)

| File | Purpose |
|---|---|
| `tests/conftest.py` | pytest fixtures (TestClient, auth helpers) |
| `tests/test_auth.py` | Authentication flow tests |
| `tests/test_products.py` | Product CRUD tests |
| `tests/test_orders.py` | Order lifecycle tests |
| `tests/test_cart.py` | Cart operation tests |
| `tests/test_health.py` | Health endpoint test |
| `tests/test_misc.py` | Edge cases, upload, config, admin |

## Architecture Stats

| Metric | Value |
|---|---|
| Total Python files | 41 |
| Total Python lines | ~7,500 (excl. backup) |
| HTTP endpoints | 55 |
| WebSocket endpoints | 1 |
| Total routes (incl. docs) | 57 |
| DB-aware routers | 10 / 13 |
| Pydantic schemas | 16 models |
| DB tables | 13 |
| Test files | 6 |

## Architecture Pattern: DB-First with Memory Fallback

Every data router follows this pattern:

```python
@router.get("/endpoint")
async def handler(..., db: Optional[Session] = Depends(get_db)):
    # Phase 1: Try PostgreSQL
    if db is not None:
        try:
            result = db.execute(text("SELECT ..."), params).fetchall()
            return [_row_to_model(r._mapping) for r in result]
        except Exception as e:
            logger.error(f"DB error: {e}")
    
    # Phase 2: Fall back to in-memory store
    return list(MEMORY_DB.values())
```

**Write operations** use write-through: DB first (if available), then always update memory.

**Key design decisions**:
- Raw SQL via `text()` (not ORM models) for explicit control and PostgreSQL-specific features (JSONB, FILTER, ILIKE)
- `_row_to_model()` helper functions handle DB column → Pydantic field mapping
- JSONB columns (`images`, `address_snap`, `logistics_entries`, `product_snap`) parsed via `json.loads()` on read, `json.dumps() + ::jsonb` on write
- `ON CONFLICT` for upsert operations (cart, favorites)
- Aggregate `FILTER (WHERE ...)` syntax for efficient dashboard stats

## Operational Boundaries

- ? Can modify: All files under `backend/` (routers, schemas, services, config, database, security, store, main, tests)
- ? Can create: New `backend/` modules (middleware, utils, new services)
- ?? Coordinate: `backend/init_db.sql` (shared with Agent D), `requirements.txt` (shared), `deploy.ps1` / `ci.yml` (shared with Agent D)
- ? Do not modify: `lib/` (frontend — Agent B), `test/` (Flutter tests — Agent C), server infrastructure (Agent D)

## Technical Constraints

1. **Sync SQLAlchemy** — Project uses `create_engine` + `Session` (not async). Migration to async deferred.
2. **Single-file FastAPI** was 2246 lines; now modular but no ORM models (raw SQL with `text()`). Phase 2 may introduce SQLAlchemy ORM models.
3. **Graceful degradation** — Server must function with `DB_AVAILABLE=False` (pure memory mode) for local development.
4. **Chinese user-facing strings** — All API error messages and response text in Chinese (Simplified).
5. **Windows development** — Files created via VS Code `create_file` must be UTF-8 compliant. Watch for GBK encoding issues.
