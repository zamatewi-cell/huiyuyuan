# Agent A — Backend Architect Roadmap

> Prioritized development plan for the HuiYuYuan backend.

---

## Completed ?

### A1: Backend Modularization ?
- [x] Extract `config.py` — Pydantic Settings from environment
- [x] Create `database.py` — SQLAlchemy engine + session + Redis
- [x] Create `security.py` — JWT + bcrypt + require_user
- [x] Create `store.py` — In-memory storage + init_store()
- [x] Extract 13 routers (auth, products, orders, cart, users, admin, favorites, reviews, shops, notifications, upload, ai, ws)
- [x] Create 8 Pydantic schema modules
- [x] Create 2 service modules (SMS, AI)
- [x] Seed data module (23 products)
- [x] Thin `main.py` entry point (107 lines, down from 2,246)
- [x] Verify all 55 routes registered

### A3: Security Hardening ?
- [x] JWT token authentication (create + verify + refresh)
- [x] Bcrypt password hashing (optional, graceful fallback)
- [x] CORS policy (environment-based allowed origins)
- [x] `require_user()` dependency for all protected endpoints
- [x] Token management (JWT primary + UUID fallback)

### A4: WebSocket Notifications ?
- [x] ConnectionManager with per-user connection tracking
- [x] WS endpoint with token authentication
- [x] Order lifecycle push notifications (created, paid, shipped, cancelled, refund)

### A2: PostgreSQL Data Persistence ?
- [x] Update `init_db.sql` with v4.0 schema migrations (7 ALTER TABLE + favorites table)
- [x] products.py — Full CRUD with parameterized queries, ILIKE search, sort, pagination
- [x] cart.py — UPSERT via ON CONFLICT, JOIN for reads
- [x] users.py — Profile + address CRUD with is_default cascade
- [x] orders.py — Multi-table transactions (orders + order_items + stock + cart cleanup)
- [x] admin.py — Aggregate dashboard + activities + ship order
- [x] favorites.py — Junction table with ON CONFLICT DO NOTHING
- [x] reviews.py — JOIN with users, AVG rating computation
- [x] All 8 data routers verified DB-aware

### A2+: Extended DB Persistence ?
- [x] Auth router DB enhancement — admin/operator/customer login now queries DB first
- [x] `_db_find_user()` generic helper for flexible user lookup
- [x] Customer SMS login creates user in DB on first visit
- [x] Shops table created (`shops` with 17 columns, 3 indexes)
- [x] shops.py rewritten with DB-first reads, filter + pagination
- [x] Devices table created (`devices` with UNIQUE device_token, JSONB settings)
- [x] Notifications table created (`notifications` with user_id FK, read tracking)
- [x] notifications.py rewritten with device registration upsert, paginated reads, mark-read
- [x] WebSocket push now persists every notification to DB via `persist_notification()`
- [x] Total: 10/13 routers DB-aware, 57 routes, 13 DB tables

---

## P0 — Next Up (Estimated: 1-2 days)

### ? Backend Test Coverage
- **Status**: 6 test files (~801 lines), basic coverage
- **Gap**: Tests run against memory mode only; no DB-path tests
- **Tasks**:
  - [ ] Add pytest fixtures for PostgreSQL test database (or SQLite in-memory)
  - [ ] Test DB code paths (products CRUD, orders lifecycle, cart upsert)
  - [ ] Test DB fallback behavior (mock `get_db` returning None)
  - [ ] Test new auth DB login paths (admin, operator, customer SMS)
  - [ ] Test notifications endpoints (register, list, mark-read)
  - [ ] Test shops DB endpoints (list with filters, detail)
  - [ ] Target: ≥80% line coverage for all routers

---

## P1 — Important (Estimated: 3-5 days)

### ? SQLAlchemy ORM Models
- **Current**: Raw SQL via `text()` with manual column mapping
- **Target**: SQLAlchemy declarative models for type safety and migration support
- **Files**: New `backend/models/` directory (user.py, product.py, order.py, cart.py, review.py, favorite.py, shop.py)
- **Benefits**: Alembic migrations, relationship loading, type checking, less boilerplate
- **Risk**: Medium — requires careful migration from raw SQL; must maintain backward compatibility with existing `_row_to_model()` pattern during transition
- **Dependency**: Coordinate with Agent D for Alembic setup

