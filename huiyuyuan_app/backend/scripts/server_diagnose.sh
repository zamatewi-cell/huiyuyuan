#!/bin/bash
# ============================================================
# ����Դ �� ������������Ͻű�
# �÷�: bash server_diagnose.sh
# ����: һ����������йؼ�����״̬�����ڿ�������
# ============================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}?${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}?${NC} $1"; }
section() { echo -e "\n${CYAN}���� $1 ����${NC}"; }

echo -e "${CYAN}�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T${NC}"
echo -e "${CYAN}  ����Դ ��������ϱ���${NC}"
echo -e "${CYAN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T${NC}"

# ���� 1. ϵͳ��Ϣ ����
section "ϵͳ"
echo "  ������: $(hostname)"
echo "  ϵͳ:   $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  �ں�:   $(uname -r)"
echo "  ����:   $(uptime -p 2>/dev/null || uptime)"

# ���� 2. ��Դ ����
section "��Դ"

# CPU
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
CPU_CORES=$(nproc)
echo "  CPU:    ${CPU_CORES} ��, ���� ${LOAD}"

# �ڴ�
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
if [ $MEM_PCT -gt 85 ]; then
    fail "�ڴ�: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%) �� �澯"
elif [ $MEM_PCT -gt 70 ]; then
    warn "�ڴ�: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%)"
else
    ok "�ڴ�: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%)"
fi

# ����
DISK_PCT=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
if [ $DISK_PCT -gt 80 ]; then
    fail "����: ${DISK_PCT}% ����, ʣ�� ${DISK_AVAIL} �� �澯"
else
    ok "����: ${DISK_PCT}% ����, ʣ�� ${DISK_AVAIL}"
fi

# ���� 3. ����״̬ ����
section "����״̬"

check_service() {
    local name="$1"
    local display="$2"
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        ok "${display}: ������"
    else
        fail "${display}: ��ֹͣ"
    fi
}

check_service "huiyuyuan" "��� (Gunicorn)"
check_service "nginx" "Nginx"
check_service "postgresql" "PostgreSQL"
check_service "redis-server" "Redis"

# ���� 4. API ������� ����
section "API �������"

