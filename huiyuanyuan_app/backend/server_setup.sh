#!/bin/bash
# ============================================================
# 汇玉源 v4.0 — 服务器一键初始化脚本 (生产级)
# 运行: bash /srv/huiyuanyuan/server_setup.sh
# 服务器: Ubuntu 22.04 LTS @ 47.112.98.191
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

APP_NAME="huiyuanyuan"
APP_DIR="/srv/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
BACKUP_DIR="/opt/${APP_NAME}/backups"
WEB_DIR="/var/www/${APP_NAME}"
UPLOAD_DIR="${APP_DIR}/uploads"
VENV_DIR="${APP_DIR}/venv"
DB_NAME="huiyuanyuan"
DB_USER="huyy_user"

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }

# ============================================================
# 预检
# ============================================================
if [ "$(id -u)" -ne 0 ]; then
    log_error "请使用 root 用户运行此脚本"
    exit 1
fi

log_step "1/10 系统更新"
apt update -qq
apt upgrade -y -qq
log_info "系统已更新"

# ============================================================
# 2. 安装基础依赖
# ============================================================
log_step "2/10 安装系统依赖"
apt install -y -qq \
    python3.11 python3.11-venv python3-pip \
    nginx \
    redis-server \
    git curl wget unzip \
    htop iotop \
    logrotate \
    ufw \
    jq

log_info "系统依赖安装完成"

# ============================================================
# 3. PostgreSQL 15 安装
# ============================================================
log_step "3/10 安装 PostgreSQL"

if ! command -v psql &>/dev/null; then
    # 添加 PostgreSQL 官方源以获取 v15
    if [ ! -f /etc/apt/sources.list.d/pgdg.list ]; then
        apt install -y -qq gnupg2 lsb-release
        curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
        apt update -qq
    fi
    apt install -y -qq postgresql-15 postgresql-client-15 postgresql-contrib-15
    log_info "PostgreSQL 15 安装完成"
else
    PG_VER=$(psql --version | grep -oP '\d+\.\d+')
    log_info "PostgreSQL 已安装 (v${PG_VER})"
fi

# 确保 PostgreSQL 运行
systemctl enable --now postgresql
log_info "PostgreSQL 服务已启动"

# ============================================================
# 4. 配置 PostgreSQL
# ============================================================
log_step "4/10 配置 PostgreSQL 数据库"

# 生成强密码
DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(24))")

# 检查用户和数据库是否已存在
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1; then
    log_warn "数据库用户 ${DB_USER} 已存在，跳过创建"
    log_warn "如需重置密码，请手动执行: sudo -u postgres psql -c \"ALTER USER ${DB_USER} PASSWORD 'new_password';\""
else
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
    log_info "数据库用户 ${DB_USER} 已创建"
fi

if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
    log_warn "数据库 ${DB_NAME} 已存在，跳过创建"
else
    sudo -u postgres createdb -O ${DB_USER} ${DB_NAME}
    log_info "数据库 ${DB_NAME} 已创建"
fi

# 授权
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
sudo -u postgres psql -d ${DB_NAME} -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"

# 安全配置: 仅允许本地连接
PG_CONF_DIR=$(sudo -u postgres psql -tAc "SHOW config_file" | xargs dirname)

if ! grep -q "${DB_USER}" "${PG_CONF_DIR}/pg_hba.conf" 2>/dev/null; then
    echo "# 汇玉源应用连接" >> "${PG_CONF_DIR}/pg_hba.conf"
    echo "local   ${DB_NAME}   ${DB_USER}   scram-sha-256" >> "${PG_CONF_DIR}/pg_hba.conf"
    echo "host    ${DB_NAME}   ${DB_USER}   127.0.0.1/32   scram-sha-256" >> "${PG_CONF_DIR}/pg_hba.conf"
    systemctl reload postgresql
    log_info "pg_hba.conf 已更新"
fi

