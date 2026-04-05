#!/bin/bash
# ============================================================
# ����Դ �� PostgreSQL ���ݿ�ָ��ű�
# �÷�: bash db_restore.sh [�����ļ�·��]
# ʾ��: bash db_restore.sh /opt/huiyuyuan/backups/db_20260227_030000.dump
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

DB_NAME="${DB_NAME:-huiyuyuan}"
DB_USER="${DB_USER:-huyy_user}"
BACKUP_DIR="${BACKUP_DIR:-/opt/huiyuyuan/backups}"

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ���� ������� ����
BACKUP_FILE="${1:-}"

if [ -z "${BACKUP_FILE}" ]; then
    echo "�÷�: bash db_restore.sh <�����ļ�·��>"
    echo ""
    echo "���ñ���:"
    echo "����������������������������������������������������������������������������������"
    ls -lh "${BACKUP_DIR}"/db_*.dump "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null | awk '{print "  " $NF " (" $5 ", " $6 " " $7 " " $8 ")"}'
    echo ""
    exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
    log_error "�ļ�������: ${BACKUP_FILE}"
    exit 1
fi

# ���� ��ȫȷ�� ����
echo ""
echo -e "${RED}!!!  ����: �˲����������������ݿ� ${DB_NAME}  !!!${NC}"
echo ""
echo "�����ļ�: ${BACKUP_FILE}"
echo "�ļ���С: $(du -h "${BACKUP_FILE}" | cut -f1)"
echo "Ŀ�����ݿ�: ${DB_NAME}"
echo ""
read -p "ȷ�ϻָ������� YES ����: " CONFIRM

if [ "${CONFIRM}" != "YES" ]; then
    log_warn "��ȡ���ָ�����"
    exit 0
fi

# ���� �ָ�ǰ��������ǰ���ݿ���� ����
log_info "�ָ�ǰ������ȫ����..."
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SAFETY_BACKUP="${BACKUP_DIR}/pre_restore_${TIMESTAMP}.dump"
sudo -u postgres pg_dump "${DB_NAME}" --format=custom --compress=9 > "${SAFETY_BACKUP}" 2>/dev/null
log_info "��ȫ����: ${SAFETY_BACKUP}"

# ���� ֹͣӦ�÷��� ����
log_info "ֹͣӦ�÷���..."
systemctl stop huiyuyuan 2>/dev/null || true
sleep 2

# ���� ִ�лָ� ����
if [[ "${BACKUP_FILE}" == *.dump ]]; then
    log_info "��⵽ custom ��ʽ��ʹ�� pg_restore..."
    
    # �Ͽ���������
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${DB_NAME}' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
    
    # ɾ�����ؽ����ݿ�
    sudo -u postgres dropdb "${DB_NAME}" 2>/dev/null || true
    sudo -u postgres createdb -O "${DB_USER}" "${DB_NAME}"
    
    # �ָ�
    sudo -u postgres pg_restore -d "${DB_NAME}" --verbose "${BACKUP_FILE}" 2>&1 | tail -20
    
    # ������Ȩ
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};"
    
elif [[ "${BACKUP_FILE}" == *.sql.gz ]]; then
    log_info "��⵽ gzip SQL ��ʽ..."
    
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${DB_NAME}' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
    sudo -u postgres dropdb "${DB_NAME}" 2>/dev/null || true
    sudo -u postgres createdb -O "${DB_USER}" "${DB_NAME}"
    
    gunzip -c "${BACKUP_FILE}" | sudo -u postgres psql -d "${DB_NAME}" 2>&1 | tail -10
    
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};"
else
    log_error "��֧�ֵı��ݸ�ʽ: ${BACKUP_FILE}"
    log_error "֧��: .dump (pg_dump custom) �� .sql.gz (gzip SQL)"
    exit 1
fi

# ���� ��֤�ָ� ����
log_info "��֤�ָ����..."
TABLE_COUNT=$(sudo -u postgres psql -d "${DB_NAME}" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
USER_COUNT=$(sudo -u postgres psql -d "${DB_NAME}" -tAc "SELECT count(*) FROM users;" 2>/dev/null || echo "N/A")
PRODUCT_COUNT=$(sudo -u postgres psql -d "${DB_NAME}" -tAc "SELECT count(*) FROM products;" 2>/dev/null || echo "N/A")

log_info "���ݿ����: ${TABLE_COUNT}"
log_info "�û���: ${USER_COUNT}"
log_info "��Ʒ��: ${PRODUCT_COUNT}"

# ���� ����Ӧ�� ����
log_info "����Ӧ�÷���..."
systemctl start huiyuyuan

sleep 3
if systemctl is-active --quiet huiyuyuan; then
    log_info "Ӧ�÷���ָ����� ?"
else
    log_error "Ӧ�����ʧ�ܣ�����: journalctl -u huiyuyuan -n 30"
fi

echo ""
echo -e "${GREEN}�ָ���ɣ�${NC}"
echo "����ع���ʹ�ð�ȫ����: bash db_restore.sh ${SAFETY_BACKUP}"
