#!/usr/bin/env bash
# ============================================================
# Legacy setup entrypoint retained for backward compatibility.
# This script no longer performs bootstrap actions because the old
# /srv/huiyuyuan flat layout is not the live production layout.
# ============================================================

set -euo pipefail

echo "[ERROR] setup.sh is deprecated for the current production layout." >&2
echo "" >&2
echo "Use one of these instead:" >&2
echo "  1. Local release:   powershell -File scripts/deploy.ps1 -Target backend" >&2
echo "  2. Server deploy:   bash /srv/huiyuyuan/backend/deploy_current_server.sh" >&2
echo "  3. SSL bootstrap:   bash /srv/huiyuyuan/backend/scripts/ssl_setup.sh xn--lsws2cdzg.top" >&2
echo "" >&2
echo "Current live layout:" >&2
echo "  backend: /srv/huiyuyuan/backend" >&2
echo "  env:     /srv/huiyuyuan/.env" >&2
echo "  nginx:   /etc/nginx/conf.d/huiyuyuan.conf" >&2
echo "  service: huiyuyuan-backend" >&2
exit 1
