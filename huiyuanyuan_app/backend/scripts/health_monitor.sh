#!/bin/bash
# ============================================================
# 汇玉源 — 健康监控脚本
# Crontab: */5 * * * * /opt/huiyuanyuan/health_monitor.sh >> /var/log/huiyuanyuan/monitor.log 2>&1
# 监控: API 响应 | PostgreSQL | Redis | 磁盘 | 内存 | systemd 服务
# ============================================================

set -uo pipefail

# ── 配置 ──
APP_NAME="huiyuanyuan"
HEALTH_URL="http://127.0.0.1:8000/api/health"
LOG_PREFIX="[MONITOR $(date '+%Y-%m-%d %H:%M:%S')]"

# 告警阈值
DISK_WARN_PERCENT=80
MEMORY_WARN_PERCENT=85
RESPONSE_TIMEOUT=10   # 健康检查超时秒数

# ── 加载 .env (获取 webhook 地址) ──
if [ -f /srv/huiyuanyuan/.env ]; then
    set -a
    source /srv/huiyuanyuan/.env 2>/dev/null || true
    set +a
fi

# ── 函数 ──
log_info()  { echo "${LOG_PREFIX} [OK]    $1"; }
log_warn()  { echo "${LOG_PREFIX} [WARN]  $1"; }
log_error() { echo "${LOG_PREFIX} [FAIL]  $1"; }

# 发送告警 (钉钉/企业微信)
send_alert() {
    local level="$1"   # WARN / CRITICAL
    local message="$2"
    local full_msg="[汇玉源监控] [${level}] ${message} | 时间: $(date '+%m-%d %H:%M')"

    # 钉钉
    if [ -n "${DINGTALK_WEBHOOK:-}" ]; then
        curl -s -m 5 -X POST "${DINGTALK_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${full_msg}\"}}" \
            > /dev/null 2>&1 || true
    fi

    # 企业微信
    if [ -n "${WECHAT_WEBHOOK:-}" ]; then
        curl -s -m 5 -X POST "${WECHAT_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${full_msg}\"}}" \
            > /dev/null 2>&1 || true
    fi
}

# ── 防止并发执行 ──
LOCK_FILE="/tmp/${APP_NAME}_monitor.lock"
if [ -f "${LOCK_FILE}" ]; then
    LOCK_PID=$(cat "${LOCK_FILE}")
    if kill -0 "${LOCK_PID}" 2>/dev/null; then
        echo "${LOG_PREFIX} [SKIP] 上一轮监控仍在运行 (PID ${LOCK_PID})"
        exit 0
    fi
fi
echo $$ > "${LOCK_FILE}"
trap "rm -f ${LOCK_FILE}" EXIT

ALERT_TRIGGERED=false

# ============================================================
# 检查 1: systemd 服务状态
# ============================================================
if systemctl is-active --quiet "${APP_NAME}"; then
    log_info "服务: ${APP_NAME} 运行中"
else
    log_error "服务: ${APP_NAME} 已停止！尝试自动重启..."
    systemctl restart "${APP_NAME}" 2>/dev/null || true
    sleep 3
    if systemctl is-active --quiet "${APP_NAME}"; then
        log_warn "服务已自动恢复"
        send_alert "WARN" "后端服务曾停止，已自动重启恢复"
    else
        log_error "服务重启失败！"
        send_alert "CRITICAL" "后端服务停止且重启失败！请立即登录排查"
        ALERT_TRIGGERED=true
    fi
fi

# ============================================================
# 检查 2: API 健康检查
# ============================================================
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m ${RESPONSE_TIMEOUT} "${HEALTH_URL}" 2>/dev/null || echo "000")
RESPONSE_TIME=$(curl -s -o /dev/null -w '%{time_total}' -m ${RESPONSE_TIMEOUT} "${HEALTH_URL}" 2>/dev/null || echo "0")