HTTP_CODE=$(curl -s -o /tmp/health_response.json -w '%{http_code}' -m 10 http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
RESPONSE_TIME=$(curl -s -o /dev/null -w '%{time_total}' -m 10 http://127.0.0.1:8000/api/health 2>/dev/null || echo "0")

if [ "$HTTP_CODE" = "200" ]; then
    ok "API: HTTP 200 (${RESPONSE_TIME}s)"
    if command -v jq &>/dev/null && [ -f /tmp/health_response.json ]; then
        cat /tmp/health_response.json | jq . 2>/dev/null | sed 's/^/  /'
    elif command -v python3 &>/dev/null; then
        cat /tmp/health_response.json | python3 -m json.tool 2>/dev/null | sed 's/^/  /'
    fi
else
    fail "API: HTTP ${HTTP_CODE}"
fi
rm -f /tmp/health_response.json

# ���� 5. PostgreSQL ���� ����
section "PostgreSQL"

if systemctl is-active --quiet postgresql; then
    PG_VER=$(psql --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "N/A")
    echo "  �汾: ${PG_VER}"
    
    PG_CONN=$(sudo -u postgres psql -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname='huiyuyuan';" 2>/dev/null || echo "N/A")
    PG_MAX=$(sudo -u postgres psql -tAc "SHOW max_connections;" 2>/dev/null || echo "N/A")
    echo "  ����: ${PG_CONN} / ${PG_MAX}"
    
    DB_SIZE=$(sudo -u postgres psql -tAc "SELECT pg_size_pretty(pg_database_size('huiyuyuan'));" 2>/dev/null || echo "N/A")
    echo "  ���ݿ��С: ${DB_SIZE}"
    
    TABLE_COUNT=$(sudo -u postgres psql -d huiyuyuan -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null || echo "N/A")
    echo "  ������: ${TABLE_COUNT}"
fi

# ���� 6. Redis ���� ����
section "Redis"

if systemctl is-active --quiet redis-server; then
    REDIS_PING=$(redis-cli ping 2>/dev/null || echo "FAIL")
    if echo "$REDIS_PING" | grep -q "PONG"; then
        ok "PING: PONG"
    elif echo "$REDIS_PING" | grep -q "NOAUTH"; then
        ok "PING: ��Ҫ���� (�������뱣��)"
    else
        warn "PING: ${REDIS_PING}"
    fi
    
    REDIS_MEM=$(redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "N/A")
    echo "  �ڴ�: ${REDIS_MEM}"
    
    REDIS_KEYS=$(redis-cli dbsize 2>/dev/null | grep -oP '\d+' || echo "N/A")
    echo "  ����: ${REDIS_KEYS}"
fi

# ���� 7. Nginx ����
section "Nginx"

if systemctl is-active --quiet nginx; then
    nginx -t 2>&1 | sed 's/^/  /'
    
    WEB_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1/index.html 2>/dev/null || echo "000")
    if [ "$WEB_CODE" = "200" ]; then
        ok "ǰ��: HTTP 200"
    else
        warn "ǰ��: HTTP ${WEB_CODE}"
    fi
fi

# ���� 8. ��־ (�������) ����
section "������� (huiyuyuan ������־)"

ERRORS=$(journalctl -u huiyuyuan --since "1 hour ago" --no-pager -p err 2>/dev/null | tail -5)
if [ -n "$ERRORS" ]; then
    echo "$ERRORS" | sed 's/^/  /'
else
    ok "���1Сʱ�޴�����־"
fi

# ���� 9. ����״̬ ����
section "����"

BACKUP_DIR="/opt/huiyuyuan/backups"
if [ -d "$BACKUP_DIR" ]; then
    LATEST=$(ls -t "$BACKUP_DIR"/*.dump "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        LATEST_NAME=$(basename "$LATEST")
        LATEST_SIZE=$(du -h "$LATEST" | cut -f1)
        LATEST_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST")) / 3600 ))
        if [ $LATEST_AGE -gt 48 ]; then
            fail "���±���: ${LATEST_NAME} (${LATEST_SIZE}, ${LATEST_AGE}Сʱǰ) �� ����48Сʱ"
        else
            ok "���±���: ${LATEST_NAME} (${LATEST_SIZE}, ${LATEST_AGE}Сʱǰ)"
        fi
    else
        warn "�ޱ����ļ�"
    fi
    TOTAL=$(ls "$BACKUP_DIR"/*.dump "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "  �� ${TOTAL} ������, �ܴ�С ${TOTAL_SIZE}"
else
    warn "����Ŀ¼������: ${BACKUP_DIR}"
fi

# ���� 10. ���� ����
section "�������"

SNAP_DIR="/opt/huiyuyuan/snapshots"
if [ -d "$SNAP_DIR" ]; then
    ls -d "$SNAP_DIR"/*/ 2>/dev/null | while read d; do
        echo "  $(basename $d)"
    done
    SNAP_COUNT=$(ls -d "$SNAP_DIR"/*/ 2>/dev/null | wc -l)
    echo "  �� ${SNAP_COUNT} ������"
else
    echo "  �޿���Ŀ¼"
fi

# ���� 11. ����ǽ ����
section "����ǽ (UFW)"

if command -v ufw &>/dev/null; then
    ufw status 2>/dev/null | sed 's/^/  /'
else
    echo "  UFW δ��װ"
fi

# ���� 12. SSL ֤�� ����
section "SSL ֤��"

CERT_PATH=$(find /etc/letsencrypt/live/ -name "fullchain.pem" 2>/dev/null | head -1)
if [ -n "$CERT_PATH" ]; then
    DOMAIN=$(echo "$CERT_PATH" | grep -oP 'live/\K[^/]+')
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    
    if [ $DAYS_LEFT -lt 7 ]; then
        fail "���� ${DOMAIN}: ��ʣ ${DAYS_LEFT} ��! ���� ${EXPIRY}"
    elif [ $DAYS_LEFT -lt 30 ]; then
        warn "���� ${DOMAIN}: ʣ ${DAYS_LEFT} �� (���� ${EXPIRY})"
    else
        ok "���� ${DOMAIN}: ʣ ${DAYS_LEFT} �� (���� ${EXPIRY})"
    fi
else
    echo "  δ���� SSL ֤��"
fi

echo ""
echo -e "${CYAN}�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T${NC}"
echo -e "${CYAN}  ������${NC}"
echo -e "${CYAN}�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T${NC}"
