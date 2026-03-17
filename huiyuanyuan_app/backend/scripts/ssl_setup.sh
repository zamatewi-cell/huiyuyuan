#!/bin/bash
# ============================================================
# 汇玉源 — SSL 证书配置脚本 (Let's Encrypt)
# 用法: bash ssl_setup.sh <域名>
# 示例: bash ssl_setup.sh huiyuanyuan.com
# 前提: 域名已解析到 47.112.98.191 且 80 端口可访问
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

DOMAIN="${1:-}"

if [ -z "${DOMAIN}" ]; then
    echo "用法: bash ssl_setup.sh <域名>"
    echo "示例: bash ssl_setup.sh huiyuanyuan.com"
    echo ""
    echo "前提条件:"
    echo "  1. 域名 A 记录已指向 47.112.98.191"
    echo "  2. 80 端口对外开放"
    echo "  3. Nginx 正在运行"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    log_error "请使用 root 用户运行"
    exit 1
fi

# ── 安装 certbot ──
log_info "安装 certbot..."
apt install -y -qq certbot python3-certbot-nginx

# ── DNS 验证 ──
log_info "验证域名解析..."
RESOLVED_IP=$(dig +short "${DOMAIN}" 2>/dev/null | head -1)
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")

if [ "${RESOLVED_IP}" != "${SERVER_IP}" ]; then
    log_warn "域名 ${DOMAIN} 解析到 ${RESOLVED_IP}，本机 IP 为 ${SERVER_IP}"
    log_warn "如果通过 CDN 或代理，可忽略此警告"
    read -p "继续？(y/N): " CONFIRM
    if [ "${CONFIRM}" != "y" ] && [ "${CONFIRM}" != "Y" ]; then
        exit 0
    fi
fi

# ── 更新 Nginx server_name ──
log_info "更新 Nginx server_name..."
NGINX_CONF="/etc/nginx/sites-available/huiyuanyuan"

if [ -f "${NGINX_CONF}" ]; then
    # 替换 server_name
    sed -i "s/server_name .*$/server_name ${DOMAIN} www.${DOMAIN};/" "${NGINX_CONF}"
    nginx -t
    systemctl reload nginx
    log_info "Nginx server_name 已更新为 ${DOMAIN}"
fi

# ── 申请证书 ──
log_info "申请 Let's Encrypt 证书..."
certbot --nginx \
    -d "${DOMAIN}" \
    -d "www.${DOMAIN}" \
    --non-interactive \
    --agree-tos \
    --email "admin@${DOMAIN}" \
    --redirect

# ── 验证证书 ──
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    log_info "SSL 证书申请成功！"
    
    EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" | cut -d= -f2)
    log_info "证书有效期至: ${EXPIRY}"
else
    log_error "证书申请失败，请检查域名解析和防火墙"
    exit 1
fi

# ── 启用自动续期 ──
log_info "配置自动续期..."
systemctl enable --now certbot.timer

# 验证续期命令
certbot renew --dry-run 2>&1 | tail -3

# ── 更新 Nginx 配置启用完整 SSL ──
log_info "强化 SSL 配置..."

# 添加 HSTS 头
if ! grep -q "Strict-Transport-Security" "${NGINX_CONF}"; then
    sed -i '/add_header X-Frame-Options/a\    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;' "${NGINX_CONF}"
fi

nginx -t && systemctl reload nginx

# ── 更新 .env ALLOWED_ORIGINS ──
ENV_FILE="/srv/huiyuanyuan/.env"
if [ -f "${ENV_FILE}" ]; then
    sed -i "s|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=https://${DOMAIN},https://www.${DOMAIN}|" "${ENV_FILE}"
    systemctl restart huiyuanyuan
    log_info ".env ALLOWED_ORIGINS 已更新为 HTTPS 域名"
fi

# ── 完成 ──
echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  SSL 配置完成！${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "  HTTPS:  https://${DOMAIN}"
echo "  证书:   /etc/letsencrypt/live/${DOMAIN}/"
echo "  续期:   certbot.timer 自动 (每12小时检查)"
echo "  测试:   curl -I https://${DOMAIN}/api/health"
echo ""
echo "  安全检测: https://www.ssllabs.com/ssltest/analyze.html?d=${DOMAIN}"
echo ""
