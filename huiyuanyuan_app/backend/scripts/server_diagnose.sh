#!/bin/bash
# ============================================================
# 汇玉源 — 服务器快速诊断脚本
# 用法: bash server_diagnose.sh
# 功能: 一次性输出所有关键服务状态，用于快速排障
# ============================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}?${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}?${NC} $1"; }
section() { echo -e "\n${CYAN}── $1 ──${NC}"; }

echo -e "${CYAN}════════════════════════════════════════════${NC}"
echo -e "${CYAN}  汇玉源 服务器诊断报告${NC}"
echo -e "${CYAN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}════════════════════════════════════════════${NC}"

# ── 1. 系统信息 ──
section "系统"
echo "  主机名: $(hostname)"
echo "  系统:   $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  内核:   $(uname -r)"
echo "  运行:   $(uptime -p 2>/dev/null || uptime)"

# ── 2. 资源 ──
section "资源"

# CPU
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
CPU_CORES=$(nproc)
echo "  CPU:    ${CPU_CORES} 核, 负载 ${LOAD}"

# 内存
MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEM_USED=$(free -m | grep Mem | awk '{print $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
if [ $MEM_PCT -gt 85 ]; then
    fail "内存: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%) ← 告警"
elif [ $MEM_PCT -gt 70 ]; then
    warn "内存: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%)"
else
    ok "内存: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%)"
fi

# 磁盘
DISK_PCT=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
if [ $DISK_PCT -gt 80 ]; then
    fail "磁盘: ${DISK_PCT}% 已用, 剩余 ${DISK_AVAIL} ← 告警"
else
    ok "磁盘: ${DISK_PCT}% 已用, 剩余 ${DISK_AVAIL}"
fi

# ── 3. 服务状态 ──
section "服务状态"

check_service() {
    local name="$1"
    local display="$2"
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        ok "${display}: 运行中"
    else
        fail "${display}: 已停止"
    fi
}

check_service "huiyuanyuan" "后端 (Gunicorn)"
check_service "nginx" "Nginx"
check_service "postgresql" "PostgreSQL"
check_service "redis-server" "Redis"

# ── 4. API 健康检查 ──
section "API 健康检查"

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

# ── 5. PostgreSQL 详情 ──
section "PostgreSQL"

if systemctl is-active --quiet postgresql; then
    PG_VER=$(psql --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "N/A")
    echo "  版本: ${PG_VER}"
    
    PG_CONN=$(sudo -u postgres psql -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname='huiyuanyuan';" 2>/dev/null || echo "N/A")
    PG_MAX=$(sudo -u postgres psql -tAc "SHOW max_connections;" 2>/dev/null || echo "N/A")
    echo "  连接: ${PG_CONN} / ${PG_MAX}"
    
    DB_SIZE=$(sudo -u postgres psql -tAc "SELECT pg_size_pretty(pg_database_size('huiyuanyuan'));" 2>/dev/null || echo "N/A")
    echo "  数据库大小: ${DB_SIZE}"
    
    TABLE_COUNT=$(sudo -u postgres psql -d huiyuanyuan -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null || echo "N/A")
    echo "  表数量: ${TABLE_COUNT}"
fi

# ── 6. Redis 详情 ──
section "Redis"

if systemctl is-active --quiet redis-server; then
    REDIS_PING=$(redis-cli ping 2>/dev/null || echo "FAIL")
    if echo "$REDIS_PING" | grep -q "PONG"; then
        ok "PING: PONG"
    elif echo "$REDIS_PING" | grep -q "NOAUTH"; then
        ok "PING: 需要密码 (已设密码保护)"
    else
        warn "PING: ${REDIS_PING}"
    fi
    
    REDIS_MEM=$(redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "N/A")
    echo "  内存: ${REDIS_MEM}"
    
    REDIS_KEYS=$(redis-cli dbsize 2>/dev/null | grep -oP '\d+' || echo "N/A")
    echo "  键数: ${REDIS_KEYS}"
fi

# ── 7. Nginx ──
section "Nginx"

if systemctl is-active --quiet nginx; then
    nginx -t 2>&1 | sed 's/^/  /'
    
    WEB_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1/index.html 2>/dev/null || echo "000")
    if [ "$WEB_CODE" = "200" ]; then
        ok "前端: HTTP 200"
    else
        warn "前端: HTTP ${WEB_CODE}"
    fi
fi

# ── 8. 日志 (最近错误) ──
section "最近错误 (huiyuanyuan 服务日志)"

ERRORS=$(journalctl -u huiyuanyuan --since "1 hour ago" --no-pager -p err 2>/dev/null | tail -5)
if [ -n "$ERRORS" ]; then
    echo "$ERRORS" | sed 's/^/  /'
else
    ok "最近1小时无错误日志"
fi

# ── 9. 备份状态 ──
section "备份"

BACKUP_DIR="/opt/huiyuanyuan/backups"
if [ -d "$BACKUP_DIR" ]; then
    LATEST=$(ls -t "$BACKUP_DIR"/*.dump "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        LATEST_NAME=$(basename "$LATEST")
        LATEST_SIZE=$(du -h "$LATEST" | cut -f1)
        LATEST_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST")) / 3600 ))
        if [ $LATEST_AGE -gt 48 ]; then
            fail "最新备份: ${LATEST_NAME} (${LATEST_SIZE}, ${LATEST_AGE}小时前) ← 超过48小时"
        else
            ok "最新备份: ${LATEST_NAME} (${LATEST_SIZE}, ${LATEST_AGE}小时前)"
        fi
    else
        warn "无备份文件"
    fi
    TOTAL=$(ls "$BACKUP_DIR"/*.dump "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "  共 ${TOTAL} 个备份, 总大小 ${TOTAL_SIZE}"
else
    warn "备份目录不存在: ${BACKUP_DIR}"
fi

# ── 10. 快照 ──
section "部署快照"

SNAP_DIR="/opt/huiyuanyuan/snapshots"
if [ -d "$SNAP_DIR" ]; then
    ls -d "$SNAP_DIR"/*/ 2>/dev/null | while read d; do
        echo "  $(basename $d)"
    done
    SNAP_COUNT=$(ls -d "$SNAP_DIR"/*/ 2>/dev/null | wc -l)
    echo "  共 ${SNAP_COUNT} 个快照"
else
    echo "  无快照目录"
fi

# ── 11. 防火墙 ──
section "防火墙 (UFW)"

if command -v ufw &>/dev/null; then
    ufw status 2>/dev/null | sed 's/^/  /'
else
    echo "  UFW 未安装"
fi

# ── 12. SSL 证书 ──
section "SSL 证书"

CERT_PATH=$(find /etc/letsencrypt/live/ -name "fullchain.pem" 2>/dev/null | head -1)
if [ -n "$CERT_PATH" ]; then
    DOMAIN=$(echo "$CERT_PATH" | grep -oP 'live/\K[^/]+')
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    
    if [ $DAYS_LEFT -lt 7 ]; then
        fail "域名 ${DOMAIN}: 仅剩 ${DAYS_LEFT} 天! 到期 ${EXPIRY}"
    elif [ $DAYS_LEFT -lt 30 ]; then
        warn "域名 ${DOMAIN}: 剩 ${DAYS_LEFT} 天 (到期 ${EXPIRY})"
    else
        ok "域名 ${DOMAIN}: 剩 ${DAYS_LEFT} 天 (到期 ${EXPIRY})"
    fi
else
    echo "  未配置 SSL 证书"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════${NC}"
echo -e "${CYAN}  诊断完成${NC}"
echo -e "${CYAN}════════════════════════════════════════════${NC}"