# PostgreSQL 性能调优 (2GB 内存服务器)
PG_CUSTOM="${PG_CONF_DIR}/conf.d/huiyuanyuan.conf"
mkdir -p "${PG_CONF_DIR}/conf.d"

if [ ! -f "${PG_CUSTOM}" ]; then
    cat > "${PG_CUSTOM}" << 'EOF'
# 汇玉源 PostgreSQL 调优 (2GB RAM)
shared_buffers = 512MB
effective_cache_size = 1GB
work_mem = 8MB
maintenance_work_mem = 128MB
max_connections = 100
log_min_duration_statement = 1000   # 慢查询 >= 1s 记录
log_statement = 'ddl'
timezone = 'Asia/Shanghai'
EOF
    # 确保 conf.d 被包含
    if ! grep -q "include_dir = 'conf.d'" "${PG_CONF_DIR}/postgresql.conf" 2>/dev/null; then
        echo "include_dir = 'conf.d'" >> "${PG_CONF_DIR}/postgresql.conf"
    fi
    systemctl restart postgresql
    log_info "PostgreSQL 性能配置已应用"
fi

log_info "PostgreSQL 配置完成"

# ============================================================
# 5. Redis 配置
# ============================================================
log_step "5/10 配置 Redis"

systemctl enable --now redis-server

REDIS_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")

# Redis 安全加固
REDIS_CONF="/etc/redis/redis.conf"
if [ -f "${REDIS_CONF}" ]; then
    # 仅绑定 localhost
    sed -i 's/^bind .*/bind 127.0.0.1 ::1/' "${REDIS_CONF}"
    
    # 设置密码 (仅首次)
    if ! grep -q "^requirepass" "${REDIS_CONF}"; then
        echo "requirepass ${REDIS_PASSWORD}" >> "${REDIS_CONF}"
        log_info "Redis 密码已设置"
    else
        REDIS_PASSWORD="(已存在，未修改)"
        log_warn "Redis 密码已存在，跳过"
    fi
    
    # 禁用危险命令
    if ! grep -q "rename-command FLUSHALL" "${REDIS_CONF}"; then
        cat >> "${REDIS_CONF}" << 'EOF'

# 安全: 禁用危险命令
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command DEBUG ""
rename-command CONFIG ""

# 内存限制 (256MB)
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF
    fi
    
    systemctl restart redis-server
    log_info "Redis 安全配置完成"
fi

# ============================================================
# 6. 创建目录结构
# ============================================================
log_step "6/10 创建目录结构"

mkdir -p "${APP_DIR}"
mkdir -p "${LOG_DIR}"
mkdir -p "${BACKUP_DIR}"
mkdir -p "${WEB_DIR}"
mkdir -p "${UPLOAD_DIR}"
mkdir -p "${APP_DIR}/scripts"

log_info "目录结构: ${APP_DIR}, ${LOG_DIR}, ${BACKUP_DIR}"

# ============================================================
# 7. Python 虚拟环境 + 依赖
# ============================================================
log_step "7/10 配置 Python 环境"

cd "${APP_DIR}"

if [ ! -d "${VENV_DIR}" ]; then
    python3.11 -m venv "${VENV_DIR}"
    log_info "Python 虚拟环境已创建"
fi

source "${VENV_DIR}/bin/activate"
pip install --upgrade pip -q

if [ -f "${APP_DIR}/requirements.txt" ]; then
    pip install -r "${APP_DIR}/requirements.txt" -q
    log_info "Python 依赖安装完成"
else
    log_warn "requirements.txt 不存在，跳过依赖安装"
fi

# ============================================================
# 8. 生成 .env 配置
# ============================================================
log_step "8/10 生成 .env 配置"

JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")

if [ ! -f "${APP_DIR}/.env" ]; then
    cat > "${APP_DIR}/.env" << EOF
# ============ 汇玉源 v4.0 生产环境配置 ============
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# !! 此文件包含敏感信息，不要提交到 Git !!

# ── 数据库 (PostgreSQL) ──
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}

