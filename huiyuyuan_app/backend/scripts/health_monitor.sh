#!/bin/bash
# ============================================================
# ����Դ �� ������ؽű�
# Crontab: */5 * * * * /opt/huiyuyuan/health_monitor.sh >> /var/log/huiyuyuan/monitor.log 2>&1
# ���: API ��Ӧ | PostgreSQL | Redis | ���� | �ڴ� | systemd ����
# ============================================================

set -uo pipefail

# ���� ���� ����
APP_NAME="huiyuyuan"
HEALTH_URL="http://127.0.0.1:8000/api/health"
LOG_PREFIX="[MONITOR $(date '+%Y-%m-%d %H:%M:%S')]"

# �澯��ֵ
DISK_WARN_PERCENT=80
MEMORY_WARN_PERCENT=85
RESPONSE_TIMEOUT=10   # ������鳬ʱ����

# ���� ���� .env (��ȡ webhook ��ַ) ����
if [ -f /srv/huiyuyuan/.env ]; then
    set -a
    source /srv/huiyuyuan/.env 2>/dev/null || true
    set +a
fi

# ���� ���� ����
log_info()  { echo "${LOG_PREFIX} [OK]    $1"; }
log_warn()  { echo "${LOG_PREFIX} [WARN]  $1"; }
log_error() { echo "${LOG_PREFIX} [FAIL]  $1"; }

# ���͸澯 (����/��ҵ΢��)
send_alert() {
    local level="$1"   # WARN / CRITICAL
    local message="$2"
    local full_msg="[����Դ���] [${level}] ${message} | ʱ��: $(date '+%m-%d %H:%M')"

    # ����
    if [ -n "${DINGTALK_WEBHOOK:-}" ]; then
        curl -s -m 5 -X POST "${DINGTALK_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${full_msg}\"}}" \
            > /dev/null 2>&1 || true
    fi

    # ��ҵ΢��
    if [ -n "${WECHAT_WEBHOOK:-}" ]; then
        curl -s -m 5 -X POST "${WECHAT_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${full_msg}\"}}" \
            > /dev/null 2>&1 || true
    fi
}

# ���� ��ֹ����ִ�� ����
LOCK_FILE="/tmp/${APP_NAME}_monitor.lock"
if [ -f "${LOCK_FILE}" ]; then
    LOCK_PID=$(cat "${LOCK_FILE}")
    if kill -0 "${LOCK_PID}" 2>/dev/null; then
        echo "${LOG_PREFIX} [SKIP] ��һ�ּ���������� (PID ${LOCK_PID})"
        exit 0
    fi
fi
echo $$ > "${LOCK_FILE}"
trap "rm -f ${LOCK_FILE}" EXIT

ALERT_TRIGGERED=false

# ============================================================
# ��� 1: systemd ����״̬
# ============================================================
if systemctl is-active --quiet "${APP_NAME}"; then
    log_info "����: ${APP_NAME} ������"
else
    log_error "����: ${APP_NAME} ��ֹͣ�������Զ�����..."
    systemctl restart "${APP_NAME}" 2>/dev/null || true
    sleep 3
    if systemctl is-active --quiet "${APP_NAME}"; then
        log_warn "�������Զ��ָ�"
        send_alert "WARN" "��˷�����ֹͣ�����Զ�����ָ�"
    else
        log_error "��������ʧ�ܣ�"
        send_alert "CRITICAL" "��˷���ֹͣ������ʧ�ܣ���������¼�Ų�"
        ALERT_TRIGGERED=true
    fi
fi

# ============================================================
# ��� 2: API �������
# ============================================================
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m ${RESPONSE_TIMEOUT} "${HEALTH_URL}" 2>/dev/null || echo "000")
RESPONSE_TIME=$(curl -s -o /dev/null -w '%{time_total}' -m ${RESPONSE_TIMEOUT} "${HEALTH_URL}" 2>/dev/null || echo "0")

