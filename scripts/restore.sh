#!/bin/bash

###############################################################################
# n8n Restore Script
# Restores n8n from a backup archive
###############################################################################

# Configuration
BACKUP_DIR="$HOME/n8n-backups"
N8N_DIR="$HOME/n8n-docker"
RESTORE_DIR="$N8N_DIR/restore_temp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Header
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  n8n Restore Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    print_error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# List available backups
echo "Available backups:"
echo ""
BACKUPS=($(find "$BACKUP_DIR" -name "n8n-backup-*.tar.gz" -type f | sort -r))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    print_error "No backup files found in $BACKUP_DIR"
    exit 1
fi

# Display backups
for i in "${!BACKUPS[@]}"; do
    BACKUP_FILE="${BACKUPS[$i]}"
    BACKUP_NAME=$(basename "$BACKUP_FILE")
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    BACKUP_DATE=$(stat -c %y "$BACKUP_FILE" | cut -d' ' -f1,2 | cut -d'.' -f1)
    echo "[$i] $BACKUP_NAME"
    echo "    Size: $BACKUP_SIZE | Date: $BACKUP_DATE"
    echo ""
done

# Select backup
read -p "Enter backup number to restore (or 'q' to quit): " SELECTION

if [ "$SELECTION" = "q" ]; then
    print_info "Restore cancelled"
    exit 0
fi

# Validate selection
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -ge "${#BACKUPS[@]}" ]; then
    print_error "Invalid selection"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$SELECTION]}"
print_info "Selected: $(basename $SELECTED_BACKUP)"

# Confirm restore
echo ""
print_warning "⚠️  WARNING: This will REPLACE your current n8n installation!"
print_warning "⚠️  All current data will be backed up before restore."
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Restore cancelled"
    exit 0
fi

# Create backup of current state
echo ""
print_info "Creating backup of current state..."
CURRENT_BACKUP="$BACKUP_DIR/n8n-backup-before-restore-$(date +%Y%m%d-%H%M%S).tar.gz"

if [ -d "$N8N_DIR" ]; then
    cd "$N8N_DIR"
    tar -czf "$CURRENT_BACKUP" n8n_data postgres_data .env docker-compose.yml nginx/nginx.conf 2>/dev/null
    print_success "Current state backed up to: $(basename $CURRENT_BACKUP)"
fi

# Stop n8n services
echo ""
print_info "Stopping n8n services..."
cd "$N8N_DIR"

if docker compose ps | grep -q "Up"; then
    docker compose down
    print_success "Services stopped"
else
    print_info "Services were not running"
fi

# Create temporary restore directory
rm -rf "$RESTORE_DIR"
mkdir -p "$RESTORE_DIR"

# Extract backup
echo ""
print_info "Extracting backup..."
tar -xzf "$SELECTED_BACKUP" -C "$RESTORE_DIR"

if [ $? -ne 0 ]; then
    print_error "Failed to extract backup"
    exit 1
fi

print_success "Backup extracted"

# Restore files
echo ""
print_info "Restoring files..."

# Backup current data (just in case)
[ -d "$N8N_DIR/n8n_data" ] && mv "$N8N_DIR/n8n_data" "$N8N_DIR/n8n_data.old"
[ -d "$N8N_DIR/postgres_data" ] && mv "$N8N_DIR/postgres_data" "$N8N_DIR/postgres_data.old"

# Restore data directories
cp -r "$RESTORE_DIR/n8n_data" "$N8N_DIR/"
cp -r "$RESTORE_DIR/postgres_data" "$N8N_DIR/"

# Restore configuration files
[ -f "$RESTORE_DIR/.env" ] && cp "$RESTORE_DIR/.env" "$N8N_DIR/"
[ -f "$RESTORE_DIR/docker-compose.yml" ] && cp "$RESTORE_DIR/docker-compose.yml" "$N8N_DIR/"
[ -f "$RESTORE_DIR/nginx/nginx.conf" ] && cp "$RESTORE_DIR/nginx/nginx.conf" "$N8N_DIR/nginx/"

print_success "Files restored"

# Restore database if SQL dump exists
if [ -f "$RESTORE_DIR/temp_backup/n8n_database.sql" ]; then
    echo ""
    print_info "Restoring database..."

    # Start only PostgreSQL
    cd "$N8N_DIR"
    docker compose up -d postgres

    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to start..."
    sleep 10

    # Restore database
    cat "$RESTORE_DIR/temp_backup/n8n_database.sql" | docker compose exec -T postgres psql -U n8n -d n8n

    if [ $? -eq 0 ]; then
        print_success "Database restored"
    else
        print_error "Database restore failed"
        print_warning "You may need to restore manually"
    fi
fi

# Clean up
echo ""
print_info "Cleaning up temporary files..."
rm -rf "$RESTORE_DIR"
print_success "Cleanup complete"

# Start services
echo ""
print_info "Starting n8n services..."
cd "$N8N_DIR"
docker compose up -d

# Wait a moment
sleep 5

# Check status
if docker compose ps | grep -q "Up"; then
    print_success "Services started successfully"
else
    print_error "Services failed to start. Check logs with: docker compose logs"
    exit 1
fi

# Final message
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
print_success "Restore completed successfully!"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
print_info "n8n should now be accessible at your configured domain"
print_info "Check status with: cd $N8N_DIR && docker compose ps"
print_info "View logs with: cd $N8N_DIR && docker compose logs -f"
echo ""
print_warning "Old data backed up to:"
echo "  - $N8N_DIR/n8n_data.old"
echo "  - $N8N_DIR/postgres_data.old"
echo "  - $CURRENT_BACKUP"
echo ""
print_info "You can safely delete these after verifying the restore"
echo ""

exit 0
