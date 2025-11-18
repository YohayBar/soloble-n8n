#!/bin/bash

###############################################################################
# Database Setup Script
# Initializes PostgreSQL database with user and email processing schema
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  n8n Database Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Configuration
N8N_DIR="$HOME/n8n-docker"
SCHEMA_FILE="$(dirname "$0")/schema.sql"

# Check if n8n is running
cd "$N8N_DIR" 2>/dev/null || {
    print_error "n8n directory not found: $N8N_DIR"
    print_info "Please run this script after installing n8n"
    exit 1
}

# Check if schema file exists
if [ ! -f "$SCHEMA_FILE" ]; then
    print_error "Schema file not found: $SCHEMA_FILE"
    exit 1
fi

# Check if Docker is running
if ! docker compose ps | grep -q "postgres.*Up"; then
    print_warning "PostgreSQL container is not running"
    read -p "Start n8n services now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose up -d
        print_info "Waiting for PostgreSQL to start..."
        sleep 10
    else
        print_error "Cannot proceed without running PostgreSQL"
        exit 1
    fi
fi

# Verify PostgreSQL is ready
print_info "Checking PostgreSQL connection..."
if docker compose exec -T postgres pg_isready -U n8n > /dev/null 2>&1; then
    print_success "PostgreSQL is ready"
else
    print_error "PostgreSQL is not responding"
    print_info "Try: cd $N8N_DIR && docker compose restart postgres"
    exit 1
fi

# Show current database info
print_info "Current database status:"
echo ""
docker compose exec -T postgres psql -U n8n -d n8n -c "\dt" 2>/dev/null || print_warning "No tables found yet"
echo ""

# Confirm setup
print_warning "This will create tables: users, incoming_emails, email_attachments, ai_processing_queue"
read -p "Continue with database setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Setup cancelled"
    exit 0
fi

# Apply schema
print_info "Applying database schema..."
cat "$SCHEMA_FILE" | docker compose exec -T postgres psql -U n8n -d n8n

if [ $? -eq 0 ]; then
    print_success "Database schema created successfully!"
else
    print_error "Failed to create database schema"
    exit 1
fi

# Verify tables were created
print_info "Verifying tables..."
echo ""
docker compose exec -T postgres psql -U n8n -d n8n -c "\dt"
echo ""

# Show table counts
print_info "Table statistics:"
docker compose exec -T postgres psql -U n8n -d n8n -c "
    SELECT
        'users' as table_name, COUNT(*) as row_count FROM users
    UNION ALL
    SELECT 'incoming_emails', COUNT(*) FROM incoming_emails
    UNION ALL
    SELECT 'email_attachments', COUNT(*) FROM email_attachments
    UNION ALL
    SELECT 'ai_processing_queue', COUNT(*) FROM ai_processing_queue;
"

# Optional: Insert sample data
echo ""
read -p "Insert sample test data? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Inserting sample data..."

    docker compose exec -T postgres psql -U n8n -d n8n <<EOF
-- Sample users
INSERT INTO users (name, email, phone, company, role) VALUES
    ('John Doe', 'john@example.com', '+1-555-0100', 'Acme Corp', 'Manager'),
    ('Jane Smith', 'jane@example.com', '+1-555-0101', 'Tech Inc', 'Developer'),
    ('Bob Johnson', 'bob@example.com', '+1-555-0102', 'StartupXYZ', 'Founder');

-- Sample emails
INSERT INTO incoming_emails (user_id, from_email, from_name, to_email, subject, body_text, category) VALUES
    (1, 'support@service.com', 'Support Team', 'john@example.com',
     'Welcome to our service!', 'Thanks for signing up with us. We are excited to have you!', 'welcome'),
    (2, 'billing@service.com', 'Billing Department', 'jane@example.com',
     'Invoice #12345', 'Your invoice is ready for download.', 'billing'),
    (1, 'newsletter@service.com', 'Newsletter', 'john@example.com',
     'This Month in Tech', 'Check out the latest technology trends...', 'newsletter');
EOF

    if [ $? -eq 0 ]; then
        print_success "Sample data inserted!"

        # Show sample data
        echo ""
        print_info "Sample users:"
        docker compose exec -T postgres psql -U n8n -d n8n -c "SELECT id, name, email, phone FROM users;"

        echo ""
        print_info "Sample emails:"
        docker compose exec -T postgres psql -U n8n -d n8n -c "SELECT id, from_email, subject, category FROM incoming_emails;"
    else
        print_warning "Failed to insert sample data (may already exist)"
    fi
fi

# Success message
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
print_success "Database setup complete!"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

print_info "Database is ready for use with n8n workflows!"
echo ""
print_info "Useful commands:"
echo "  # Connect to database:"
echo "  cd $N8N_DIR && docker compose exec postgres psql -U n8n -d n8n"
echo ""
echo "  # View all users:"
echo "  SELECT * FROM users;"
echo ""
echo "  # View all emails:"
echo "  SELECT * FROM incoming_emails;"
echo ""
echo "  # View unprocessed emails:"
echo "  SELECT * FROM incoming_emails WHERE processed = FALSE;"
echo ""

print_info "Next steps:"
echo "  1. Create n8n workflows to receive emails"
echo "  2. Store email data in PostgreSQL"
echo "  3. Trigger AI processing"
echo "  4. Store AI results back to database"
echo ""

exit 0
