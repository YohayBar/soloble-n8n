#!/bin/bash

###############################################################################
# Enhanced n8n Backup Script with Oracle Object Storage Support
# Backs up to local disk AND optionally to Oracle Object Storage
###############################################################################

# ============================================================================
# CONFIGURATION - Edit these values
# ============================================================================

# Local backup settings
BACKUP_DIR="$HOME/n8n-backups"
N8N_DIR="$HOME/n8n-docker"
KEEP_DAYS_LOCAL=30  # Keep local backups for 30 days

# Oracle Object Storage settings (optional)
ENABLE_OBJECT_STORAGE="false"  # Set to "true" to enable Object Storage backups
OCI_BUCKET="n8n-backups"       # Your bucket name
OCI_NAMESPACE=""                # Leave empty to auto-detect, or specify manually
KEEP_DAYS_REMOTE=90            # Keep Object Storage backups for 90 days

# Encryption (optional)
ENABLE_ENCRYPTION="false"      # Set to "true" to encrypt backups
GPG_RECIPIENT=""               # Your GPG key email (if encryption enabled)

# ============================================================================
# DO NOT EDIT BELOW THIS LINE (unless you know what you're doing)
# ============================================================================

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/n8n-backup-$TIMESTAMP.tar.gz"
LOG_FILE="$HOME/backup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ $1${NC}" | tee -a "$LOG_FILE"
}

# ============================================================================
# Main Backup Process
# ============================================================================

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

# ============================================================================
# Step 1: Export PostgreSQL Database
# ============================================================================

log_info "Exporting PostgreSQL database..."
cd "$N8N_DIR"

POSTGRES_CONTAINER=$(docker compose ps -q postgres)

if [ -n "$POSTGRES_CONTAINER" ]; then
    mkdir -p "$N8N_DIR/temp_backup"

    # Export database
    docker compose exec -T postgres pg_dump -U n8n n8n > "$N8N_DIR/temp_backup/n8n_database.sql" 2>/dev/null

    if [ $? -eq 0 ]; then
        DB_SIZE=$(du -h "$N8N_DIR/temp_backup/n8n_database.sql" | cut -f1)
        log_success "Database exported successfully ($DB_SIZE)"
    else
        log_error "Database export failed"
        rm -rf "$N8N_DIR/temp_backup"
        exit 1
    fi
else
    log_warning "PostgreSQL container not found, skipping database export"
fi

# ============================================================================
# Step 2: Create Backup Archive
# ============================================================================

log_info "Creating backup archive..."

# Files and directories to backup
BACKUP_ITEMS="n8n_data postgres_data .env docker-compose.yml nginx/nginx.conf"

# Add database dump if it exists
if [ -d "temp_backup" ]; then
    BACKUP_ITEMS="$BACKUP_ITEMS temp_backup"
fi

# Create metadata file
cat > temp_backup/metadata.txt <<EOF
Backup Date: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)
n8n Version: $(docker compose exec -T n8n n8n --version 2>/dev/null || echo "unknown")
PostgreSQL Version: $(docker compose exec -T postgres psql -U n8n -c "SELECT version();" 2>/dev/null | head -3 | tail -1 || echo "unknown")
Backup Script Version: 2.0 (with Object Storage support)
EOF

# Create tarball
tar -czf "$BACKUP_FILE" $BACKUP_ITEMS 2>/dev/null

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_success "Backup archive created: $BACKUP_FILE ($BACKUP_SIZE)"
else
    log_error "Failed to create backup archive"
    rm -rf "$N8N_DIR/temp_backup"
    exit 1
fi

# Clean up temporary files
rm -rf "$N8N_DIR/temp_backup"

# ============================================================================
# Step 3: Encrypt Backup (Optional)
# ============================================================================

if [ "$ENABLE_ENCRYPTION" = "true" ]; then
    if command -v gpg &> /dev/null; then
        log_info "Encrypting backup..."

        if [ -n "$GPG_RECIPIENT" ]; then
            gpg --encrypt --recipient "$GPG_RECIPIENT" "$BACKUP_FILE"

            if [ $? -eq 0 ]; then
                rm "$BACKUP_FILE"  # Remove unencrypted version
                BACKUP_FILE="${BACKUP_FILE}.gpg"
                log_success "Backup encrypted successfully"
            else
                log_warning "Encryption failed, keeping unencrypted backup"
            fi
        else
            log_warning "GPG_RECIPIENT not set, skipping encryption"
        fi
    else
        log_warning "GPG not installed, skipping encryption"
    fi
fi

# ============================================================================
# Step 4: Upload to Object Storage (Optional)
# ============================================================================

