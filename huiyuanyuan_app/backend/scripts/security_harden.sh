#!/bin/bash
# ============================================================
# HuiYuYuan - Security Hardening Script
# Applies baseline security measures to Ubuntu 22.04 ECS
#
# Features:
#   1. fail2ban (SSH + Nginx brute-force protection)
#   2. unattended-upgrades (automatic security patches)
#   3. SSH hardening (disable root password, idle timeout)
#   4. sysctl network hardening (SYN cookies, ICMP, etc.)
#   5. Audit summary
#
# Usage:
#   sudo bash /opt/huiyuanyuan/scripts/security_harden.sh [--check-only]
# ============================================================

set -euo pipefail

# Color helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
header(){ echo -e "\n${CYAN}=== $1 ===${NC}"; }

CHECK_ONLY=false
[[ "${1:-}" == "--check-only" ]] && CHECK_ONLY=true

[[ $EUID -eq 0 ]] || { fail "Must run as root (sudo)"; exit 1; }

SCORE=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    if eval "$1" >/dev/null 2>&1; then
        info "$2"
        SCORE=$((SCORE + 1))
        return 0
    else
        warn "$2 - NOT configured"
        return 1
    fi
}

# ============================================================
# 1. fail2ban
# ============================================================
header "1. fail2ban (brute-force protection)"

if ! check "dpkg -l fail2ban 2>/dev/null | grep -q '^ii'" "fail2ban installed"; then
    if $CHECK_ONLY; then
        warn "Would install fail2ban"
    else
        apt-get update -qq && apt-get install -y -qq fail2ban
        info "fail2ban installed"
        SCORE=$((SCORE + 1))
    fi
fi

JAIL_LOCAL="/etc/fail2ban/jail.local"
if ! check "test -f $JAIL_LOCAL" "fail2ban jail.local configured"; then
    if $CHECK_ONLY; then
        warn "Would create $JAIL_LOCAL"
    else
        cat > "$JAIL_LOCAL" << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
banaction = ufw

[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 7200

[nginx-http-auth]
enabled  = true
port     = http,https
filter   = nginx-http-auth
logpath  = /var/log/nginx/error.log
maxretry = 5

[nginx-limit-req]
enabled  = true
port     = http,https
filter   = nginx-limit-req
logpath  = /var/log/nginx/error.log
maxretry = 10
findtime = 60
bantime  = 600
EOF
        systemctl enable fail2ban
        systemctl restart fail2ban
        info "fail2ban configured and started"
        SCORE=$((SCORE + 1))
    fi
fi

# ============================================================
# 2. unattended-upgrades
# ============================================================
header "2. Automatic security updates"

if ! check "dpkg -l unattended-upgrades 2>/dev/null | grep -q '^ii'" "unattended-upgrades installed"; then
    if $CHECK_ONLY; then
        warn "Would install unattended-upgrades"
    else
        apt-get install -y -qq unattended-upgrades
        info "unattended-upgrades installed"
        SCORE=$((SCORE + 1))
    fi
fi

AUTO_CONF="/etc/apt/apt.conf.d/20auto-upgrades"
if ! check "grep -q 'APT::Periodic::Unattended-Upgrade' $AUTO_CONF 2>/dev/null" "auto-upgrades enabled"; then
    if $CHECK_ONLY; then
        warn "Would enable auto-upgrades"
    else
        cat > "$AUTO_CONF" << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
        info "Auto-upgrades enabled (daily check, weekly clean)"
        SCORE=$((SCORE + 1))
    fi
fi

# ============================================================
# 3. SSH hardening
# ============================================================
header "3. SSH hardening"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Disable password auth for root (key-only)
if ! check "grep -qE '^PermitRootLogin\s+(prohibit-password|without-password|no)' $SSHD_CONFIG" "Root password login disabled"; then
    if $CHECK_ONLY; then
        warn "Would set PermitRootLogin prohibit-password"
    else
        sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
        info "PermitRootLogin set to prohibit-password"
        SCORE=$((SCORE + 1))
    fi
fi

# Set idle timeout (10 min)
if ! check "grep -q '^ClientAliveInterval' $SSHD_CONFIG" "SSH idle timeout configured"; then
    if $CHECK_ONLY; then
        warn "Would set ClientAliveInterval 600"
    else
        echo -e "\n# HuiYuYuan: SSH idle timeout\nClientAliveInterval 600\nClientAliveCountMax 2" >> "$SSHD_CONFIG"
        info "SSH idle timeout set to 10 min"
        SCORE=$((SCORE + 1))
    fi
fi

# Max auth tries
if ! check "grep -qE '^MaxAuthTries\s+[1-4]$' $SSHD_CONFIG" "MaxAuthTries <= 4"; then
    if $CHECK_ONLY; then
        warn "Would set MaxAuthTries 4"
    else
        sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 4/' "$SSHD_CONFIG"
        info "MaxAuthTries set to 4"
        SCORE=$((SCORE + 1))
    fi
fi

if ! $CHECK_ONLY; then
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    info "SSHD configuration reloaded"
fi

# ============================================================
# 4. sysctl network hardening
# ============================================================
header "4. Kernel network hardening"

SYSCTL_CONF="/etc/sysctl.d/99-huiyuanyuan-security.conf"
if ! check "test -f $SYSCTL_CONF" "sysctl hardening config exists"; then
    if $CHECK_ONLY; then
        warn "Would create $SYSCTL_CONF"
    else
        cat > "$SYSCTL_CONF" << 'EOF'
# HuiYuYuan security hardening

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Ignore source-routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore broadcast ICMP
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Protect against time-wait assassination
net.ipv4.tcp_rfc1337 = 1
EOF
        sysctl --system >/dev/null 2>&1
        info "Kernel network hardening applied"
        SCORE=$((SCORE + 1))
    fi
fi

# ============================================================
# 5. Additional checks
# ============================================================
header "5. Additional security checks"

check "command -v ufw >/dev/null && ufw status | grep -q 'Status: active'" "UFW firewall active"
check "test -f /etc/logrotate.d/huiyuanyuan" "Logrotate configured for app"
check "systemctl is-active fail2ban >/dev/null 2>&1" "fail2ban service running"

# Check for open ports (should only be 22, 80, 443)
OPEN_PORTS=$(ss -tlnp | grep LISTEN | awk '{print $4}' | grep -oE '[0-9]+$' | sort -n | uniq | tr '\n' ',')
echo -e "  Listening ports: ${OPEN_PORTS%,}"

# ============================================================
# Summary
# ============================================================
header "Security Audit Summary"
echo -e "  Score: ${GREEN}${SCORE}/${TOTAL}${NC} checks passed"

if [[ $SCORE -eq $TOTAL ]]; then
    echo -e "  ${GREEN}All security measures are in place!${NC}"
elif [[ $SCORE -ge $((TOTAL * 7 / 10)) ]]; then
    echo -e "  ${YELLOW}Good baseline, some items need attention.${NC}"
else
    echo -e "  ${RED}Multiple security gaps detected.${NC}"
fi

if $CHECK_ONLY; then
    echo -e "\n  Run without --check-only to apply fixes automatically."
fi

echo ""
echo "Useful commands:"
echo "  fail2ban-client status sshd          # View SSH bans"
echo "  fail2ban-client status nginx-limit-req  # View Nginx bans"
echo "  unattended-upgrades --dry-run        # Preview pending updates"
echo "  sudo bash $0 --check-only            # Re-audit without changes"
