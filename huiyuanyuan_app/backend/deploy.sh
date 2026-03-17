#!/bin/bash
# ============================================================
# 汇玉源 v4.0 — 服务器端热更新部署脚本
# 用法（在服务器上执行）：bash /srv/huiyuanyuan/deploy.sh
# 功能: 快照 → 依赖安装 → 重启 → 健康检查 → 失败自动回滚
# ============================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

APP_DIR="/srv/huiyuanyuan"
SNAP_DIR="/opt/huiyuanyuan/snapshots"
HEALTH_URL="http://127.0.0.1:8000/api/health"
MAX_SNAPS=3

echo -e "${YELLOW}=== 开始热更新部署 ===${NC}"

cd "${APP_DIR}"
source venv/bin/activate

# 1. 创建部署前快照
SNAP_TS=$(date '+%Y%m%d_%H%M%S')
SNAP_PATH="${SNAP_DIR}/${SNAP_TS}"
mkdir -p "${SNAP_PATH}"
cp -a main.py requirements.txt "${SNAP_PATH}/" 2>/dev/null || true
cp -a config.py database.py security.py store.py logging_config.py "${SNAP_PATH}/" 2>/dev/null || true
cp -a alembic.ini "${SNAP_PATH}/" 2>/dev/null || true
cp -a routers services schemas data migrations "${SNAP_PATH}/" 2>/dev/null || true
echo -e "${GREEN}快照已创建: ${SNAP_TS}${NC}"

# 清理旧快照 (保留最近 N 个)
cd "${SNAP_DIR}"
ls -dt */ 2>/dev/null | tail -n +$((MAX_SNAPS + 1)) | xargs -r rm -rf
cd "${APP_DIR}"

# 2. 安装/更新依赖
echo "检查依赖更新..."
pip install -r requirements.txt -q

# 2.5. Run database migrations (if DB available)
if [ -f "${APP_DIR}/alembic.ini" ]; then
    echo "Running database migrations..."
    if alembic upgrade head 2>&1; then
        echo -e "${GREEN}Migrations applied successfully${NC}"
    else
        echo -e "${YELLOW}Migration skipped (DB may not be configured)${NC}"
    fi
fi

# 3. 更新 Nginx (如有新配置)
if [ -f "${APP_DIR}/nginx_production.conf" ]; then
    cp "${APP_DIR}/nginx_production.conf" /etc/nginx/sites-available/huiyuanyuan
    mkdir -p /etc/nginx/snippets
    cp "${APP_DIR}/nginx_proxy_params.conf" /etc/nginx/snippets/proxy_params.conf 2>/dev/null || true
    nginx -t 2>/dev/null && systemctl reload nginx && echo "Nginx 配置已更新"
fi

# 4. 重启服务（零宕机 graceful restart）
echo "重启服务..."
systemctl reload-or-restart huiyuanyuan

# 5. 健康检查
sleep 3
HEALTHY=false
for i in $(seq 1 5); do
    STATUS=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "${HEALTH_URL}" 2>/dev/null || echo "000")
    if [ "${STATUS}" = "200" ]; then
        echo -e "${GREEN}健康检查通过 (尝试 $i/5)${NC}"
        HEALTHY=true
        break
    fi
    echo "等待服务就绪... ($i/5)"
    sleep 2
done

if [ "${HEALTHY}" = true ]; then
    echo -e "${GREEN}部署成功！版本已更新${NC}"
    curl -s "${HEALTH_URL}" | python3 -m json.tool 2>/dev/null || true
else
    echo -e "${RED}健康检查失败！自动回滚到 ${SNAP_TS}...${NC}"
    cp -a "${SNAP_PATH}"/* "${APP_DIR}/" 2>/dev/null || true
    systemctl restart huiyuanyuan
    sleep 3
    ROLLBACK_STATUS=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "${HEALTH_URL}" 2>/dev/null || echo "000")
    if [ "${ROLLBACK_STATUS}" = "200" ]; then
        echo -e "${YELLOW}回滚成功，但新版本有问题，请排查${NC}"
    else
        echo -e "${RED}回滚后仍然失败！请手动排查: journalctl -u huiyuanyuan -n 50${NC}"
    fi
    exit 1
fi
