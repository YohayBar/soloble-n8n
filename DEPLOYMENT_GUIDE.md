# Complete Guide: Deploy n8n on Oracle Cloud Always Free Tier

This guide will walk you through deploying n8n (workflow automation tool) on Oracle Cloud's Always Free tier VM - completely free, forever!

## 📋 What You'll Get

- **n8n** workflow automation platform
- **PostgreSQL** database for workflow storage
- **Nginx** reverse proxy with SSL/HTTPS
- **Automatic backups**
- **Auto-restart on reboot**
- **~24GB RAM, 4 ARM cores** (Always Free!)

---

## 🎯 Prerequisites

- [ ] Email address for Oracle Cloud account
- [ ] Credit card (for verification - **won't be charged**)
- [ ] Government-issued ID (for account verification)
- [ ] Domain name (optional, but recommended - $1-15/year)
- [ ] 2-3 hours of time

---

## Step 1: Create Oracle Cloud Account

### 1.1 Sign Up

1. Go to https://www.oracle.com/cloud/free/
2. Click **"Start for free"**
3. Fill out the form:
   - **Country/Territory**: Your location
   - **Name and Email**: Your details
   - **Verify email**: Check inbox and click verification link

### 1.2 Account Verification

1. **Provide address** and phone number
2. **Add payment method**: Credit/debit card
   - ⚠️ **Important**: Oracle charges $1 for verification (refunded)
   - They will NOT charge you for Always Free resources
3. **Identity verification**: Upload government ID
   - Driver's license, passport, or national ID
   - This may take a few minutes to verify

### 1.3 Wait for Approval

- Usually takes **5-30 minutes**
- You'll receive an email when approved
- Sometimes can take up to 24 hours

---

## Step 2: Create a Virtual Machine

### 2.1 Access Cloud Console

1. Log in to https://cloud.oracle.com/
2. Click **"Create a VM instance"** or navigate to:
   - Menu (☰) → **Compute** → **Instances**
3. Click **"Create Instance"**

### 2.2 Configure VM Instance

**Name:**
```
n8n-production
```

**Placement:**
- Leave as default (usually AD-1)

**Image and Shape:**

1. Click **"Change Image"**
   - Select **"Canonical Ubuntu"** (22.04 or 24.04)
   - Click **"Select Image"**

2. Click **"Change Shape"**
   - Click **"Ampere"** (ARM-based)
   - Select **"VM.Standard.A1.Flex"**
   - Set **OCPUs: 2** (or up to 4)
   - Set **Memory: 12 GB** (or up to 24 GB)
   - ✅ Shows "Always Free-eligible"
   - Click **"Select Shape"**

**Networking:**
- Leave default VCN and subnet
- Make sure **"Assign a public IPv4 address"** is checked

**Add SSH Keys:**

Choose one option:

**Option A: Auto-generate (Easiest)**
1. Select **"Generate a key pair for me"**
2. Click **"Save Private Key"** → saves as `*.key` file
3. Click **"Save Public Key"** (optional)
4. ⚠️ **IMPORTANT**: Store this file safely! You can't download it again

**Option B: Use Your Own SSH Key**
1. Select **"Upload public key files"**
2. Upload your existing `id_rsa.pub` or similar

**Boot Volume:**
- Set to **200 GB** (maximum for Always Free)
- Leave other options as default

### 2.3 Create the Instance

1. Click **"Create"**
2. Wait 1-2 minutes for provisioning
3. Status will change from "Provisioning" → "Running"
4. **Note down the Public IP address** (you'll need this!)

---

## Step 3: Configure Firewall Rules

### 3.1 Open Ports in Oracle Cloud

1. On your instance page, click your **VCN name** (usually "vcn-...")
2. Click **"Security Lists"** → Click your security list
3. Click **"Add Ingress Rules"**

**Add these rules one by one:**

**Rule 1: HTTP**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `80`
- Description: `HTTP`
- Click **"Add Ingress Rules"**

**Rule 2: HTTPS**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `443`
- Description: `HTTPS`
- Click **"Add Ingress Rules"**

### 3.2 Configure Ubuntu Firewall

We'll do this in the next step when we connect to the VM.

---

## Step 4: Connect to Your VM

### 4.1 Prepare SSH Key (Windows Users)

If you're on Windows and downloaded a `.key` file:

**Using Git Bash or WSL:**
```bash
# Move key to .ssh folder
mv ~/Downloads/ssh-key-*.key ~/.ssh/oracle_key
chmod 600 ~/.ssh/oracle_key
```

**Using PuTTY:**
1. Download PuTTYgen
2. Load your `.key` file
3. Save as `.ppk` format
4. Use in PuTTY

### 4.2 Connect via SSH

Replace `YOUR_PUBLIC_IP` with your VM's public IP:

**Linux/Mac/Git Bash:**
```bash
ssh -i ~/.ssh/oracle_key ubuntu@YOUR_PUBLIC_IP
```

**Using default key:**
```bash
ssh ubuntu@YOUR_PUBLIC_IP
```

**First time connecting:**
- Type `yes` when asked about fingerprint

### 4.3 Verify Connection

You should see Ubuntu welcome message. Run:
```bash
uname -a
# Should show: Linux ... aarch64 (ARM64)

free -h
# Should show ~12-24GB RAM
```

---

## Step 5: Initial Server Setup

### 5.1 Update System

```bash
# Update package list
sudo apt update

# Upgrade packages (takes 5-10 minutes)
sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git nano ufw
```

### 5.2 Configure Firewall

```bash
# Allow SSH (don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status
```

Should show:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                     ALLOW       Anywhere
```

---

## Step 6: Install Docker

### 6.1 Install Docker Engine

```bash
# Remove old versions (if any)
sudo apt remove docker docker-engine docker.io containerd runc

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

# Verify installation
docker --version
```

### 6.2 Configure Docker

```bash
# Add your user to docker group
sudo usermod -aG docker ubuntu

# Enable Docker to start on boot
sudo systemctl enable docker

# Start Docker
sudo systemctl start docker

# Log out and back in for group changes to take effect
exit
```

**Reconnect to your VM:**
```bash
ssh -i ~/.ssh/oracle_key ubuntu@YOUR_PUBLIC_IP
```

**Test Docker:**
```bash
docker run hello-world
```

---

## Step 7: Set Up Domain (Optional but Recommended)

### 7.1 Why You Need a Domain

- Required for SSL/HTTPS (secure connection)
- Professional looking: `n8n.yourdomain.com` instead of `123.456.789.0`
- Free SSL certificates with Let's Encrypt
- Better for email automation (some servers reject IP addresses)

### 7.2 Purchase Domain

**Cheap registrars:**
- Namecheap: ~$8-15/year
- Porkbun: ~$5-10/year
- Cloudflare: ~$8-10/year (at cost pricing)
- Google Domains (now Squarespace): ~$12/year

**Recommendation**: Get something like:
- `yourname.com` or `yourproject.com`
- Then use subdomain: `n8n.yourname.com`

### 7.3 Configure DNS

In your domain registrar's DNS settings:

**If using subdomain (recommended):**
```
Type: A Record
Name: n8n
Value: YOUR_VM_PUBLIC_IP
TTL: 300 (or automatic)
```

**If using main domain:**
```
Type: A Record
Name: @
Value: YOUR_VM_PUBLIC_IP
TTL: 300
```

**Wait 5-30 minutes** for DNS propagation.

**Test DNS:**
```bash
# On your local computer
ping n8n.yourdomain.com

# Should respond with your VM's IP
```

---

## Step 8: Deploy n8n with Docker Compose

### 8.1 Create Project Directory

```bash
# Create directory
mkdir -p ~/n8n-docker
cd ~/n8n-docker

# Create data directories
mkdir -p n8n_data
mkdir -p postgres_data
mkdir -p letsencrypt
mkdir -p nginx
```

### 8.2 Create Docker Compose File

Download the configuration from this repository:

```bash
# Clone this repository
cd ~
git clone https://github.com/YohayBar/soloble-n8n.git
cd soloble-n8n

# Copy files to deployment directory
cp docker-compose.yml ~/n8n-docker/
cp .env.example ~/n8n-docker/.env
cp nginx/nginx.conf ~/n8n-docker/nginx/
```

Or create manually:

```bash
cd ~/n8n-docker
nano docker-compose.yml
```

Paste the content from `docker-compose.yml` in this repository.

### 8.3 Configure Environment Variables

```bash
nano .env
```

**Replace these values:**

```bash
# Basic Configuration
DOMAIN_NAME=n8n.yourdomain.com    # Your domain
SUBDOMAIN=n8n                      # Subdomain (or leave empty for root)
GENERIC_TIMEZONE=America/New_York  # Your timezone

# Security - CHANGE THESE!
N8N_BASIC_AUTH_USER=admin          # Your n8n login username
N8N_BASIC_AUTH_PASSWORD=ChangeMeToSecurePassword123!  # Strong password

# PostgreSQL - CHANGE THIS!
POSTGRES_PASSWORD=AnotherSecurePassword456!  # Database password

# Email (Optional - for notifications)
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-app-password
N8N_SMTP_SENDER=your-email@gmail.com
```

**Get your timezone:**
```bash
timedatectl | grep "Time zone"
# Or use: ls /usr/share/zoneinfo/
```

**Save file**: `Ctrl + X`, then `Y`, then `Enter`

### 8.4 Configure Nginx

The Nginx configuration is already provided in `nginx/nginx.conf`. Just update your domain:

```bash
nano nginx/nginx.conf
```

Replace `n8n.yourdomain.com` with your actual domain.

---

## Step 9: Launch n8n

### 9.1 Start Services

```bash
cd ~/n8n-docker

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

**Press `Ctrl + C` to stop viewing logs**

### 9.2 Verify Services

```bash
# Check if containers are running
docker ps

# Should show 4 containers:
# - n8n
# - postgres
# - nginx
# - certbot (might be stopped - that's okay)
```

### 9.3 Test Without SSL (First Time)

If you don't have a domain yet:

```bash
# Access via IP
http://YOUR_PUBLIC_IP
```

If you have a domain:

```bash
# Access via domain
http://n8n.yourdomain.com
```

**You should see n8n login page!**

---

## Step 10: Set Up SSL Certificate (HTTPS)

### 10.1 Install Certbot

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx

# Stop nginx temporarily
cd ~/n8n-docker
docker compose stop nginx
```

### 10.2 Obtain Certificate

```bash
# Request certificate
sudo certbot certonly --standalone -d n8n.yourdomain.com --email your-email@example.com --agree-tos --non-interactive

# Certificate will be saved to:
# /etc/letsencrypt/live/n8n.yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/n8n.yourdomain.com/privkey.pem
```

### 10.3 Update Nginx Configuration

```bash
nano ~/n8n-docker/nginx/nginx.conf
```

Uncomment the SSL section (remove `#` from SSL lines).

### 10.4 Update Docker Compose for SSL

```bash
nano ~/n8n-docker/docker-compose.yml
```

Make sure the nginx service has these volumes:
```yaml
volumes:
  - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  - /etc/letsencrypt:/etc/letsencrypt:ro
```

### 10.5 Restart Services

```bash
cd ~/n8n-docker
docker compose up -d

# Check logs
docker compose logs nginx
```

### 10.6 Set Up Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Create renewal hook
sudo nano /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
```

Add:
```bash
#!/bin/bash
cd /home/ubuntu/n8n-docker
docker compose restart nginx
```

```bash
# Make executable
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
```

Certbot will automatically renew certificates (cron job is installed automatically).

---

## Step 11: Access n8n

### 11.1 Open n8n

Go to: `https://n8n.yourdomain.com`

**Login with:**
- Username: (what you set in `.env`)
- Password: (what you set in `.env`)

### 11.2 Initial Setup

1. **Create owner account**: Set email and password
2. **Setup personalization**: Optional survey
3. **Explore templates**: Check out pre-built workflows

---

## Step 12: Configure Auto-Start on Reboot

### 12.1 Create Systemd Service

```bash
sudo nano /etc/systemd/system/n8n-docker.service
```

Paste:
```ini
[Unit]
Description=n8n Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/n8n-docker
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=ubuntu

[Install]
WantedBy=multi-user.target
```

### 12.2 Enable Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable n8n-docker.service

# Check status
sudo systemctl status n8n-docker.service
```

### 12.3 Test Reboot

```bash
# Reboot VM
sudo reboot
```

Wait 1-2 minutes, then check if n8n is running:
```bash
# Reconnect
ssh -i ~/.ssh/oracle_key ubuntu@YOUR_PUBLIC_IP

# Check containers
docker ps
```

All containers should be running automatically!

---

## Step 13: Set Up Backups

### 13.1 Create Backup Script

```bash
cd ~
git clone https://github.com/YohayBar/soloble-n8n.git
cp soloble-n8n/scripts/backup.sh ~/backup-n8n.sh
chmod +x ~/backup-n8n.sh
```

Or create manually:
```bash
nano ~/backup-n8n.sh
```

Paste the backup script from `scripts/backup.sh` in this repository.

### 13.2 Test Backup

```bash
~/backup-n8n.sh
```

Should create: `/home/ubuntu/n8n-backups/n8n-backup-YYYYMMDD-HHMMSS.tar.gz`

### 13.3 Schedule Automatic Backups

```bash
# Edit crontab
crontab -e

# Choose nano (option 1)
```

Add these lines:
```bash
# Backup n8n every day at 2 AM
0 2 * * * /home/ubuntu/backup-n8n.sh >> /home/ubuntu/backup.log 2>&1

# Delete backups older than 30 days
0 3 * * * find /home/ubuntu/n8n-backups -name "*.tar.gz" -mtime +30 -delete
```

Save and exit.

---

## Step 14: Monitoring and Maintenance

### 14.1 Useful Commands

**View logs:**
```bash
cd ~/n8n-docker

# All logs
docker compose logs -f

# Specific service
docker compose logs -f n8n
docker compose logs -f postgres
docker compose logs -f nginx
```

**Restart services:**
```bash
cd ~/n8n-docker

# Restart all
docker compose restart

# Restart specific service
docker compose restart n8n
```

**Stop services:**
```bash
cd ~/n8n-docker
docker compose down
```

**Start services:**
```bash
cd ~/n8n-docker
docker compose up -d
```

### 14.2 Check Resource Usage

```bash
# CPU and memory
htop
# Press 'q' to quit

# Disk usage
df -h

# Docker disk usage
docker system df
```

### 14.3 Update n8n

```bash
cd ~/n8n-docker

# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Remove old images
docker image prune -a
```

### 14.4 Keep Oracle from Reclaiming Your VM

Oracle may reclaim idle Always Free VMs. To prevent this:

**Option 1: Monitor from another service**
- Use UptimeRobot (free) to ping your n8n every 5 minutes
- Sign up at https://uptimerobot.com/

**Option 2: Create a simple health check workflow**
- In n8n, create a workflow that runs every hour
- Just a simple HTTP request to any external site

---

## 🎉 Congratulations!

You now have:
- ✅ n8n running on Oracle Always Free tier
- ✅ HTTPS with automatic SSL renewal
- ✅ PostgreSQL database
- ✅ Automatic backups
- ✅ Auto-restart on reboot
- ✅ **$0/month forever!**

---

## 📚 Next Steps

### Learn n8n

1. **Official docs**: https://docs.n8n.io/
2. **Templates**: https://n8n.io/workflows/
3. **Community**: https://community.n8n.io/
4. **YouTube tutorials**: Search "n8n tutorial"

### Popular Use Cases

**Email Automation:**
- Automated welcome emails
- Follow-up sequences
- Newsletter management
- Email parsing and processing

**Cron Jobs:**
- Daily reports
- Data synchronization
- Social media posting
- Database cleanup
- API monitoring

**Integrations:**
- Gmail, Outlook, SendGrid
- Slack, Discord, Telegram
- Google Sheets, Airtable
- Stripe, PayPal
- 400+ app integrations

---

## ❓ Troubleshooting

### Can't connect to VM

**Check:**
1. Firewall rules in Oracle Cloud (Step 3.1)
2. Ubuntu firewall: `sudo ufw status`
3. SSH key permissions: `chmod 600 ~/.ssh/oracle_key`

### n8n not loading

**Check:**
1. Containers running: `docker ps`
2. Logs: `docker compose logs -f`
3. DNS propagated: `ping n8n.yourdomain.com`
4. Port 80/443 open: `sudo ufw status`

### SSL certificate errors

**Check:**
1. Domain pointing to correct IP
2. Wait 5-30 minutes for DNS propagation
3. Port 80 and 443 open
4. Try: `sudo certbot renew --dry-run`

### Database connection errors

**Check:**
1. PostgreSQL running: `docker ps | grep postgres`
2. Correct password in `.env`
3. Recreate: `docker compose down -v && docker compose up -d`

### Out of disk space

**Clean up Docker:**
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# See disk usage
docker system df
```

---

## 🔒 Security Best Practices

1. **Change default passwords** in `.env` file
2. **Use strong passwords** (16+ characters, mixed case, numbers, symbols)
3. **Enable 2FA** if n8n supports it (check latest version)
4. **Regular backups** (automated via cron)
5. **Keep system updated**: `sudo apt update && sudo apt upgrade`
6. **Monitor logs** regularly
7. **Don't expose sensitive data** in workflows
8. **Use environment variables** for API keys in n8n

---

## 💰 Cost Estimate

| Item | Cost |
|------|------|
| Oracle Cloud VM | **$0** (Always Free) |
| Domain name | $8-15/year (optional) |
| SSL certificate | **$0** (Let's Encrypt) |
| **Total** | **$0-15/year** |

Compare to:
- n8n Cloud: $240-600/year
- DigitalOcean: $72/year minimum
- AWS: $84/year minimum

**You save: $200-600/year!**

---

## 📞 Support

- **This repository**: Open an issue
- **n8n community**: https://community.n8n.io/
- **Oracle Cloud docs**: https://docs.oracle.com/cloud/
- **Docker docs**: https://docs.docker.com/

---

## 📄 License

This guide and configuration files are provided as-is under MIT License.

---

**Enjoy your free n8n automation platform! 🚀**
