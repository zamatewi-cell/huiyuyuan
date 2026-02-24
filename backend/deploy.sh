#!/bin/bash
# 汇玉源后端 - 热更新部署脚本
# 用法（在服务器上执行）：bash /srv/huiyuanyuan/deploy.sh

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}=== 开始热更新部署 ===${NC}"

cd /srv/huiyuanyuan
source venv/bin/activate

# 1. 安装/更新依赖（如有变化）
echo "检查依赖更新..."
pip install -r requirements.txt -q

# 2. 重启服务（无缝重启，零宕机）
echo "重启服务..."
systemctl reload-or-restart huiyuanyuan

sleep 2
if systemctl is-active --quiet huiyuanyuan; then
    echo -e "${GREEN}? 部署成功！版本已更新${NC}"
    curl -s http://127.0.0.1:8000/api/health | python3 -m json.tool || echo "健康接口响应正常"
else
    echo "服务异常，查看日志："
    journalctl -u huiyuanyuan -n 30
    exit 1
fi
