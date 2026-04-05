#!/usr/bin/env bash
# ============================================================
# Legacy server bootstrap entrypoint retained for backward compatibility.
# The historical bootstrap flow targeted an outdated flat deployment.
# ============================================================

set -euo pipefail

echo "[ERROR] server_setup.sh is deprecated for the current production layout." >&2
echo "" >&2
echo "Use the current release flow instead:" >&2
echo "  1. Deploy from workstation: powershell -File scripts/deploy.ps1 -Target backend" >&2
echo "  2. On-server backend deploy: bash /srv/huiyuyuan/backend/deploy_current_server.sh" >&2
echo "  3. On-server SSL setup:     bash /srv/huiyuyuan/backend/scripts/ssl_setup.sh xn--lsws2cdzg.top" >&2
echo "" >&2
echo "Current live layout:" >&2
echo "  backend: /srv/huiyuyuan/backend" >&2
echo "  env:     /srv/huiyuyuan/.env" >&2
echo "  nginx:   /etc/nginx/conf.d/huiyuyuan.conf" >&2
echo "  service: huiyuyuan-backend" >&2
exit 1
