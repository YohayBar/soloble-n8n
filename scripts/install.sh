#!/bin/bash

###############################################################################
# n8n Installation Script for Oracle Cloud Always Free Tier
# This script automates the setup of n8n on Ubuntu
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

print_header "n8n Installation Script for Oracle Cloud"

# Step 1: Update System
print_header "Step 1: Updating System"
print_info "Updating package list..."
sudo apt update

print_info "Upgrading packages (this may take a few minutes)..."
sudo apt upgrade -y

print_info "Installing essential tools..."
sudo apt install -y curl wget git nano ufw

print_success "System updated successfully"

# Step 2: Configure Firewall
print_header "Step 2: Configuring Firewall"

print_info "Setting up UFW firewall rules..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable

print_success "Firewall configured successfully"
sudo ufw status

# Step 3: Install Docker
print_header "Step 3: Installing Docker"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    print_warning "Docker is already installed"
    docker --version
else
    print_info "Installing Docker..."

    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install dependencies
    sudo apt install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER

    # Enable Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    print_success "Docker installed successfully"
    docker --version
fi

# Step 4: Create Project Directory
print_header "Step 4: Setting Up Project Directory"

INSTALL_DIR="$HOME/n8n-docker"

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists"
    read -p "Do you want to continue? This will overwrite configuration files. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
else
    print_info "Creating directory $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Create subdirectories
mkdir -p n8n_data postgres_data letsencrypt nginx

print_success "Project directory created"

# Step 5: Download Configuration Files
print_header "Step 5: Downloading Configuration Files"

# Clone or copy files
if [ -d "/tmp/soloble-n8n" ]; then
    rm -rf /tmp/soloble-n8n
fi

print_info "Cloning repository..."
git clone https://github.com/YohayBar/soloble-n8n.git /tmp/soloble-n8n

print_info "Copying configuration files..."
cp /tmp/soloble-n8n/docker-compose.yml "$INSTALL_DIR/"
cp /tmp/soloble-n8n/.env.example "$INSTALL_DIR/.env"
cp /tmp/soloble-n8n/nginx/nginx.conf "$INSTALL_DIR/nginx/"

print_success "Configuration files downloaded"

# Step 6: Configure Environment
print_header "Step 6: Configuring Environment Variables"

print_warning "You need to edit the .env file with your settings"
print_info "File location: $INSTALL_DIR/.env"
echo ""
print_info "Required settings:"
echo "  - DOMAIN_NAME: Your domain (e.g., n8n.yourdomain.com)"
echo "  - N8N_BASIC_AUTH_USER: Your n8n username"
echo "  - N8N_BASIC_AUTH_PASSWORD: Your n8n password (use a strong password!)"
echo "  - POSTGRES_PASSWORD: Database password (use a strong password!)"
echo "  - GENERIC_TIMEZONE: Your timezone (e.g., America/New_York)"
echo ""

read -p "Do you want to edit the .env file now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nano "$INSTALL_DIR/.env"
else
    print_warning "Remember to edit $INSTALL_DIR/.env before starting n8n!"
fi

# Step 7: Install Certbot
print_header "Step 7: Installing Certbot (for SSL)"

if command -v certbot &> /dev/null; then
    print_warning "Certbot is already installed"
else
    print_info "Installing Certbot..."
    sudo apt install -y certbot python3-certbot-nginx
    print_success "Certbot installed"
fi

# Step 8: Create Systemd Service
print_header "Step 8: Creating Auto-start Service"

print_info "Creating systemd service..."

sudo tee /etc/systemd/system/n8n-docker.service > /dev/null <<EOF
[Unit]
Description=n8n Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable n8n-docker.service

print_success "Auto-start service created"

# Step 9: Create Backup Script
print_header "Step 9: Setting Up Backup Script"

BACKUP_SCRIPT="$HOME/backup-n8n.sh"

print_info "Creating backup script at $BACKUP_SCRIPT..."

tee "$BACKUP_SCRIPT" > /dev/null <<'EOF'
#!/bin/bash
# n8n Backup Script

BACKUP_DIR="$HOME/n8n-backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/n8n-backup-$TIMESTAMP.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Stop n8n (optional - comment out if you want live backup)
# cd ~/n8n-docker && docker compose stop n8n

# Create backup
cd ~/n8n-docker
tar -czf "$BACKUP_FILE" \
    n8n_data \
    postgres_data \
    .env \
    docker-compose.yml \
    nginx/nginx.conf

# Restart n8n (if stopped)
# docker compose start n8n

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup created: $BACKUP_FILE"
EOF

chmod +x "$BACKUP_SCRIPT"

print_success "Backup script created"

# Optional: Setup cron job
read -p "Do you want to schedule daily backups at 2 AM? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    (crontab -l 2>/dev/null; echo "0 2 * * * $BACKUP_SCRIPT >> $HOME/backup.log 2>&1") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * * find $HOME/n8n-backups -name '*.tar.gz' -mtime +30 -delete") | crontab -
    print_success "Automatic backups scheduled"
fi

# Final Instructions
print_header "Installation Complete!"

echo ""
print_success "n8n installation files are ready!"
echo ""
print_info "Next steps:"
echo ""
echo "1. Configure your domain DNS:"
echo "   - Create an A record pointing to your VM's public IP"
echo "   - Wait 5-30 minutes for DNS propagation"
echo ""
echo "2. Edit configuration file:"
echo "   nano $INSTALL_DIR/.env"
echo ""
echo "3. Update Nginx configuration with your domain:"
echo "   nano $INSTALL_DIR/nginx/nginx.conf"
echo ""
echo "4. Start n8n:"
echo "   cd $INSTALL_DIR"
echo "   docker compose up -d"
echo ""
echo "5. Obtain SSL certificate:"
echo "   sudo certbot certonly --standalone -d yourdomain.com --email your@email.com"
echo "   (Stop nginx first: docker compose stop nginx)"
echo ""
echo "6. Enable SSL in Nginx:"
echo "   nano $INSTALL_DIR/nginx/nginx.conf"
echo "   (Uncomment the HTTPS server section and update domain)"
echo ""
echo "7. Restart services:"
echo "   cd $INSTALL_DIR"
echo "   docker compose up -d"
echo ""
print_info "Full guide: $INSTALL_DIR/../DEPLOYMENT_GUIDE.md"
echo ""
print_warning "IMPORTANT: You may need to log out and back in for Docker permissions to take effect"
echo ""
print_success "Happy automating with n8n! 🚀"
echo ""
