#!/bin/bash
# ============================================================
# 汇玉源 — PostgreSQL 数据库恢复脚本
# 用法: bash db_restore.sh [备份文件路径]
# 示例: bash db_restore.sh /opt/huiyuanyuan/backups/db_20260227_030000.dump
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

DB_NAME="${DB_NAME:-huiyuanyuan}"
DB_USER="${DB_USER:-huyy_user}"
BACKUP_DIR="${BACKUP_DIR:-/opt/huiyuanyuan/backups}"

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ── 参数检查 ──
BACKUP_FILE="${1:-}"

if [ -z "${BACKUP_FILE}" ]; then
    echo "用法: bash db_restore.sh <备份文件路径>"
    echo ""
    echo "可用备份:"
    echo "─────────────────────────────────────────"
    ls -lh "${BACKUP_DIR}"/db_*.dump "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null | awk '{print "  " $NF " (" $5 ", " $6 " " $7 " " $8 ")"}'
    echo ""
    exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
    log_error "文件不存在: ${BACKUP_FILE}"
    exit 1
fi

# ── 安全确认 ──
echo ""
echo -e "${RED}!!!  警告: 此操作将覆盖现有数据库 ${DB_NAME}  !!!${NC}"
echo ""
echo "备份文件: ${BACKUP_FILE}"
echo "文件大小: $(du -h "${BACKUP_FILE}" | cut -f1)"
echo "目标数据库: ${DB_NAME}"
echo ""
read -p "确认恢复？输入 YES 继续: " CONFIRM

if [ "${CONFIRM}" != "YES" ]; then
    log_warn "已取消恢复操作"
    exit 0
fi

# ── 恢复前：创建当前数据库快照 ──
log_info "恢复前创建安全快照..."
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SAFETY_BACKUP="${BACKUP_DIR}/pre_restore_${TIMESTAMP}.dump"
sudo -u postgres pg_dump "${DB_NAME}" --format=custom --compress=9 > "${SAFETY_BACKUP}" 2>/dev/null
log_info "安全快照: ${SAFETY_BACKUP}"

# ── 停止应用服务 ──
log_info "停止应用服务..."
systemctl stop huiyuanyuan 2>/dev/null || true
sleep 2

# ── 执行恢复 ──
if [[ "${BACKUP_FILE}" == *.dump ]]; then
    log_info "检测到 custom 格式，使用 pg_restore..."
    
    # 断开所有连接
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${DB_NAME}' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
    
    # 删除并重建数据库
    sudo -u postgres dropdb "${DB_NAME}" 2>/dev/null || true
    sudo -u postgres createdb -O "${DB_USER}" "${DB_NAME}"
    
    # 恢复
    sudo -u postgres pg_restore -d "${DB_NAME}" --verbose "${BACKUP_FILE}" 2>&1 | tail -20
    
    # 重新授权
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};"
    
elif [[ "${BACKUP_FILE}" == *.sql.gz ]]; then
    log_info "检测到 gzip SQL 格式..."
    
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${DB_NAME}' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
    sudo -u postgres dropdb "${DB_NAME}" 2>/dev/null || true
    sudo -u postgres createdb -O "${DB_USER}" "${DB_NAME}"
    
    gunzip -c "${BACKUP_FILE}" | sudo -u postgres psql -d "${DB_NAME}" 2>&1 | tail -10
    
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO ${DB_USER};"
    sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};"
else
    log_error "不支持的备份格式: ${BACKUP_FILE}"
    log_error "支持: .dump (pg_dump custom) 或 .sql.gz (gzip SQL)"
    exit 1
fi

# ── 验证恢复 ──
log_info "验证恢复结果..."
TABLE_COUNT=$(sudo -u postgres psql -d "${DB_NAME}" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
USER_COUNT=$(sudo -u postgres psql -d "${DB_NAME}" -tAc "SELECT count(*) FROM users;" 2>/dev/null || echo "N/A")
PRODUCT_COUNT=$(sudo -u postgres psql -d "${DB_NAME}" -tAc "SELECT count(*) FROM products;" 2>/dev/null || echo "N/A")

log_info "数据库表数: ${TABLE_COUNT}"
log_info "用户数: ${USER_COUNT}"
log_info "商品数: ${PRODUCT_COUNT}"

# ── 重启应用 ──
log_info "重启应用服务..."
systemctl start huiyuanyuan

sleep 3
if systemctl is-active --quiet huiyuanyuan; then
    log_info "应用服务恢复正常 ?"
else
    log_error "应用启动失败！请检查: journalctl -u huiyuanyuan -n 30"
fi

echo ""
echo -e "${GREEN}恢复完成！${NC}"
echo "如需回滚，使用安全快照: bash db_restore.sh ${SAFETY_BACKUP}"
