# Agent A ¡ª Backend Architect Change Log

> Chronological record of all backend modifications, newest first.

---

## [2026-02-27] Session 3 ¡ª Auth Enhancement + Shops & Notifications DB Migration

### Overview
Extended DB persistence to the remaining 2 data routers (shops, notifications) and enhanced auth login to query the database. Also added notification persistence for the WebSocket push system. DB-aware routers now at **10/13** (3 stateless by design).

### Schema Updates

#### `init_db.sql` ¡ª v4.1 Tables Added
- **CREATE TABLE shops** (17 columns): Full shop data with `platform`, `category`, `contact_status` CHECK constraint, `conversion_rate`, `followers`, `monthly_sales`, `negative_rate`, `is_influencer`, `operator_id` FK, `ai_priority`, `is_active`. Indexes on `platform`, `category`, `operator_id`.
- **CREATE TABLE devices** (8 columns): Push notification device registration. `device_token` UNIQUE, `user_id` FK, `platform`, `settings` JSONB, `is_active`. Indexes on `user_id`, `device_token`.
- **CREATE TABLE notifications** (8 columns): Notification history. Auto-ID via UUID, `user_id` FK, `title`, `body`, `type`, `ref_id`, `is_read`, `created_at`. Indexes on `user_id`, `created_at DESC`.

### Router Changes

#### `routers/auth.py` (399 lines, enhanced)
- **NEW**: `_db_find_user(db, phone, username, operator_num, user_type)` ¡ª Generic DB user lookup helper with flexible filter params
- **NEW**: `_login_success(user_id, user_data)` ¡ª DRY helper for token generation + response assembly
- **CHANGED**: Admin login now attempts DB lookup first (`SELECT FROM users WHERE phone = :phone AND user_type = 'admin'`), falls back to memory `USERS_DB`
- **CHANGED**: Operator login now tries DB by `operator_num` or `username` first, falls back to memory
- **CHANGED**: Customer SMS login now creates new users in DB via `INSERT INTO users`, falls back to memory
- **CHANGED**: All login paths now share `_login_success()` for consistent response format