if [ "${HTTP_CODE}" = "200" ]; then
    log_info "API: HTTP 200 (${RESPONSE_TIME}s)"
    # ��Ӧ���澯 (>5s)
    if [ "$(echo "${RESPONSE_TIME} > 5.0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
        log_warn "API: ��Ӧ���� ${RESPONSE_TIME}s"
        send_alert "WARN" "API ��Ӧ����: ${RESPONSE_TIME}s"
    fi
else
    log_error "API: HTTP ${HTTP_CODE} (���� 200)"
    send_alert "CRITICAL" "API �������ʧ��: HTTP ${HTTP_CODE}"
    ALERT_TRIGGERED=true
fi

# ============================================================
# ��� 3: PostgreSQL
# ============================================================
if systemctl is-active --quiet postgresql; then
    # ���������
    PG_CONN=$(sudo -u postgres psql -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname='huiyuyuan';" 2>/dev/null || echo "N/A")
    PG_MAX=$(sudo -u postgres psql -tAc "SHOW max_connections;" 2>/dev/null || echo "N/A")
    log_info "PostgreSQL: ��Ծ���� ${PG_CONN}/${PG_MAX}"
    
    # ����������80%�澯
    if [ "${PG_CONN}" != "N/A" ] && [ "${PG_MAX}" != "N/A" ]; then
        CONN_RATIO=$((PG_CONN * 100 / PG_MAX))
        if [ ${CONN_RATIO} -gt 80 ]; then
            log_warn "PostgreSQL: ���������� ${PG_CONN}/${PG_MAX} (${CONN_RATIO}%)"
            send_alert "WARN" "PostgreSQL ����������: ${PG_CONN}/${PG_MAX}"
        fi
    fi
else
    log_error "PostgreSQL: ����δ���У�"
    send_alert "CRITICAL" "PostgreSQL ����ֹͣ��"
    ALERT_TRIGGERED=true
fi

# ============================================================
# ��� 4: Redis
# ============================================================
if systemctl is-active --quiet redis-server; then
    # ���� ping (���ǿ���������)
    REDIS_PING=$(redis-cli ping 2>/dev/null || redis-cli -a "$(grep -oP 'requirepass \K.*' /etc/redis/redis.conf 2>/dev/null || echo '')" ping 2>/dev/null || echo "FAIL")
    if echo "${REDIS_PING}" | grep -q "PONG"; then
        REDIS_MEM=$(redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "N/A")
        log_info "Redis: PONG (�ڴ�: ${REDIS_MEM})"
    else
        log_warn "Redis: �������е� PING ʧ�� (������Ҫ����)"
    fi
else
    log_warn "Redis: ����δ���� (������������Ϊ�ڴ滺��)"
fi

# ============================================================
# ��� 5: Nginx
# ============================================================
if systemctl is-active --quiet nginx; then
    # ���ǰ�˿ɷ�����
    WEB_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1/index.html 2>/dev/null || echo "000")
    if [ "${WEB_CODE}" = "200" ]; then
        log_info "Nginx: ������, ǰ�� HTTP 200"
    else
        log_warn "Nginx: ���е�ǰ�˷��� HTTP ${WEB_CODE}"
    fi
else
    log_error "Nginx: ����δ���У�"
    send_alert "CRITICAL" "Nginx ����ֹͣ��"
    ALERT_TRIGGERED=true
fi

# ============================================================
# ��� 6: ���̿ռ�
# ============================================================
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')

if [ "${DISK_USAGE}" -gt "${DISK_WARN_PERCENT}" ]; then
    log_warn "����: ${DISK_USAGE}% ���� (ʣ�� ${DISK_AVAIL})"
    send_alert "WARN" "���̿ռ䲻��: ${DISK_USAGE}% ����, ʣ�� ${DISK_AVAIL}"
else
    log_info "����: ${DISK_USAGE}% ���� (ʣ�� ${DISK_AVAIL})"
fi

# ============================================================
# ��� 7: �ڴ�
# ============================================================
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

if [ "${MEM_PERCENT}" -gt "${MEMORY_WARN_PERCENT}" ]; then
    log_warn "�ڴ�: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
    send_alert "WARN" "�ڴ�ʹ���ʸ�: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
else
    log_info "�ڴ�: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
fi

# ============================================================
# ��� 8: ��־�ļ���С
# ============================================================
LOG_DIR="/var/log/huiyuyuan"
if [ -d "${LOG_DIR}" ]; then
    LOG_SIZE=$(du -sh "${LOG_DIR}" 2>/dev/null | cut -f1)
    log_info "��־: ${LOG_DIR} �ܴ�С ${LOG_SIZE}"
fi

# ============================================================
# ����
# ============================================================
if [ "${ALERT_TRIGGERED}" = true ]; then
    log_error "=== ������: ������������ ==="
else
    log_info "=== ������: һ������ ==="
fi
