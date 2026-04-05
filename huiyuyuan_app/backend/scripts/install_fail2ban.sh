#!/usr/bin/env bash
set -euo pipefail

JAIL_LOCAL="/etc/fail2ban/jail.d/huiyuyuan.local"

if ! command -v fail2ban-client >/dev/null 2>&1; then
  yum install -y fail2ban
fi

mkdir -p /etc/fail2ban/jail.d

cat > "$JAIL_LOCAL" <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = auto
banaction = nftables-multiport
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = systemd
maxretry = 6
bantime = 24h

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/huiyuyuan_access.log
maxretry = 8
findtime = 10m
bantime = 2h

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/huiyuyuan_access.log
maxretry = 2
findtime = 10m
bantime = 12h
EOF

systemctl enable fail2ban
systemctl restart fail2ban
sleep 2
fail2ban-client ping
fail2ban-client status