# ── 缓存 (Redis) ──
REDIS_URL=redis://:${REDIS_PASSWORD}@localhost:6379/0

# ── JWT 认证 ──
JWT_SECRET_KEY=${JWT_SECRET}
JWT_ALGORITHM=HS256
JWT_ACCESS_EXPIRE_MINUTES=120
JWT_REFRESH_EXPIRE_DAYS=7

# ── 阿里云短信 ──
ALIYUN_ACCESS_KEY_ID=
ALIYUN_ACCESS_KEY_SECRET=
SMS_SIGN_NAME=汇玉源
SMS_TEMPLATE_CODE=

# ── 阿里云 OSS ──
OSS_ACCESS_KEY_ID=
OSS_ACCESS_KEY_SECRET=
OSS_BUCKET=huiyuanyuan-images
OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
OSS_REGION=cn-hangzhou

# ── AI 服务 ──
OPENROUTER_API_KEY=
OPENROUTER_MODEL=nvidia/nemotron-nano-12b-v2-vl:free
OPENROUTER_SITE_URL=https://huiyuanyuan.local
OPENROUTER_APP_NAME=汇玉源

# ── 应用配置 ──
APP_ENV=production
DEBUG=false
ALLOWED_ORIGINS=http://47.112.98.191
LOG_LEVEL=INFO
EOF
    chmod 600 "${APP_DIR}/.env"
    log_info ".env 文件已生成 (权限 600)"
    log_warn "请手动编辑 ${APP_DIR}/.env 填入阿里云/AI 密钥"
else
    log_warn ".env 已存在，不覆盖。请手动检查配置"
fi

# ============================================================
# 9. 初始化数据库表
# ============================================================
log_step "9/10 初始化数据库"

if [ -f "${APP_DIR}/init_db.sql" ]; then
    sudo -u postgres psql -d ${DB_NAME} -f "${APP_DIR}/init_db.sql" 2>&1 | tail -5
    log_info "数据库表初始化完成"
else
    log_warn "init_db.sql 不存在，跳过数据库初始化"
fi

# ============================================================
# 10. systemd + Nginx + 防火墙
# ============================================================
log_step "10/10 配置系统服务"

# --- systemd 服务 ---
cat > /etc/systemd/system/huiyuanyuan.service << 'EOF'
[Unit]
Description=汇玉源 FastAPI 后端服务 v4.0
After=network.target postgresql.service redis-server.service
Requires=postgresql.service
Wants=redis-server.service

[Service]
Type=notify
User=root
Group=root
WorkingDirectory=/srv/huiyuanyuan
Environment="PATH=/srv/huiyuanyuan/venv/bin:/usr/local/bin:/usr/bin"
EnvironmentFile=/srv/huiyuanyuan/.env

ExecStart=/srv/huiyuanyuan/venv/bin/gunicorn main:app \
    -w 2 \
    -k uvicorn.workers.UvicornWorker \
    --bind 127.0.0.1:8000 \
    --access-logfile /var/log/huiyuanyuan/access.log \
    --error-logfile /var/log/huiyuanyuan/error.log \
    --timeout 120 \
    --graceful-timeout 30 \
    --max-requests 1000 \
    --max-requests-jitter 100

ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

Restart=on-failure
RestartSec=5
StartLimitBurst=5
StartLimitIntervalSec=60

# 安全加固
ProtectSystem=strict
ReadWritePaths=/srv/huiyuanyuan /var/log/huiyuanyuan
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable huiyuanyuan
log_info "systemd 服务已配置"

# --- Nginx ---
cp "${APP_DIR}/nginx_production.conf" /etc/nginx/sites-available/huiyuanyuan 2>/dev/null || \
    cp "${APP_DIR}/nginx.conf" /etc/nginx/sites-available/huiyuanyuan 2>/dev/null || \
    log_warn "未找到 Nginx 配置文件，请手动配置"

if [ -L /etc/nginx/sites-enabled/huiyuanyuan ] || [ -f /etc/nginx/sites-enabled/huiyuanyuan ]; then
    rm -f /etc/nginx/sites-enabled/huiyuanyuan