if [ "$ENABLE_OBJECT_STORAGE" = "true" ]; then
    log_info "Uploading to Oracle Object Storage..."

    # Check if OCI CLI is installed
    if ! command -v oci &> /dev/null; then
        log_warning "OCI CLI not installed. Skipping Object Storage upload."
        log_info "Install with: bash -c \"\$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)\""
    else
        # Auto-detect namespace if not set
        if [ -z "$OCI_NAMESPACE" ]; then
            OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output 2>/dev/null)
            if [ -z "$OCI_NAMESPACE" ]; then
                log_error "Failed to auto-detect OCI namespace. Set it manually in the script."
            else
                log_info "Auto-detected namespace: $OCI_NAMESPACE"
            fi
        fi

        if [ -n "$OCI_NAMESPACE" ]; then
            # Upload to Object Storage
            OBJECT_NAME=$(basename "$BACKUP_FILE")

            oci os object put \
                --bucket-name "$OCI_BUCKET" \
                --namespace "$OCI_NAMESPACE" \
                --file "$BACKUP_FILE" \
                --name "$OBJECT_NAME" \
                --force 2>&1 | tee -a "$LOG_FILE"

            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                log_success "Backup uploaded to Object Storage: $OCI_BUCKET/$OBJECT_NAME"

                # Verify upload
                REMOTE_SIZE=$(oci os object head \
                    --bucket-name "$OCI_BUCKET" \
                    --namespace "$OCI_NAMESPACE" \
                    --name "$OBJECT_NAME" \
                    --query 'content-length' \
                    --raw-output 2>/dev/null)

                if [ -n "$REMOTE_SIZE" ]; then
                    REMOTE_SIZE_MB=$(echo "scale=2; $REMOTE_SIZE / 1048576" | bc)
                    log_info "Remote backup size: ${REMOTE_SIZE_MB} MB"
                fi
            else
                log_error "Failed to upload backup to Object Storage"
                log_warning "Backup is still available locally: $BACKUP_FILE"
            fi

            # ============================================================================
            # Step 5: Clean Old Remote Backups
            # ============================================================================

            if [ $KEEP_DAYS_REMOTE -gt 0 ]; then
                log_info "Cleaning old Object Storage backups (older than $KEEP_DAYS_REMOTE days)..."

                # Calculate cutoff date
                CUTOFF_DATE=$(date -d "$KEEP_DAYS_REMOTE days ago" '+%Y-%m-%d' 2>/dev/null || date -v-${KEEP_DAYS_REMOTE}d '+%Y-%m-%d')

                # List and delete old backups
                DELETED_REMOTE=0
                while IFS= read -r object; do
                    OBJECT_DATE=$(echo "$object" | grep -oP 'n8n-backup-\K\d{8}' || true)

                    if [ -n "$OBJECT_DATE" ]; then
                        OBJECT_DATE_FORMATTED="${OBJECT_DATE:0:4}-${OBJECT_DATE:4:2}-${OBJECT_DATE:6:2}"

                        if [[ "$OBJECT_DATE_FORMATTED" < "$CUTOFF_DATE" ]]; then
                            log_info "Deleting old remote backup: $object"
                            oci os object delete \
                                --bucket-name "$OCI_BUCKET" \
                                --namespace "$OCI_NAMESPACE" \
                                --name "$object" \
                                --force 2>/dev/null

                            if [ $? -eq 0 ]; then
                                ((DELETED_REMOTE++))
                            fi
                        fi
                    fi
                done < <(oci os object list \
                    --bucket-name "$OCI_BUCKET" \
                    --namespace "$OCI_NAMESPACE" \
                    --query 'data[].name' \
                    --raw-output 2>/dev/null | grep "n8n-backup-")

                if [ $DELETED_REMOTE -gt 0 ]; then
                    log_success "Deleted $DELETED_REMOTE old remote backup(s)"
                fi
            fi
        fi
    fi
fi

# ============================================================================
# Step 6: Clean Old Local Backups
# ============================================================================

log_info "Cleaning old local backups (older than $KEEP_DAYS_LOCAL days)..."
DELETED_LOCAL=$(find "$BACKUP_DIR" -name "n8n-backup-*.tar.gz*" -mtime +$KEEP_DAYS_LOCAL -delete -print | wc -l)

if [ "$DELETED_LOCAL" -gt 0 ]; then
    log_success "Deleted $DELETED_LOCAL old local backup(s)"
else
    log_info "No old local backups to delete"
fi

# ============================================================================
# Step 7: Backup Statistics
# ============================================================================

TOTAL_LOCAL=$(find "$BACKUP_DIR" -name "n8n-backup-*.tar.gz*" | wc -l)
TOTAL_SIZE_LOCAL=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)

log "=========================================="
log "Backup completed successfully"
log "=========================================="
log_info "Latest backup: $BACKUP_FILE"
log_info "Backup size: $BACKUP_SIZE"
log_info "Total local backups: $TOTAL_LOCAL"
log_info "Total local storage: $TOTAL_SIZE_LOCAL"

# Count remote backups if Object Storage is enabled
if [ "$ENABLE_OBJECT_STORAGE" = "true" ] && command -v oci &> /dev/null && [ -n "$OCI_NAMESPACE" ]; then
    TOTAL_REMOTE=$(oci os object list \
        --bucket-name "$OCI_BUCKET" \
        --namespace "$OCI_NAMESPACE" \
        --query 'data[].name' \
        --raw-output 2>/dev/null | grep -c "n8n-backup-" || echo "0")

    log_info "Total Object Storage backups: $TOTAL_REMOTE"
fi

log "=========================================="

# ============================================================================
# Optional: Send Notification (Uncomment to enable)
# ============================================================================

# Example: Discord webhook
# if [ -n "$DISCORD_WEBHOOK" ]; then
#     curl -X POST -H 'Content-type: application/json' \
#         --data "{\"content\":\"✅ n8n backup completed: $BACKUP_FILE ($BACKUP_SIZE)\"}" \
#         "$DISCORD_WEBHOOK"
# fi

# Example: Slack webhook
# if [ -n "$SLACK_WEBHOOK" ]; then
#     curl -X POST -H 'Content-type: application/json' \
#         --data "{\"text\":\"✅ n8n backup completed: $BACKUP_FILE ($BACKUP_SIZE)\"}" \
#         "$SLACK_WEBHOOK"
# fi

# Example: Email (requires mailutils or sendmail)
# if [ -n "$BACKUP_EMAIL" ]; then
#     echo "Backup completed: $BACKUP_FILE ($BACKUP_SIZE)" | \
#         mail -s "n8n Backup Success" "$BACKUP_EMAIL"
# fi

exit 0
