#!/usr/bin/env bash
# ============================================================
# Backward-compatible entrypoint for the current ECS backend deploy.
# Usage: bash /srv/huiyuanyuan/deploy.sh
# ============================================================

set -euo pipefail

CURRENT_DEPLOY_SCRIPT="/srv/huiyuanyuan/backend/deploy_current_server.sh"

if [[ ! -f "${CURRENT_DEPLOY_SCRIPT}" ]]; then
    echo "[ERROR] Missing deploy script: ${CURRENT_DEPLOY_SCRIPT}" >&2
    exit 1
fi

exec bash "${CURRENT_DEPLOY_SCRIPT}" "$@"
