#!/bin/bash
# HuiYuYuan database auto backup script
# Run by cron daily at 3:00 AM
# Retains last 7 days of backups

set -euo pipefail

BACKUP_DIR="/opt/huiyuyuan/backups"
DB_NAME="huiyuyuan"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/huiyuyuan_${TIMESTAMP}.dump.gz"
LOG_FILE="/opt/huiyuyuan/logs/db_backup.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "=== Starting backup ==="

# Use postgres user for pg_dump (peer auth, no password needed)
if sudo -u postgres pg_dump -d "$DB_NAME" -Fc --compress=9 2>>"$LOG_FILE" | gzip > "$BACKUP_FILE"; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "OK Backup done: ${BACKUP_FILE} (${FILE_SIZE})"
else
    log "FAIL Backup failed"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Clean old backups
DELETED=$(find "$BACKUP_DIR" -name "huiyuyuan_*.dump.gz" -mtime +${RETENTION_DAYS} -delete -print 2>/dev/null | wc -l)
if [ "$DELETED" -gt 0 ]; then
    log "Cleaned ${DELETED} expired backups"
fi

# Count current backups
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/huiyuyuan_*.dump.gz 2>/dev/null | wc -l)
log "Keeping ${BACKUP_COUNT} backups"
log "=== Backup ended ==="
