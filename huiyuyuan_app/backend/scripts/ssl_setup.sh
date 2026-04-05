#!/usr/bin/env bash
# ============================================================
# HuiYuYuan SSL bootstrap for the current production layout.
# Usage:
#   bash ssl_setup.sh <domain>
# Example:
#   bash ssl_setup.sh xn--lsws2cdzg.top
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

APP_ROOT="/srv/huiyuyuan"
BACKEND_DIR="${APP_ROOT}/backend"
ENV_FILE="${APP_ROOT}/.env"
NGINX_CONF="/etc/nginx/conf.d/huiyuyuan.conf"
NGINX_SNIPPET="/etc/nginx/snippets/proxy_params.conf"
ACME_ROOT="/var/www/certbot"
SERVICE_NAME="huiyuyuan-backend"
BACKEND_PORT="8000"

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat <<'EOF'
Usage:
  bash ssl_setup.sh <domain>

Examples:
  bash ssl_setup.sh xn--lsws2cdzg.top
  bash ssl_setup.sh your-domain.example

Optional:
  export SSL_CONTACT_EMAIL=ops@example.com
EOF
}

normalize_domain() {
    local domain="$1"
    domain="${domain#http://}"
    domain="${domain#https://}"
    domain="${domain%%/*}"
    domain="${domain,,}"
    domain="${domain#www.}"
    printf '%s' "${domain}"
}

to_ascii_domain() {
    python3 - "$1" <<'PY'
import sys

domain = sys.argv[1].strip().lower()
print(domain.encode("idna").decode("ascii"))
PY
}

ensure_command() {
    local command_name="$1"
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        log_error "Missing required command: ${command_name}"
        exit 1
    fi
}

write_proxy_snippet() {
    mkdir -p /etc/nginx/snippets
    if [[ -f "${BACKEND_DIR}/nginx_proxy_params.conf" ]]; then
        cp "${BACKEND_DIR}/nginx_proxy_params.conf" "${NGINX_SNIPPET}"
        return
    fi

    cat > "${NGINX_SNIPPET}" <<'EOF'
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_http_version 1.1;
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
EOF
}

write_http_bootstrap_conf() {
    cat > "${NGINX_CONF}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${PRIMARY_DOMAIN_ASCII} ${WWW_DOMAIN_ASCII};

    location /.well-known/acme-challenge/ {
        root ${ACME_ROOT};
        try_files \$uri =404;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF
}

write_https_conf() {
    cat > "${NGINX_CONF}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${PRIMARY_DOMAIN_ASCII} ${WWW_DOMAIN_ASCII};

    location /.well-known/acme-challenge/ {
        root ${ACME_ROOT};
        try_files \$uri =404;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${PRIMARY_DOMAIN_ASCII} ${WWW_DOMAIN_ASCII};

    ssl_certificate /etc/letsencrypt/live/${PRIMARY_DOMAIN_ASCII}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${PRIMARY_DOMAIN_ASCII}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    client_max_body_size 20m;

    location /api/ {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        include ${NGINX_SNIPPET};
    }

    location /uploads/ {
        alias ${BACKEND_DIR}/uploads/;
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
    }

    location / {
        root /var/www/huiyuyuan;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    log_error "Please run this script as root."
    exit 1
fi

ensure_command python3
ensure_command nginx
ensure_command systemctl

PRIMARY_DOMAIN_RAW="$(normalize_domain "$1")"
PRIMARY_DOMAIN_ASCII="$(to_ascii_domain "${PRIMARY_DOMAIN_RAW}")"
WWW_DOMAIN_ASCII="www.${PRIMARY_DOMAIN_ASCII}"
CONTACT_EMAIL="${SSL_CONTACT_EMAIL:-admin@${PRIMARY_DOMAIN_ASCII}}"

log_info "Primary domain: ${PRIMARY_DOMAIN_ASCII}"
log_info "WWW domain: ${WWW_DOMAIN_ASCII}"
log_info "Contact email: ${CONTACT_EMAIL}"

log_info "Installing SSL dependencies..."
apt-get update -qq
apt-get install -y -qq certbot curl dnsutils

log_info "Checking DNS resolution..."
RESOLVED_IP="$(dig +short "${PRIMARY_DOMAIN_ASCII}" 2>/dev/null | head -1 || true)"
SERVER_IP="$(curl -fsS https://ifconfig.me/ip 2>/dev/null || echo "unknown")"
if [[ -n "${RESOLVED_IP}" && "${SERVER_IP}" != "unknown" && "${RESOLVED_IP}" != "${SERVER_IP}" ]]; then
    log_warn "Domain resolves to ${RESOLVED_IP}, but the current server public IP is ${SERVER_IP}."
    log_warn "If you are behind a CDN or DNS has not fully propagated yet, continue with caution."
    read -r -p "Continue anyway? (y/N): " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        exit 0
    fi
fi

mkdir -p "${ACME_ROOT}"
mkdir -p /etc/nginx/conf.d

if [[ -f "${NGINX_CONF}" ]]; then
    cp "${NGINX_CONF}" "${NGINX_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
fi

log_info "Writing temporary HTTP bootstrap config..."
write_http_bootstrap_conf
nginx -t
systemctl reload nginx

log_info "Requesting Let's Encrypt certificate with webroot challenge..."
certbot certonly \
    --webroot \
    -w "${ACME_ROOT}" \
    -d "${PRIMARY_DOMAIN_ASCII}" \
    -d "${WWW_DOMAIN_ASCII}" \
    --non-interactive \
    --agree-tos \
    --email "${CONTACT_EMAIL}" \
    --keep-until-expiring

if [[ ! -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN_ASCII}/fullchain.pem" ]]; then
    log_error "Certificate request failed."
    exit 1
fi

log_info "Writing final HTTPS Nginx config..."
write_proxy_snippet
write_https_conf
nginx -t
systemctl reload nginx

log_info "Enabling automatic renewal..."
systemctl enable --now certbot.timer
certbot renew --dry-run 2>&1 | tail -3

ALLOWED_ORIGINS="https://${PRIMARY_DOMAIN_ASCII},https://${WWW_DOMAIN_ASCII}"
if [[ -f "${ENV_FILE}" ]]; then
    log_info "Updating ${ENV_FILE} ALLOWED_ORIGINS..."
    if grep -q '^ALLOWED_ORIGINS=' "${ENV_FILE}"; then
        sed -i "s|^ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=${ALLOWED_ORIGINS}|" "${ENV_FILE}"
    else
        printf '\nALLOWED_ORIGINS=%s\n' "${ALLOWED_ORIGINS}" >> "${ENV_FILE}"
    fi
    chmod 600 "${ENV_FILE}"
fi

if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
    log_info "Restarting ${SERVICE_NAME}..."
    systemctl restart "${SERVICE_NAME}"
fi

log_info "Certificate expiry:"
openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${PRIMARY_DOMAIN_ASCII}/fullchain.pem"

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}SSL setup completed for ${PRIMARY_DOMAIN_ASCII}${NC}"
echo -e "${GREEN}============================================================${NC}"
echo "Nginx config: ${NGINX_CONF}"
echo "Env file:     ${ENV_FILE}"
echo "Service:      ${SERVICE_NAME}"
echo "Health URL:   https://${PRIMARY_DOMAIN_ASCII}/api/health"
echo ""
