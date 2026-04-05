# Agent D - DevOps Roadmap

> This roadmap tracks the remaining high-priority operational work against the current production layout.

## P0

### SSL setup script validation
- Status: in progress by an external collaborating agent.
- Target server: `47.112.98.191`
- Target domain: `xn--lsws2cdzg.top` / `汇玉源.top`
- Expected script location: `/srv/huiyuyuan/backend/scripts/ssl_setup.sh`
- Expected Nginx target: `/etc/nginx/conf.d/huiyuyuan.conf`
- Expected service: `huiyuyuan-backend`

### Production layout consistency
- Confirm all deployment docs, scripts, and service references point to `/srv/huiyuyuan/backend`.
- Keep the authoritative env path at `/srv/huiyuyuan/.env`.
- Remove any remaining references to the legacy service name `huiyuyuan` for production operations.

## P1

### Verification and maintenance
- Re-verify HTTPS ingress for `https://xn--lsws2cdzg.top` after each Nginx or certificate change.
- Keep backup, monitoring, and rollout docs aligned with the live server layout.
- Record operational changes in the corresponding agent docs and release guides.
