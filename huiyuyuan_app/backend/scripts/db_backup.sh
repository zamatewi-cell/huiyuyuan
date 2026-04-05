#!/bin/bash
# ============================================================
# ����Դ �� PostgreSQL �Զ����ݽű�
# Crontab: 0 3 * * * /opt/huiyuyuan/backup.sh >> /var/log/huiyuyuan/backup.log 2>&1
# ����: ȫ�ⱸ�� + ѹ�� + �������� + ��ѡԶ��ͬ��
# ============================================================

set -euo pipefail

# ���� ���� ����
DB_NAME="${DB_NAME:-huiyuyuan}"
DB_USER="${DB_USER:-huyy_user}"
BACKUP_DIR="${BACKUP_DIR:-/opt/huiyuyuan/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
LOG_PREFIX="[BACKUP $(date '+%Y-%m-%d %H:%M:%S')]"

# ��ѡ: Զ�̱��� (rsync ����һ̨������)
REMOTE_BACKUP_HOST="${REMOTE_BACKUP_HOST:-}"
REMOTE_BACKUP_PATH="${REMOTE_BACKUP_PATH:-/opt/backups/huiyuyuan}"

# ���� ���� ����
log_info()  { echo "${LOG_PREFIX} [INFO]  $1"; }
log_error() { echo "${LOG_PREFIX} [ERROR] $1" >&2; }
log_warn()  { echo "${LOG_PREFIX} [WARN]  $1"; }

send_alert() {
    local message="$1"
    # �����澯
    if [ -n "${DINGTALK_WEBHOOK:-}" ]; then
        curl -s -X POST "${DINGTALK_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[����Դ����] ${message}\"}}" \
            > /dev/null 2>&1 || true
    fi
    # ��ҵ΢�Ÿ澯
    if [ -n "${WECHAT_WEBHOOK:-}" ]; then
        curl -s -X POST "${WECHAT_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[����Դ����] ${message}\"}}" \
            > /dev/null 2>&1 || true
    fi
}

# ���� ���� .env ����
if [ -f /srv/huiyuyuan/.env ]; then
    set -a
    source /srv/huiyuyuan/.env
    set +a
fi

# ���� ��������Ŀ¼ ����
mkdir -p "${BACKUP_DIR}"

# ���� ִ�б��� ����
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
BACKUP_SCHEMA="${BACKUP_DIR}/schema_${TIMESTAMP}.sql.gz"

log_info "��ʼ�������ݿ� ${DB_NAME}..."

# 1. ȫ������ (����+�ṹ)
if sudo -u postgres pg_dump "${DB_NAME}" --format=custom --compress=9 > "${BACKUP_DIR}/db_${TIMESTAMP}.dump" 2>/dev/null; then
    DUMP_SIZE=$(du -h "${BACKUP_DIR}/db_${TIMESTAMP}.dump" | cut -f1)
    log_info "ȫ���������: db_${TIMESTAMP}.dump (${DUMP_SIZE})"
else
    # ����Ϊ���ı�����
    log_warn "custom��ʽʧ�ܣ�����ΪSQL�ı�����"
    sudo -u postgres pg_dump "${DB_NAME}" | gzip > "${BACKUP_FILE}" 2>/dev/null
    DUMP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    log_info "SQL�������: db_${TIMESTAMP}.sql.gz (${DUMP_SIZE})"
fi

# 2. ���ṹ���� (���ڿ��ٶԱȱ��)
sudo -u postgres pg_dump "${DB_NAME}" --schema-only | gzip > "${BACKUP_SCHEMA}" 2>/dev/null
log_info "�ṹ�������: schema_${TIMESTAMP}.sql.gz"

# ���� ������ڱ��� ����
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "*.dump" -o -name "*.sql.gz" | xargs -I{} find {} -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)
find "${BACKUP_DIR}" \( -name "*.dump" -o -name "*.sql.gz" \) -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true

if [ "${DELETED_COUNT}" -gt 0 ]; then
    log_info "������ ${DELETED_COUNT} �����ڱ��� (>${RETENTION_DAYS}��)"
fi

# ���� ����ͳ�� ����
TOTAL_BACKUPS=$(find "${BACKUP_DIR}" \( -name "*.dump" -o -name "*.sql.gz" \) | wc -l)
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1)
log_info "����Ŀ¼ͳ��: ${TOTAL_BACKUPS} ���ļ�, �ܴ�С ${TOTAL_SIZE}"

# ���� Զ��ͬ�� (��ѡ) ����
if [ -n "${REMOTE_BACKUP_HOST}" ]; then
    log_info "ͬ����Զ�̷����� ${REMOTE_BACKUP_HOST}..."
    rsync -az --timeout=60 "${BACKUP_DIR}/" "${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}/" 2>/dev/null && \
        log_info "Զ��ͬ�����" || \
        log_warn "Զ��ͬ��ʧ�� (������)"
fi

# ���� ��֤���±��� ����
LATEST_DUMP=$(ls -t "${BACKUP_DIR}"/db_*.dump 2>/dev/null | head -1)
if [ -n "${LATEST_DUMP}" ] && [ -s "${LATEST_DUMP}" ]; then
    log_info "������֤: ${LATEST_DUMP} ���� ?"
else
    LATEST_SQL=$(ls -t "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null | head -1)
    if [ -n "${LATEST_SQL}" ] && [ -s "${LATEST_SQL}" ]; then
        log_info "������֤: ${LATEST_SQL} ���� ?"
    else
        log_error "������֤ʧ�ܣ�����Ч�����ļ�"
        send_alert "���ݿⱸ��ʧ�ܣ����������"
        exit 1
    fi
fi

log_info "�����������"