#### `routers/shops.py` (127 lines, rewritten)
- **NEW**: `_row_to_shop(m)` helper for DB row ¡ú Shop schema
- **GET /**: Dynamic WHERE clause with filters (platform, category, contact_status, is_influencer, operator_id), `ORDER BY ai_priority DESC`, pagination
- **GET /{id}**: DB lookup with `is_active = true` filter
- Both endpoints fall back to in-memory `SHOPS_DB` if DB unavailable

#### `routers/notifications.py` (176 lines, rewritten)
- **POST /register**: `INSERT INTO devices ... ON CONFLICT (device_token) DO UPDATE` (upsert) + memory write-through
- **GET /**: DB query with pagination, `ORDER BY created_at DESC`, aggregate count for total/unread stats; demo data fallback when DB unavailable
- **NEW**: `POST /{id}/read` ¡ª Mark single notification as read
- **NEW**: `POST /read-all` ¡ª Mark all notifications as read for a user

#### `routers/ws.py` (139 lines, enhanced)
- **NEW**: `persist_notification(user_id, title, body, ntype, ref_id)` ¡ª Best-effort DB persistence for every WS push notification, uses own Session (non-blocking)

#### `routers/orders.py` (710 lines, enhanced)
- **CHANGED**: `_ws_notify()` now calls `persist_notification()` to store every order event push as a notification record in DB

### Verification Results
- ? 57 total routes (55 HTTP + 1 WS + docs), up from 55
- ? 10/13 routers DB-aware (+2: shops, notifications)
- ? 3 stateless routers by design: upload, ai, ws
- ? All files valid UTF-8

---

## [2026-02-27] Session 2 ¡ª PostgreSQL Data Persistence (A2)

### Overview
Completed the DB persistence layer for all 8 data routers. Every data-access endpoint now follows the **DB-first with in-memory fallback** pattern.

### Schema Updates

#### `init_db.sql` ¡ª v4.0 Migrations Added
- **ALTER TABLE orders**: Added 7 columns required by the Order Pydantic model:
  - `cancel_reason TEXT`
  - `logistics_company VARCHAR(64)`
  - `logistics_entries JSONB DEFAULT '[]'`
  - `refund_reason TEXT`
  - `refund_amount NUMERIC(12,2)`
  - `payment_id VARCHAR(64)`
  - `delivered_at TIMESTAMPTZ`
- **CREATE TABLE favorites**: New junction table (`user_id`, `product_id` composite PK with FK references, `created_at`)
- **Index**: `idx_favorites_user_id` on `favorites(user_id)`

### Router Rewrites (7 files, ~2,100 lines)

All rewrites follow the same architecture: `Depends(get_db)` ¡ú SQL via `text()` ¡ú `_row_to_model()` helper ¡ú memory fallback.

#### `routers/products.py` (298 lines)
- **GET /**: Dynamic WHERE clause, parameterized ILIKE search, configurable sort, LIMIT/OFFSET pagination from DB
- **GET /{id}**: DB lookup with `is_active = true` filter
- **POST /**: DB `INSERT` with `::jsonb` cast for images array + memory write-through
- **PUT /{id}**: DB `UPDATE` with dynamic SET clause + memory update
- **DELETE /{id}**: Soft delete via `UPDATE SET is_active = false` + memory removal
- **Helper**: `_row_to_product(m)` ¡ª handles JSONB images parsing, all column-to-field mapping

#### `routers/cart.py` (218 lines)
- **GET /**: `JOIN products` for full product data in cart response
- **POST /**: `INSERT ... ON CONFLICT (user_id, product_id) DO UPDATE SET quantity = cart_items.quantity + :qty` (upsert)
- **PUT /{pid}**: DB `UPDATE` or `DELETE` based on quantity <= 0
- **DELETE /{pid}**: DB `DELETE` by user_id + product_id
- **DELETE /**: DB `DELETE` all cart items for user

#### `routers/users.py` (277 lines)
- **GET /profile**: DB `SELECT` from users, maps `avatar_url` ¡ú `avatar`, `operator_num` ¡ú `operator_number`
- **PUT /profile**: Dynamic SET clause for allowed fields (username, avatar)
- **Address CRUD**: Full DB persistence with `is_default` cascade (UPDATE all to false before setting new default)
- **Helper**: `_row_to_address(m)` for DB row ¡ú Address schema conversion

#### `routers/orders.py` (701 lines) ¡ª Most Complex
- **Helpers**: `_row_to_order(m, items)`, `_ts(val)`, `_fetch_order_items(db, oid)`, `_fetch_order_with_items(db, oid)`, `_ws_notify(uid, payload)`
- **Column mapping**: DB `tracking_no` ¡ú Pydantic `tracking_number`, DB `address_snap` ¡ú Pydantic `address`
- **GET /**: Fetches orders + batch-fetches order_items per order
- **GET /stats**: Single aggregate query with `FILTER (WHERE status = ...)` for all status counts
- **POST /** (create order): Multi-table transaction:
  - `INSERT INTO orders` (with address_snap JSONB)
  - `INSERT INTO order_items` (per item, with product_snap JSONB)
  - `UPDATE products SET stock = stock - :qty` (stock deduction)
  - `DELETE FROM cart_items` (cleanup ordered items)
- **POST /{id}/pay**: `INSERT INTO payments` + `UPDATE orders.payment_id`
- **GET /{id}/pay-status**: Auto-callback after 3s with DB update for both orders and payments; stores logistics_entries as JSONB
- **POST /{id}/cancel**: Stock restoration via `UPDATE products SET stock = stock + :qty, sales_count = GREATEST(sales_count - :qty, 0)`
- **POST /{id}/confirm-receipt**: Update status to 'delivered' with logistics entry
- **POST /{id}/refund**: Update status to 'refunding' with reason + amount
- **GET /{id}/logistics**: Read logistics data from order record

#### `routers/admin.py` (257 lines)
- **GET /dashboard**: Single aggregate SQL with `FILTER` clauses for order stats, separate queries for products and operators
- **GET /activities**: Subquery for item names from order_items, low-stock product warnings
- **POST /orders/{id}/ship**: DB `UPDATE` with logistics_entries JSONB, WebSocket notification to buyer
- **Helpers**: `_add_activity(acts, m)` for DB rows, `_add_activity_mem(acts, o, name, qty)` for memory orders

#### `routers/favorites.py` (126 lines)
- **GET /**: `JOIN products` for full product data in response
- **POST /{pid}**: `INSERT INTO favorites ... ON CONFLICT DO NOTHING`
- **DELETE /{pid}**: DB `DELETE` from favorites table

#### `routers/reviews.py` (139 lines)
- **GET /products/{pid}/reviews**: `LEFT JOIN users` for reviewer name/avatar, CASE WHEN for anonymous
- **POST /reviews**: `INSERT` + compute `AVG(rating)` + `UPDATE products.rating`
- **Helper**: `_row_to_review(m)` with anonymous user handling

### Encoding Fix
- All 7 newly created router files required GBK ¡ú UTF-8 conversion due to Windows `create_file` encoding behavior
- Applied batch conversion script; verified all 14 router `.py` files as valid UTF-8

### Verification Results
- ? `from main import app` ¡ª 55 routes registered successfully
- ? All 8 data routers confirmed DB-aware (auth, products, cart, users, orders, admin, favorites, reviews)
- ? All 5 stateless routers confirmed memory-only by design (shops, notifications, upload, ai, ws)
- ? All 14 router files valid UTF-8 encoding

---

## [2026-02-27] Session 1 ¡ª Modularization + Security + WebSocket (A1, A3, A4)

### A1: Backend Modularization

**Before**: Single `main.py` at 2,246 lines containing all routes, models, storage, utilities.
**After**: Modular structure with 41 Python files totaling ~7,215 lines (including tests and backup).

#### New Files Created (30+)

| Category | Files Created |
|---|---|
| **Core** | `main.py` (107 lines), `config.py`, `database.py`, `security.py`, `store.py` |
| **Routers** | `auth.py`, `products.py`, `orders.py`, `cart.py`, `users.py`, `admin.py`, `favorites.py`, `reviews.py`, `shops.py`, `notifications.py`, `upload.py`, `ai.py`, `ws.py` |
| **Schemas** | `auth.py`, `product.py`, `order.py`, `cart.py`, `user.py`, `review.py`, `shop.py`, `common.py` |
| **Services** | `sms_service.py`, `ai_service.py` |
| **Data** | `seed_products.py` |
| **Tests** | `conftest.py`, `test_auth.py`, `test_products.py`, `test_orders.py`, `test_cart.py`, `test_health.py`, `test_misc.py` |

#### Architecture Decisions

| Decision | Rationale |
|---|---|
| Raw SQL via `text()` instead of ORM models | Explicit control, PostgreSQL-specific features (JSONB, FILTER, ILIKE), lower migration risk |
| Pydantic schemas separate from DB layer | Clean API contract, no coupling to database schema |
| `Depends(get_db)` yields `None` when DB unavailable | Enables graceful degradation to in-memory mode |
| Factory singleton pattern for services | Consistent with frontend service architecture |
| Write-through caching | DB writes always accompanied by memory store update |

### A3: Security Hardening

- **JWT Authentication**: `security.py` with `create_jwt_token()`, `verify_jwt_token()`, `require_user()`
- **Bcrypt passwords**: Optional `passlib[bcrypt]` support, falls back to plaintext comparison in dev
- **CORS policy**: Configured in `main.py` with environment-based allowed origins
- **Rate limiting**: Documented in init approach; SMS endpoint rate-limited via Nginx (5r/m upstream)
- **Token management**: JWT + fallback UUID tokens in `TOKENS_DB`

### A4: WebSocket Notifications

- **`routers/ws.py`** (113 lines): `ConnectionManager` class with per-user connection tracking
- **Endpoint**: `WS /ws/notifications` with authentication via `?token=` query parameter
- **Integration**: `_ws_notify()` helper in orders.py and admin.py for real-time push:
  - `order_created` ¡ª when buyer creates an order
  - `payment_success` ¡ª when payment confirmed
  - `order_shipped` ¡ª when admin ships an order
  - `order_cancelled` / `order_refund` ¡ª status change notifications

### Deployment Updates

- **`scripts/deploy.ps1`**: Updated to sync entire `backend/` directory structure (routers/, schemas/, services/, data/, tests/)
- **`.github/workflows/ci.yml`**: Updated SCP source list and snapshot paths for modular backend

### Backup

- **`main_v3_backup.py`**: Original 2,246-line monolith preserved as backup (2,245 lines)

---
