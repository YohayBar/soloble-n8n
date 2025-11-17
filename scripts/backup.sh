#!/bin/bash

###############################################################################
# n8n Backup Script
# Automatically backs up n8n data, PostgreSQL database, and configurations
###############################################################################

# Configuration
BACKUP_DIR="$HOME/n8n-backups"
N8N_DIR="$HOME/n8n-docker"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/n8n-backup-$TIMESTAMP.tar.gz"
LOG_FILE="$HOME/backup.log"
KEEP_DAYS=30  # Keep backups for 30 days

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}" | tee -a "$LOG_FILE"
}

# Start backup
log "=========================================="
log "Starting n8n backup process"
log "=========================================="

# Check if n8n directory exists
if [ ! -d "$N8N_DIR" ]; then
    log_error "n8n directory not found: $N8N_DIR"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running"
    exit 1
fi

# Check if n8n containers are running
cd "$N8N_DIR"
if ! docker compose ps | grep -q "Up"; then
    log_warning "n8n containers are not running"
fi

# Export PostgreSQL database
log "Exporting PostgreSQL database..."
POSTGRES_CONTAINER=$(docker compose ps -q postgres)

if [ -n "$POSTGRES_CONTAINER" ]; then
    mkdir -p "$N8N_DIR/temp_backup"

    # Get database password from .env file
    if [ -f "$N8N_DIR/.env" ]; then
        source "$N8N_DIR/.env"
    fi

    # Export database
    docker compose exec -T postgres pg_dump -U n8n n8n > "$N8N_DIR/temp_backup/n8n_database.sql" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "Database exported successfully"
    else
        log_error "Database export failed"
        rm -rf "$N8N_DIR/temp_backup"
        exit 1
    fi
else
    log_warning "PostgreSQL container not found, skipping database export"
fi

# Create backup archive
log "Creating backup archive..."

cd "$N8N_DIR"

# Files and directories to backup
BACKUP_ITEMS="n8n_data postgres_data .env docker-compose.yml nginx/nginx.conf"

# Add database dump if it exists
if [ -d "temp_backup" ]; then
    BACKUP_ITEMS="$BACKUP_ITEMS temp_backup"
fi

# Create tarball
tar -czf "$BACKUP_FILE" $BACKUP_ITEMS 2>/dev/null

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_success "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    log_error "Failed to create backup archive"
    rm -rf "$N8N_DIR/temp_backup"
    exit 1
fi

# Clean up temporary files
rm -rf "$N8N_DIR/temp_backup"

# Remove old backups
log "Cleaning up old backups (older than $KEEP_DAYS days)..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "n8n-backup-*.tar.gz" -mtime +$KEEP_DAYS -delete -print | wc -l)

if [ "$DELETED_COUNT" -gt 0 ]; then
    log_success "Deleted $DELETED_COUNT old backup(s)"
else
    log "No old backups to delete"
fi

# Backup statistics
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "n8n-backup-*.tar.gz" | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log "=========================================="
log "Backup completed successfully"
log "Total backups: $TOTAL_BACKUPS"
log "Total size: $TOTAL_SIZE"
log "Latest backup: $BACKUP_FILE"
log "=========================================="

# Optional: Send notification (uncomment if needed)
# You can integrate with Discord, Slack, email, etc.
# Example webhook notification:
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"n8n backup completed: $BACKUP_FILE\"}" \
#   YOUR_WEBHOOK_URL

exit 0
