# Agent D - DevOps Change Log

> Reverse-chronological record of all DevOps infrastructure changes.
> Last updated: 2026-03-25

---

## [2026-02-27] Session 5 - Alembic Migration + Nginx Cache + Deploy Chain

### Added
- **Alembic migration framework**
  - backend/alembic.ini, migrations/env.py, script.py.mako
  - Baseline migration: 20260227_0001_baseline_from_init_db_sql_v4_1.py
  - Usage: existing DB -> `alembic stamp 0001`; new -> `alembic revision -m "desc"`; apply -> `alembic upgrade head`
- **backend/deploy.sh**: Added step 2.5 - alembic upgrade head (skip if DB unavailable)
- **scripts/deploy.ps1**: BACKEND_SYNC_ITEMS += alembic.ini, migrations
- **.github/workflows/ci.yml**: deploy-backend SCP source += alembic.ini, migrations/
- **nginx_production.conf**: Added /assets/ and /canvaskit/ locations (365d cache, access_log off)

### Verified
- `alembic history` -> finds `<base> -> 0001 (head)`
- `alembic upgrade head --sql` -> offline mode generates correct SQL
- Backend 78/78 passed, Flutter 25/25 screens passed

---

## [2026-02-27] Session 4 - Backend Test Coverage + Security Hardening

### New Tests (+21 tests, total 78/78 passed)
- test_shops.py (5): list/detail/filter/404
- test_notifications.py (6): device register/fetch/mark-read/mark-all-read/401
- test_admin.py (6): ship/not-found/wrong-status/permission/activity/401
- test_upload.py (4): jpg/png/illegal format rejected/OSS STS 501

### New Scripts
- **backend/scripts/security_harden.sh**: fail2ban, unattended-upgrades, SSH hardening, sysctl network, --check-only audit mode

### Fixed
- **backend/security.py**: datetime.utcnow() (Python 3.12 DeprecationWarning) -> datetime.now(timezone.utc)
  - Affects: create_jwt_token() + create_refresh_token() (4 occurrences)
  - Result: 78 passed, 0 warnings (previously 224 warnings)

---

## [2025-07-15] Session 3 - Structured Logging + Cron Installer + Test Fixes

### Added
- **backend/logging_config.py**: Dual-mode logging (production JSON / dev colored text)
  - JSONFormatter: ts/level/logger/msg + request_id, user_id, method, path, status_code, duration_ms, client_ip
  - DevFormatter: colored HH:MM:SS [LEVEL] logger: msg
  - RequestLoggingMiddleware: skips /api/health, /favicon.ico, /robots.txt
  - setup_logging(): auto-selects JSON or text based on APP_ENV
- **backend/scripts/install_cron.sh**: health monitor (every 5min) + DB backup (daily 02:30), 14-day logrotate, idempotent

### Modified
- backend/main.py: logging.basicConfig() -> setup_logging() + RequestLoggingMiddleware
- scripts/deploy.ps1: BACKEND_SYNC_ITEMS += logging_config.py
- .github/workflows/ci.yml: deploy-backend SCP += logging_config.py

### Test Fixes (assisting Agent B/C)
- checkout_screen.dart: Row overflow -> Flexible wrap + button padding 40->32
- order_list_screen.dart: AppBar height 100->112 + Future.delayed -> Timer + dispose
- admin_dashboard.dart: _getMockActivities() -> _buildActivityData()
- All 25 screens passing

---

## [2025-07-14] Session 2 - Deploy Sync Fix + Documentation

### Fixed
- deploy.sh snapshot: added schemas/, security.py, store.py, data/
- deploy.ps1: added pyproject.toml, tests/; removed non-existent middleware/
- ci.yml snapshot: added config.py, database.py, security.py, store.py, data
- ci.yml SCP source: added pyproject.toml, tests/; removed middleware/

### Added
- docs/agent_d_docs/: identity.md, change_log.md, roadmap.md

---

## [2025-07-13] Session 1 - Full DevOps Infrastructure Build

### New Files (11)
| File | Description |
|---|---|
| backend/server_setup.sh | Server init: PostgreSQL 15, Redis, Python venv, systemd, UFW, logrotate |
| backend/nginx_production.conf | Production Nginx: security headers, WebSocket, rate limiting, SSL-ready |
| backend/nginx_proxy_params.conf | Nginx proxy params snippet |
| backend/scripts/db_backup.sh | Auto backup: pg_dump + gzip + expiry + rsync + webhook alert |
| backend/scripts/db_restore.sh | Safe restore: auto-snapshot + verify |
| backend/scripts/health_monitor.sh | Cron: API/PG/Redis/Nginx/disk/memory checks + auto-restart |
| backend/scripts/ssl_setup.sh | Let's Encrypt one-click install + auto-renew |
| backend/scripts/server_diagnose.sh | One-click server diagnosis |
| docs/agent_d_docs/identity.md | Agent D identity |
| docs/agent_d_docs/change_log.md | This file |
| docs/agent_d_docs/roadmap.md | DevOps roadmap |

### Major Modifications (5)
| File | Change |
|---|---|
| backend/.env.example | Added Redis pwd, AI Key, backup config, monitor webhook; production CORS no wildcard |
| backend/deploy.sh | v4 rewrite: snapshot -> deps -> Nginx sync -> restart -> health check -> auto-rollback |
| scripts/deploy.ps1 | v4 rewrite: -Target all/web/backend/nginx/db-init, -Rollback, full-dir rsync, auto snapshot/rollback |
| .github/workflows/ci.yml | Added backend-test job (pytest + PG/Redis containers) + security-scan job |
| .vscode/tasks.json | Added 4 tasks: Nginx update, DB init, full diagnosis, manual backup |

### Architecture Decisions
| Decision | Rationale |
|---|---|
| Sync SQLAlchemy (not asyncpg) | Already using create_engine + Session; migration cost high; current traffic needs no async |
| CORS production whitelist | Disallow *; only https://xn--lsws2cdzg.top |
| Keep 3 snapshots | Balance disk vs rollback needs |
| Nginx config in code sync | Version-consistent reverse proxy config |
