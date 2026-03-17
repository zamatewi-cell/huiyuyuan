#!/bin/bash
# ============================================================
# 汇玉源 — PostgreSQL 自动备份脚本
# Crontab: 0 3 * * * /opt/huiyuanyuan/backup.sh >> /var/log/huiyuanyuan/backup.log 2>&1
# 功能: 全库备份 + 压缩 + 过期清理 + 可选远程同步
# ============================================================

set -euo pipefail

# ── 配置 ──
DB_NAME="${DB_NAME:-huiyuanyuan}"
DB_USER="${DB_USER:-huyy_user}"
BACKUP_DIR="${BACKUP_DIR:-/opt/huiyuanyuan/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
LOG_PREFIX="[BACKUP $(date '+%Y-%m-%d %H:%M:%S')]"

# 可选: 远程备份 (rsync 到另一台服务器)
REMOTE_BACKUP_HOST="${REMOTE_BACKUP_HOST:-}"
REMOTE_BACKUP_PATH="${REMOTE_BACKUP_PATH:-/opt/backups/huiyuanyuan}"

# ── 函数 ──
log_info()  { echo "${LOG_PREFIX} [INFO]  $1"; }
log_error() { echo "${LOG_PREFIX} [ERROR] $1" >&2; }
log_warn()  { echo "${LOG_PREFIX} [WARN]  $1"; }

send_alert() {
    local message="$1"
    # 钉钉告警
    if [ -n "${DINGTALK_WEBHOOK:-}" ]; then
        curl -s -X POST "${DINGTALK_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[汇玉源备份] ${message}\"}}" \
            > /dev/null 2>&1 || true
    fi
    # 企业微信告警
    if [ -n "${WECHAT_WEBHOOK:-}" ]; then
        curl -s -X POST "${WECHAT_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[汇玉源备份] ${message}\"}}" \
            > /dev/null 2>&1 || true
    fi
}

# ── 加载 .env ──
if [ -f /srv/huiyuanyuan/.env ]; then
    set -a
    source /srv/huiyuanyuan/.env
    set +a
fi

# ── 创建备份目录 ──
mkdir -p "${BACKUP_DIR}"

# ── 执行备份 ──
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
BACKUP_SCHEMA="${BACKUP_DIR}/schema_${TIMESTAMP}.sql.gz"

log_info "开始备份数据库 ${DB_NAME}..."

# 1. 全量备份 (数据+结构)
if sudo -u postgres pg_dump "${DB_NAME}" --format=custom --compress=9 > "${BACKUP_DIR}/db_${TIMESTAMP}.dump" 2>/dev/null; then
    DUMP_SIZE=$(du -h "${BACKUP_DIR}/db_${TIMESTAMP}.dump" | cut -f1)
    log_info "全量备份完成: db_${TIMESTAMP}.dump (${DUMP_SIZE})"
else
    # 降级为纯文本备份
    log_warn "custom格式失败，降级为SQL文本备份"
    sudo -u postgres pg_dump "${DB_NAME}" | gzip > "${BACKUP_FILE}" 2>/dev/null
    DUMP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log_info "SQL备份完成: db_${TIMESTAMP}.sql.gz (${DUMP_SIZE})"
fi

# 2. 仅结构备份 (用于快速对比变更)
sudo -u postgres pg_dump "${DB_NAME}" --schema-only | gzip > "${BACKUP_SCHEMA}" 2>/dev/null
log_info "结构备份完成: schema_${TIMESTAMP}.sql.gz"

# ── 清理过期备份 ──
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "*.dump" -o -name "*.sql.gz" | xargs -I{} find {} -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)
find "${BACKUP_DIR}" \( -name "*.dump" -o -name "*.sql.gz" \) -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true

if [ "${DELETED_COUNT}" -gt 0 ]; then
    log_info "已清理 ${DELETED_COUNT} 个过期备份 (>${RETENTION_DAYS}天)"
fi

# ── 备份统计 ──
TOTAL_BACKUPS=$(find "${BACKUP_DIR}" \( -name "*.dump" -o -name "*.sql.gz" \) | wc -l)
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1)
log_info "备份目录统计: ${TOTAL_BACKUPS} 个文件, 总大小 ${TOTAL_SIZE}"

# ── 远程同步 (可选) ──
if [ -n "${REMOTE_BACKUP_HOST}" ]; then
    log_info "同步到远程服务器 ${REMOTE_BACKUP_HOST}..."
    rsync -az --timeout=60 "${BACKUP_DIR}/" "${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}/" 2>/dev/null && \
        log_info "远程同步完成" || \
        log_warn "远程同步失败 (非致命)"
fi

# ── 验证最新备份 ──
LATEST_DUMP=$(ls -t "${BACKUP_DIR}"/db_*.dump 2>/dev/null | head -1)
if [ -n "${LATEST_DUMP}" ] && [ -s "${LATEST_DUMP}" ]; then
    log_info "备份验证: ${LATEST_DUMP} 完整 ?"
else
    LATEST_SQL=$(ls -t "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null | head -1)
    if [ -n "${LATEST_SQL}" ] && [ -s "${LATEST_SQL}" ]; then
        log_info "备份验证: ${LATEST_SQL} 完整 ?"
    else
        log_error "备份验证失败！无有效备份文件"
        send_alert "数据库备份失败！请立即检查"
        exit 1
    fi
fi

log_info "备份任务完成"