if [ "${HTTP_CODE}" = "200" ]; then
    log_info "API: HTTP 200 (${RESPONSE_TIME}s)"
    # 响应慢告警 (>5s)
    if [ "$(echo "${RESPONSE_TIME} > 5.0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
        log_warn "API: 响应缓慢 ${RESPONSE_TIME}s"
        send_alert "WARN" "API 响应缓慢: ${RESPONSE_TIME}s"
    fi
else
    log_error "API: HTTP ${HTTP_CODE} (期望 200)"
    send_alert "CRITICAL" "API 健康检查失败: HTTP ${HTTP_CODE}"
    ALERT_TRIGGERED=true
fi

# ============================================================
# 检查 3: PostgreSQL
# ============================================================
if systemctl is-active --quiet postgresql; then
    # 检查连接数
    PG_CONN=$(sudo -u postgres psql -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname='huiyuanyuan';" 2>/dev/null || echo "N/A")
    PG_MAX=$(sudo -u postgres psql -tAc "SHOW max_connections;" 2>/dev/null || echo "N/A")
    log_info "PostgreSQL: 活跃连接 ${PG_CONN}/${PG_MAX}"
    
    # 连接数超过80%告警
    if [ "${PG_CONN}" != "N/A" ] && [ "${PG_MAX}" != "N/A" ]; then
        CONN_RATIO=$((PG_CONN * 100 / PG_MAX))
        if [ ${CONN_RATIO} -gt 80 ]; then
            log_warn "PostgreSQL: 连接数过高 ${PG_CONN}/${PG_MAX} (${CONN_RATIO}%)"
            send_alert "WARN" "PostgreSQL 连接数过高: ${PG_CONN}/${PG_MAX}"
        fi
    fi
else
    log_error "PostgreSQL: 服务未运行！"
    send_alert "CRITICAL" "PostgreSQL 服务停止！"
    ALERT_TRIGGERED=true
fi

# ============================================================
# 检查 4: Redis
# ============================================================
if systemctl is-active --quiet redis-server; then
    # 尝试 ping (考虑可能有密码)
    REDIS_PING=$(redis-cli ping 2>/dev/null || redis-cli -a "$(grep -oP 'requirepass \K.*' /etc/redis/redis.conf 2>/dev/null || echo '')" ping 2>/dev/null || echo "FAIL")
    if echo "${REDIS_PING}" | grep -q "PONG"; then
        REDIS_MEM=$(redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "N/A")
        log_info "Redis: PONG (内存: ${REDIS_MEM})"
    else
        log_warn "Redis: 服务运行但 PING 失败 (可能需要密码)"
    fi
else
    log_warn "Redis: 服务未运行 (非致命，降级为内存缓存)"
fi

# ============================================================
# 检查 5: Nginx
# ============================================================
if systemctl is-active --quiet nginx; then
    # 检查前端可访问性
    WEB_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1/index.html 2>/dev/null || echo "000")
    if [ "${WEB_CODE}" = "200" ]; then
        log_info "Nginx: 运行中, 前端 HTTP 200"
    else
        log_warn "Nginx: 运行但前端返回 HTTP ${WEB_CODE}"
    fi
else
    log_error "Nginx: 服务未运行！"
    send_alert "CRITICAL" "Nginx 服务停止！"
    ALERT_TRIGGERED=true
fi

# ============================================================
# 检查 6: 磁盘空间
# ============================================================
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')

if [ "${DISK_USAGE}" -gt "${DISK_WARN_PERCENT}" ]; then
    log_warn "磁盘: ${DISK_USAGE}% 已用 (剩余 ${DISK_AVAIL})"
    send_alert "WARN" "磁盘空间不足: ${DISK_USAGE}% 已用, 剩余 ${DISK_AVAIL}"
else
    log_info "磁盘: ${DISK_USAGE}% 已用 (剩余 ${DISK_AVAIL})"
fi

# ============================================================
# 检查 7: 内存
# ============================================================
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

if [ "${MEM_PERCENT}" -gt "${MEMORY_WARN_PERCENT}" ]; then
    log_warn "内存: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
    send_alert "WARN" "内存使用率高: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
else
    log_info "内存: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
fi

# ============================================================
# 检查 8: 日志文件大小
# ============================================================
LOG_DIR="/var/log/huiyuanyuan"
if [ -d "${LOG_DIR}" ]; then
    LOG_SIZE=$(du -sh "${LOG_DIR}" 2>/dev/null | cut -f1)
    log_info "日志: ${LOG_DIR} 总大小 ${LOG_SIZE}"
fi

# ============================================================
# 汇总
# ============================================================
if [ "${ALERT_TRIGGERED}" = true ]; then
    log_error "=== 监控完成: 发现严重问题 ==="
else
    log_info "=== 监控完成: 一切正常 ==="
fi
