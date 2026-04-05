#!/bin/bash
# ============================================================
# HuiYuYuan - Crontab Installer
# Installs (or updates) scheduled tasks for:
#   1. Health monitoring  (every 5 min)
#   2. PostgreSQL backup  (daily 02:30)
#   3. Log rotation hint  (logrotate config)
#
# Usage:
#   sudo bash /opt/huiyuyuan/scripts/install_cron.sh [--remove]
# ============================================================

set -euo pipefail

# ���� Config ����
APP_DIR="/opt/huiyuyuan"
SCRIPTS_DIR="${APP_DIR}/scripts"
LOG_DIR="/var/log/huiyuyuan"
CRON_TAG="# huiyuyuan-managed"

# Color helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

# ���� Pre-checks ����
[[ $EUID -eq 0 ]] || fail "This script must be run as root (sudo)"

echo "=== HuiYuYuan Crontab Installer ==="
echo "Scripts dir : ${SCRIPTS_DIR}"
echo "Log dir     : ${LOG_DIR}"
echo ""

# ���� Ensure dirs & permissions ����
mkdir -p "${LOG_DIR}"
chmod 750 "${LOG_DIR}"

for script in health_monitor.sh db_backup.sh; do
    if [[ ! -f "${SCRIPTS_DIR}/${script}" ]]; then
        fail "Required script not found: ${SCRIPTS_DIR}/${script}"
    fi
    chmod +x "${SCRIPTS_DIR}/${script}"
done
info "Scripts are executable"

# ���� Remove mode ����
if [[ "${1:-}" == "--remove" ]]; then
    echo "Removing HuiYuYuan cron entries..."
    crontab -l 2>/dev/null | grep -v "${CRON_TAG}" | crontab - || true
    info "All huiyuyuan-managed cron entries removed"
    exit 0
fi

# ���� Define cron entries ����
CRON_ENTRIES=(
    "*/5 * * * * ${SCRIPTS_DIR}/health_monitor.sh >> ${LOG_DIR}/monitor.log 2>&1 ${CRON_TAG}"
    "30 2 * * * ${SCRIPTS_DIR}/db_backup.sh >> ${LOG_DIR}/backup.log 2>&1 ${CRON_TAG}"
)

# ���� Install: remove old managed entries, then append new ones ����
EXISTING_CRON=$(crontab -l 2>/dev/null || echo "")

# Strip old managed lines
CLEAN_CRON=$(echo "${EXISTING_CRON}" | grep -v "${CRON_TAG}" || true)

# Build new crontab
{
    echo "${CLEAN_CRON}"
    echo ""
    echo "# ---- HuiYuYuan Scheduled Tasks ----"
    for entry in "${CRON_ENTRIES[@]}"; do
        echo "${entry}"
    done
} | crontab -

info "Cron entries installed ($(echo "${CRON_ENTRIES[@]}" | wc -w) jobs)"

# Verify
echo ""
echo "Current crontab:"
crontab -l | grep "${CRON_TAG}" | while read -r line; do
    echo "  ${line}"
done

# ���� Logrotate config ����
LOGROTATE_CONF="/etc/logrotate.d/huiyuyuan"
if [[ ! -f "${LOGROTATE_CONF}" ]]; then
    cat > "${LOGROTATE_CONF}" << 'EOF'
/var/log/huiyuyuan/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 root root
    sharedscripts
    postrotate
        # Signal gunicorn to reopen log files if needed
        systemctl reload huiyuyuan 2>/dev/null || true
    endscript
}
EOF
    info "Logrotate config created: ${LOGROTATE_CONF}"
else
    warn "Logrotate config already exists: ${LOGROTATE_CONF} (skipped)"
fi

echo ""
echo "=== Installation Complete ==="
echo "  Health check : every 5 minutes"
echo "  DB backup    : daily at 02:30"
echo "  Log rotation : daily, 14 days retention"
echo ""
echo "Useful commands:"
echo "  crontab -l                              # list cron jobs"
echo "  tail -f ${LOG_DIR}/monitor.log          # monitor logs"
echo "  tail -f ${LOG_DIR}/backup.log           # backup logs"
echo "  sudo bash $0 --remove                   # uninstall cron"