### ? Alembic Database Migrations
- **Current**: `init_db.sql` with `IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS`
- **Target**: Alembic versioned migrations for schema evolution
- **Tasks**:
  - [ ] `alembic init` in backend/
  - [ ] Initial migration from current `init_db.sql`
  - [ ] Auto-generate migrations from ORM model changes
- **Dependency**: Requires ORM models (above)

### ? Payment System Enhancement
- **Current**: Simulated payment with auto-callback after 3 seconds
- **Target**: Pluggable payment interface (WeChat Pay / Alipay / manual confirmation)
- **Tasks**:
  - [ ] Abstract `PaymentService` interface
  - [ ] WeChat Pay integration (JSAPI for Web, APP for mobile)
  - [ ] Payment callback webhook endpoint
  - [ ] Refund API integration
- **Note**: True payment integration requires business license and merchant account

### ? Full-Text Search
- **Current**: `ILIKE '%keyword%'` search in products
- **Target**: PostgreSQL `pg_trgm` + GIN index full-text search
- **Status**: `init_db.sql` already creates `pg_trgm` extension and GIN index on products.name
- **Tasks**:
  - [ ] Use `similarity()` or `word_similarity()` for fuzzy search
  - [ ] Add `tsvector` column for Chinese full-text search (requires `zhparser` extension)
  - [ ] Search ranking and relevance scoring

---

## P2 — Improvements (Estimated: 1-2 weeks)

### ? Query Optimization
- Products listing: Add composite index on `(category, is_active, created_at)`
- Orders listing: Add index on `(user_id, status, created_at)`
- Admin dashboard: Consider materialized views for aggregate stats (if query time exceeds 100ms)
- Connection pooling: Tune `pool_size` and `max_overflow` in `database.py`

### ? Advanced Security
- [ ] API rate limiting per user (Redis-backed token bucket)
- [ ] Request signing for mobile clients
- [ ] IP allowlist for admin endpoints
- [ ] Audit log table (who did what, when)
- [ ] SQL injection hardening review (all queries use parameterized `text()`, but review edge cases)

### ? API Analytics & Monitoring
- [ ] Request/response logging middleware (structured JSON)
- [ ] Endpoint performance metrics (P50/P95/P99 response times)
- [ ] Error rate tracking and alerting
- [ ] Health endpoint with DB/Redis connectivity status (already exists at `/api/health`)

### ? Cache Layer
- **Current**: Memory-only cache (PRODUCTS_DB, etc.)
- **Target**: Redis cache with TTL for frequently accessed data
- **Strategy**: Cache products listing (60s TTL), cache user profiles (300s TTL), invalidate on write
- **Dependency**: Redis must be available (currently optional)

### ? API Documentation
- [ ] OpenAPI schema descriptions for all endpoints
- [ ] Example request/response bodies in schemas
- [ ] Error code documentation
- [ ] API versioning strategy (currently no version prefix beyond /api/)

---

## P3 — Long-term Vision

### ? Async Migration
- Migrate from sync SQLAlchemy to async (`asyncpg` + `sqlalchemy.ext.asyncio`)
- Benefits: Better concurrency for I/O-bound operations
- Risk: Significant refactor; requires async-compatible dependencies
- Trigger: When concurrent user count exceeds ~100 and sync performance becomes bottleneck

### ?? Microservice Preparation
- Current monolith is well-modularized (13 routers = 13 potential services)
- Extract communication-heavy modules first (AI, SMS, Notification)
- Event-driven architecture with message queue (Redis Streams or RabbitMQ)
- Trigger: When single server cannot handle load

### ? Multi-tenancy
- Support multiple stores/brands on same backend
- Tenant isolation at DB level (schema-per-tenant or row-level security)
- API key per tenant for B2B scenarios

---

## Architecture Evolution Map

```
v3.x (Before)                    v4.0 (Current)                  v4.x (Next)
─────────────                    ──────────────                  ───────────
main.py (2246 lines)     →       13 routers + 8 schemas    →     ORM models + Alembic
Memory-only storage      →       DB-first (10/13 routers)  →     DB-only + Redis cache
Hardcoded credentials    →       JWT + bcrypt + DB auth    →     OAuth2 + refresh tokens
No WebSocket             →       WS + notification persist →     Full real-time (chat, live)
No tests                 →       6 test files              →     ≥80% coverage + E2E
Manual deploy            →       deploy.ps1 + CI/CD        →     Blue-green deployment
```