fi
ln -s /etc/nginx/sites-available/huiyuanyuan /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl restart nginx
log_info "Nginx 配置完成"

# --- UFW 防火墙 ---
if command -v ufw &>/dev/null; then
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw --force enable
    log_info "UFW 防火墙已启用 (22, 80, 443)"
fi

# --- 日志轮转 ---
cat > /etc/logrotate.d/huiyuanyuan << 'EOF'
/var/log/huiyuanyuan/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
    postrotate
        systemctl reload huiyuanyuan > /dev/null 2>&1 || true
    endscript
}
EOF
log_info "日志轮转配置完成 (保留14天)"

# ============================================================
# 安装备份和监控脚本
# ============================================================
if [ -f "${APP_DIR}/scripts/db_backup.sh" ]; then
    cp "${APP_DIR}/scripts/db_backup.sh" /opt/${APP_NAME}/backup.sh
    chmod +x /opt/${APP_NAME}/backup.sh
    
    # 添加 crontab
    CRON_ENTRY="0 3 * * * /opt/${APP_NAME}/backup.sh >> /var/log/${APP_NAME}/backup.log 2>&1"
    (crontab -l 2>/dev/null | grep -v 'backup.sh'; echo "${CRON_ENTRY}") | crontab -
    log_info "数据库备份 cron 已配置 (每天 3:00)"
fi

if [ -f "${APP_DIR}/scripts/health_monitor.sh" ]; then
    cp "${APP_DIR}/scripts/health_monitor.sh" /opt/${APP_NAME}/health_monitor.sh
    chmod +x /opt/${APP_NAME}/health_monitor.sh
    
    CRON_MONITOR="*/5 * * * * /opt/${APP_NAME}/health_monitor.sh >> /var/log/${APP_NAME}/monitor.log 2>&1"
    (crontab -l 2>/dev/null | grep -v 'health_monitor.sh'; echo "${CRON_MONITOR}") | crontab -
    log_info "健康监控 cron 已配置 (每5分钟)"
fi

# ============================================================
# 启动服务
# ============================================================
log_step "启动应用服务"

systemctl start huiyuanyuan

sleep 3
if systemctl is-active --quiet huiyuanyuan; then
    log_info "服务启动成功！"
    HEALTH=$(curl -s http://127.0.0.1:8000/api/health 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "N/A")
    echo -e "${GREEN}${HEALTH}${NC}"
else
    log_error "服务启动失败，查看日志: journalctl -u huiyuanyuan -n 50"
fi

# ============================================================
# 输出摘要
# ============================================================
echo ""
echo -e "${CYAN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  汇玉源 v4.0 服务器初始化完成！${NC}"
echo -e "${CYAN}════════════════════════════════════════════${NC}"
echo ""
echo -e "  应用目录:     ${APP_DIR}"
echo -e "  Web 目录:     ${WEB_DIR}"
echo -e "  日志目录:     ${LOG_DIR}"
echo -e "  备份目录:     ${BACKUP_DIR}"
echo -e "  .env 文件:    ${APP_DIR}/.env"
echo ""
echo -e "  PostgreSQL 用户: ${DB_USER}"
echo -e "  PostgreSQL 密码: ${DB_PASSWORD}"
echo -e "  Redis 密码:      ${REDIS_PASSWORD}"
echo ""
echo -e "${YELLOW}  !! 请立即记录上述密码，并填写 .env 中的阿里云/AI 密钥 !!${NC}"
echo ""
echo -e "  常用命令:"
echo -e "    systemctl status huiyuanyuan     # 服务状态"
echo -e "    journalctl -u huiyuanyuan -f     # 实时日志"
echo -e "    psql -U ${DB_USER} -d ${DB_NAME} # 连接数据库"
echo -e "    redis-cli -a <password>          # 连接 Redis"
echo -e "    curl http://127.0.0.1:8000/api/health  # 健康检查"
echo ""
