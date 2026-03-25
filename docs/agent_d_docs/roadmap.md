# Agent D - DevOps Roadmap

> This roadmap tracks the remaining high-priority operational work against the current production layout.

## P0

### SSL setup script validation
- Status: in progress by an external collaborating agent.
- Target server: `47.112.98.191`
- Target domain: `xn--lsws2cdzg.top` / `汇玉源.top`
- Expected script location: `/srv/huiyuanyuan/backend/scripts/ssl_setup.sh`
- Expected Nginx target: `/etc/nginx/conf.d/huiyuanyuan.conf`
- Expected service: `huiyuanyuan-backend`

### Production layout consistency
- Confirm all deployment docs, scripts, and service references point to `/srv/huiyuanyuan/backend`.
- Keep the authoritative env path at `/srv/huiyuanyuan/.env`.
- Remove any remaining references to the legacy service name `huiyuanyuan` for production operations.

## P1

### Verification and maintenance
- Re-verify HTTPS ingress for `https://xn--lsws2cdzg.top` after each Nginx or certificate change.
- Keep backup, monitoring, and rollout docs aligned with the live server layout.
- Record operational changes in the corresponding agent docs and release guides.
