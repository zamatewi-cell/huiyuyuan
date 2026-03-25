# Agent E - Roadmap

## Current Priorities

- [x] Sweep `docs/guides/` and `docs/agent_d_docs/` for stale production layout references and align them to the live domain, server, backend path, env path, Nginx conf, and service name.
- [x] Align CI/CD deployment with the live server layout:
  - backend path: `/srv/huiyuanyuan/backend`
  - service: `huiyuanyuan-backend`
  - Nginx conf: `/etc/nginx/conf.d/huiyuanyuan.conf`
- [x] Keep release verification scripts aligned with HTTPS domain access.
- [x] Audit remaining production docs for old IP-only deployment assumptions.
- [x] Resolve legacy encoding debt in `huiyuanyuan_app/backend/scripts/ssl_setup.sh`.
- [x] Record every release-related change in `change_log.md`.
- [x] Normalize `.github/workflows/ci.yml` and finalize the backend deploy block.

## Working Notes

- The live production domain is `xn--lsws2cdzg.top`.
- Manual deploy flow is currently authoritative.
- CI workflow backend deploy now mirrors the manual release flow.
- `scripts/migrate_server.ps1` now writes punycode-only `ALLOWED_ORIGINS` to avoid remote shell encoding issues.
- `huiyuanyuan_app/backend/scripts/ssl_setup.sh` encoding cleanup is being handled by an external collaborating agent.
