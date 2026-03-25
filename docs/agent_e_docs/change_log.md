# Agent E - Change Log

## 2026-03-25

### Session Start

- Created Agent E workspace under `docs/agent_e_docs/`.
- Assigned role: Production Release Engineer.
- Initial focus: CI/CD cleanup, deployment consistency, and release verification.

### CI Review

- Inspected `.github/workflows/ci.yml` for production deployment assumptions.
- Normalized the workflow file to UTF-8 so it could be edited safely.
- First-pass CI cleanup exposed that the workflow still retained old `/srv/huiyuanyuan`, `sites-available`, and `huiyuanyuan` service assumptions.
- Finalized the backend deploy job so it uploads into `/srv/huiyuanyuan/backend`, installs `huiyuanyuan-backend.service`, applies `alembic upgrade head`, reloads `/etc/nginx/conf.d/huiyuanyuan.conf`, and restarts `huiyuanyuan-backend`.
- Added backend snapshot rollback logic that restores the backend directory and re-applies service and Nginx files if health checks fail.
- Kept the manual deploy flow authoritative for server release verification.

### Migration Script Follow-up

- Rewrote `scripts/migrate_server.ps1` to keep the remote `ALLOWED_ORIGINS` update ASCII-safe.
- Verified the migration script with a PowerShell parse check and a full `-DryRun`.

### Production Docs Update

- Audited `docs/README.md` and `docs/guides/deployment_guide.md` to replace old IP `47.98.188.141` references with `xn--lsws2cdzg.top`.
- Updated `SERVER_HOST` documentation and dates to reflect the new production state.

### Production Layout Sweep & Encoding Normalization

- Swept across `docs/guides/` and `docs/agent_d_docs/` to align all legacy references to the new paths (`/srv/huiyuanyuan/backend`, `huiyuanyuan-backend.service`, `/etc/nginx/conf.d/huiyuanyuan.conf`, etc.).
- Normalized line endings (CRLF -> LF) and stripped any potential UTF-8 BOM from `huiyuanyuan_app/backend/scripts/ssl_setup.sh`, `.github/workflows/ci.yml`, and corrupted markdown docs.
- Reviewed `.github/workflows/ci.yml` syntax manually: It is currently a valid YAML file, completely converted to English labels and metadata, without any mojibake remaining, and properly configured for the `/srv/huiyuanyuan/backend` layout.

### Planning & Reference Sweep

- Swept `docs/planning/` (4 files) to replace stale `47.98.188.141` IP references with `xn--lsws2cdzg.top`.
  - `task.md`: Historical logs annotated with `（原 47.98.188.141）`; L177 task flipped from `[ ]` to `[x]` to reflect domain is live.
  - `server_migration_plan.md`: Document header, info table, service name (`huiyuanyuan.service` → `huiyuanyuan-backend.service`), Nginx paths (`sites-available` → `conf.d/huiyuanyuan.conf`) updated.
  - `technical_debt_fix_plan.md`: CORS and `apiBaseUrl` code examples updated to `https://xn--lsws2cdzg.top`.
  - `v4_master_plan.md`: All bare IP occurrences replaced (file contained mojibake but ASCII IP was safely substituted).
- `docs/reference/archive/` intentionally left unchanged — those are historical snapshots that must not be rewritten.

### Production Docs Sweep Follow-up

- Rebuilt `docs/agent_d_docs/identity.md` and `docs/agent_d_docs/roadmap.md` as UTF-8 docs because the legacy files were not valid UTF-8 and could not be patched safely.
- Aligned Agent D's production facts with the live server `47.112.98.191`, backend path `/srv/huiyuanyuan/backend`, env path `/srv/huiyuanyuan/.env`, Nginx conf `/etc/nginx/conf.d/huiyuanyuan.conf`, and service `huiyuanyuan-backend`.
- Rewrote `docs/guides/deployment_guide.md` to remove the remaining root-level backend, `sites-enabled`, and legacy `huiyuanyuan` service assumptions while preserving the current domain-based release flow.
- Left `huiyuanyuan_app/backend/scripts/ssl_setup.sh` untouched because that encoding task is now owned by an external collaborating agent.
