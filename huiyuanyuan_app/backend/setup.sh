#!/bin/bash
# 汇玉源后端 - 服务器一键初始化脚本
# 用法: bash /srv/huiyuanyuan/setup.sh
# 服务器: Ubuntu 22.04 LTS

set -e  # 出错立即停止
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}=== 汇玉源后端初始化脚本 ===${NC}"

# ============ 1. 系统更新 ============
echo -e "${YELLOW}[1/8] 更新系统包...${NC}"
apt update -qq && apt upgrade -y -qq

# ============ 2. 安装依赖 ============
echo -e "${YELLOW}[2/8] 安装系统依赖...${NC}"
apt install -y -qq python3.11 python3.11-venv python3-pip nginx redis-server git curl

# 检查 PostgreSQL 版本（优先14，兼容已安装版本）
if ! command -v psql &> /dev/null; then
    echo "安装 PostgreSQL 14..."
    apt install -y -qq postgresql postgresql-client
fi

# ============ 3. 确保服务运行 ============
echo -e "${YELLOW}[3/8] 启动服务...${NC}"
systemctl enable --now redis-server
systemctl enable --now postgresql

# ============ 4. 创建目录结构 ============
echo -e "${YELLOW}[4/8] 创建目录结构...${NC}"
mkdir -p /srv/huiyuanyuan/uploads
mkdir -p /var/log/huiyuanyuan

# ============ 5. Python 虚拟环境 ============
echo -e "${YELLOW}[5/8] 配置 Python 环境...${NC}"
cd /srv/huiyuanyuan
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}Python 依赖安装完成${NC}"

# ============ 6. 生成 JWT 密钥并创建 .env ============
echo -e "${YELLOW}[6/8] 创建 .env 配置文件...${NC}"
JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")

if [ ! -f /srv/huiyuanyuan/.env ]; then
cat > /srv/huiyuanyuan/.env << EOF
DATABASE_URL=postgresql://huyy_user:YOUR_PASSWORD_HERE@localhost:5432/huiyuanyuan
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=${JWT_SECRET}
JWT_ALGORITHM=HS256
JWT_ACCESS_EXPIRE_MINUTES=120
JWT_REFRESH_EXPIRE_DAYS=7
ALIYUN_ACCESS_KEY_ID=
ALIYUN_ACCESS_KEY_SECRET=
SMS_SIGN_NAME=汇玉源
SMS_TEMPLATE_CODE=
APP_ENV=production
DEBUG=false
ALLOWED_ORIGINS=*
EOF
    echo ".env 文件已创建"
else
    echo ".env 文件已存在，跳过（不覆盖）"
fi

# ============ 7. Gunicorn systemd 服务 ============
echo -e "${YELLOW}[7/8] 配置 Gunicorn 服务...${NC}"
cat > /etc/systemd/system/huiyuanyuan.service << 'EOF'
[Unit]
Description=汇玉源 FastAPI 后端服务
After=network.target postgresql.service redis.service

[Service]
User=root
WorkingDirectory=/srv/huiyuanyuan
Environment="PATH=/srv/huiyuanyuan/venv/bin"
EnvironmentFile=/srv/huiyuanyuan/.env
ExecStart=/srv/huiyuanyuan/venv/bin/gunicorn main:app \
    -w 2 \
    -k uvicorn.workers.UvicornWorker \
    --bind 127.0.0.1:8000 \
    --access-logfile /var/log/huiyuanyuan/access.log \
    --error-logfile /var/log/huiyuanyuan/error.log \
    --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable huiyuanyuan

# ============ 8. Nginx 配置 ============
echo -e "${YELLOW}[8/8] 配置 Nginx...${NC}"
cat > /etc/nginx/sites-available/huiyuanyuan << 'EOF'
# 限流区域（在 http 块内）
# 按 IP 限制：每分钟最多 60 个请求（API接口）
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
# 短信接口额外限制：每分钟 5 次
limit_req_zone $binary_remote_addr zone=sms:10m rate=5r/m;

server {
    listen 80;
    server_name 47.112.98.191;  # 后续改为域名

    # 文件上传大小限制
    client_max_body_size 20M;

    # Gzip 压缩
    gzip on;
    gzip_types application/json text/plain;

    # API 代理
    location / {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 10s;
    }

    # 短信接口单独限流
    location /api/auth/send-sms {
        limit_req zone=sms burst=3 nodelay;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
    }

    # 上传文件静态服务
    location /uploads/ {
        alias /srv/huiyuanyuan/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 屏蔽 .env 等敏感文件
    location ~ /\. {
        deny all;
    }
}
EOF

# 启用站点（检查是否已链接，避免重复）
if [ ! -L /etc/nginx/sites-enabled/huiyuanyuan ]; then
    ln -s /etc/nginx/sites-available/huiyuanyuan /etc/nginx/sites-enabled/
fi
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm -f /etc/nginx/sites-enabled/default
fi

nginx -t && systemctl restart nginx
echo -e "${GREEN}Nginx 配置完成${NC}"

# ============ 启动服务 ============
echo -e "${YELLOW}启动应用服务...${NC}"
systemctl start huiyuanyuan

sleep 3
if systemctl is-active --quiet huiyuanyuan; then
    echo -e "${GREEN}? 服务启动成功！${NC}"
    echo ""
    echo -e "访问地址: http://47.112.98.191/api/health"
else
    echo -e "${RED}?? 服务启动失败，查看日志：journalctl -u huiyuanyuan -n 50${NC}"
fi

echo ""
echo -e "${GREEN}=== 初始化完成 ===${NC}"
echo "  API 地址:    http://47.112.98.191"
echo "  日志目录:    /var/log/huiyuanyuan/"
echo "  .env 配置:   /srv/huiyuanyuan/.env"
echo "  服务管理:    systemctl status huiyuanyuan"
