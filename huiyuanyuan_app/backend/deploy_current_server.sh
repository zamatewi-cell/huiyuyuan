#!/bin/bash
# ============================================================
# HuiYuYuan backend hot-deploy script for the current ECS layout
# Usage: bash /srv/huiyuanyuan/backend/deploy_current_server.sh
# ============================================================

set -euo pipefail

APP_DIR="/srv/huiyuanyuan/backend"
SNAP_DIR="/opt/huiyuanyuan/snapshots"
HEALTH_URL="http://127.0.0.1:8000/api/health"
MAX_SNAPS=3
SERVICE_NAME="huiyuanyuan-backend"
SYSTEMD_UNIT="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_CONF="/etc/nginx/conf.d/huiyuanyuan.conf"

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }
red() { printf '\033[0;31m%s\033[0m\n' "$1"; }

cd "${APP_DIR}"
source venv/bin/activate

SNAP_TS=$(date '+%Y%m%d_%H%M%S')
SNAP_PATH="${SNAP_DIR}/${SNAP_TS}"
mkdir -p "${SNAP_PATH}"
cp -a \
  alembic.ini \
  config.py database.py logging_config.py main.py requirements.txt security.py store.py \
  deploy_current_server.sh huiyuanyuan-backend.service nginx_current.conf nginx_proxy_params.conf \
  routers services schemas data migrations tests \
  "${SNAP_PATH}/" 2>/dev/null || true
green "snapshot created: ${SNAP_TS}"

cd "${SNAP_DIR}"
ls -dt */ 2>/dev/null | tail -n +$((MAX_SNAPS + 1)) | xargs -r rm -rf
cd "${APP_DIR}"

pip install -r requirements.txt -q
alembic upgrade head

if [ -f "${APP_DIR}/huiyuanyuan-backend.service" ]; then
  cp "${APP_DIR}/huiyuanyuan-backend.service" "${SYSTEMD_UNIT}"
  systemctl daemon-reload
fi

if [ -f "${APP_DIR}/nginx_current.conf" ]; then
  mkdir -p /etc/nginx/snippets
  cp "${APP_DIR}/nginx_current.conf" "${NGINX_CONF}"
  cp "${APP_DIR}/nginx_proxy_params.conf" /etc/nginx/snippets/proxy_params.conf
  nginx -t
  systemctl reload nginx
fi

systemctl restart "${SERVICE_NAME}"

healthy=false
for _ in $(seq 1 5); do
  status=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "${HEALTH_URL}" || echo "000")
  if [ "${status}" = "200" ]; then
    healthy=true
    break
  fi
  sleep 2
done

if [ "${healthy}" = true ]; then
  green "deploy succeeded"
  curl -s "${HEALTH_URL}"
  exit 0
fi

red "health check failed, rolling back ${SNAP_TS}"
cp -a "${SNAP_PATH}/"* "${APP_DIR}/" 2>/dev/null || true

if [ -f "${APP_DIR}/huiyuanyuan-backend.service" ]; then
  cp "${APP_DIR}/huiyuanyuan-backend.service" "${SYSTEMD_UNIT}"
  systemctl daemon-reload
fi

if [ -f "${APP_DIR}/nginx_current.conf" ]; then
  mkdir -p /etc/nginx/snippets
  cp "${APP_DIR}/nginx_current.conf" "${NGINX_CONF}"
  cp "${APP_DIR}/nginx_proxy_params.conf" /etc/nginx/snippets/proxy_params.conf 2>/dev/null || true
  nginx -t
  systemctl reload nginx
fi

systemctl restart "${SERVICE_NAME}"
exit 1
