# Complete Backup Strategy for n8n on Oracle Cloud

This guide covers multiple backup strategies to ensure your data is safe.

## 📊 Backup Strategy Overview

We implement a **3-2-1 backup strategy**:
- **3** copies of your data
- **2** different storage types
- **1** off-site copy

### Backup Levels

| Level | Location | Storage | Auto | Recovery Time | Safety |
|-------|----------|---------|------|---------------|--------|
| **Level 1** | VM Local | Block Volume | ✅ Daily | Seconds | ⚠️ Same VM |
| **Level 2** | Object Storage | Oracle Cloud | ✅ Daily | Minutes | ✅ Off-VM |
| **Level 3** | External | Cloud/Local | Manual | Hours | ✅✅ Off-site |

---

## Level 1: Local Backups (Already Included)

### What's Backed Up
- PostgreSQL database (full dump)
- n8n workflow data
- n8n credentials (encrypted)
- Configuration files (.env, docker-compose.yml, nginx.conf)

### Location
```bash
~/n8n-backups/
└── n8n-backup-YYYYMMDD-HHMMSS.tar.gz
```

### Automatic Schedule
- **Daily** at 2:00 AM
- **Retention**: 30 days
- **Size**: ~100 MB - 1 GB (depending on workflows)

### Manual Backup
```bash
# Create backup now
~/backup-n8n.sh

# List backups
ls -lh ~/n8n-backups/

# Restore from backup
~/restore-n8n.sh
```

### Limitations
⚠️ **Problem**: If your VM is deleted or corrupted, local backups are lost too!

---

## Level 2: Oracle Object Storage (Recommended)

### Why Object Storage?

✅ **Separate from VM** - Survives VM deletion
✅ **20 GB free** - More than enough for backups
✅ **99.9% durability** - Multiple copies maintained by Oracle
✅ **Regional redundancy** - Replicated across multiple servers
✅ **Cost**: $0 (within Always Free limits)

### Setup Object Storage

#### Step 1: Create Object Storage Bucket

1. **Log in** to Oracle Cloud Console
2. Navigate to **Storage → Buckets**
3. Click **"Create Bucket"**

**Bucket Configuration:**
```
Bucket Name: n8n-backups
Default Storage Tier: Standard
Enable Auto-Tiering: No (optional)
Encryption: Encrypt using Oracle-managed keys
Emit Object Events: No
Versioning: Enabled (recommended)
```

4. Click **"Create"**

#### Step 2: Create API Key

1. Click your **profile icon** (top right)
2. Select **"User Settings"**
3. Scroll to **"Resources" → "API Keys"**
4. Click **"Add API Key"**
5. Select **"Generate API Key Pair"**
6. Click **"Download Private Key"** → Save as `oci_api_key.pem`
7. Click **"Download Public Key"** (optional)
8. Click **"Add"**

**Save the configuration** shown (you'll need this):
```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaa...
fingerprint=aa:bb:cc:dd...
tenancy=ocid1.tenancy.oc1..aaaaaa...
region=us-ashburn-1
key_file=~/.oci/oci_api_key.pem
```

#### Step 3: Install OCI CLI on Your VM

```bash
# Connect to your VM
ssh -i ~/.ssh/oracle_key ubuntu@YOUR_VM_IP

# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Accept all defaults (press Enter)
# Installation takes 2-3 minutes

# Verify installation
oci --version
```

#### Step 4: Configure OCI CLI

```bash
# Create config directory
mkdir -p ~/.oci
chmod 700 ~/.oci

# Upload your API key
# Option A: Copy from local machine
# On your local machine:
scp -i ~/.ssh/oracle_key ~/Downloads/oci_api_key.pem ubuntu@YOUR_VM_IP:~/.oci/

# On VM: Set permissions
chmod 600 ~/.oci/oci_api_key.pem

# Option B: Create directly on VM
nano ~/.oci/config
```

**Paste your configuration** (from Step 2):
```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaa...
fingerprint=aa:bb:cc:dd...
tenancy=ocid1.tenancy.oc1..aaaaaa...
region=us-ashburn-1
key_file=~/.oci/oci_api_key.pem
```

Save and set permissions:
```bash
chmod 600 ~/.oci/config
```

#### Step 5: Test Object Storage Access

```bash
# Get your namespace
OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output)
echo "Namespace: $OCI_NAMESPACE"

# List buckets
oci os bucket list --compartment-id YOUR_COMPARTMENT_ID

# Test upload
echo "test" > test.txt
oci os object put -bn n8n-backups -ns $OCI_NAMESPACE --file test.txt --name test.txt

# Test download
oci os object get -bn n8n-backups -ns $OCI_NAMESPACE --name test.txt --file downloaded_test.txt

# Clean up test
rm test.txt downloaded_test.txt
oci os object delete -bn n8n-backups -ns $OCI_NAMESPACE --name test.txt
```

#### Step 6: Use Enhanced Backup Script

The enhanced backup script automatically uploads to Object Storage:

```bash
# Copy enhanced backup script
cp ~/soloble-n8n/scripts/backup-with-object-storage.sh ~/backup-n8n.sh
chmod +x ~/backup-n8n.sh

# Configure
nano ~/backup-n8n.sh
```

Update these variables:
```bash
OCI_BUCKET="n8n-backups"
OCI_NAMESPACE="your-namespace-here"  # From Step 5
ENABLE_OBJECT_STORAGE="true"
```

**Test it:**
```bash
~/backup-n8n.sh
```

You should see:
```
✓ Backup created locally: ~/n8n-backups/n8n-backup-20250117-120000.tar.gz
✓ Backup uploaded to Object Storage
✓ Remote backups: 5
```

#### Step 7: Verify Backups in Object Storage

```bash
# List remote backups
oci os object list -bn n8n-backups -ns $OCI_NAMESPACE

# Check backup size
oci os object head -bn n8n-backups -ns $OCI_NAMESPACE --name n8n-backup-YYYYMMDD-HHMMSS.tar.gz
```

Or via Web Console:
1. Go to **Storage → Buckets**
2. Click **"n8n-backups"**
3. View your backup files

---

## Level 3: External Backups (Maximum Safety)

For absolute safety, copy backups to external storage:

### Option A: Download to Local Computer

```bash
# From your local computer
scp -i ~/.ssh/oracle_key ubuntu@YOUR_VM_IP:~/n8n-backups/*.tar.gz ~/local-backups/

# Schedule weekly (macOS/Linux)
crontab -e
```
Add:
```cron
0 3 * * 0 scp -i ~/.ssh/oracle_key ubuntu@YOUR_VM_IP:~/n8n-backups/n8n-backup-$(date +\%Y\%m\%d)-*.tar.gz ~/local-backups/
```

### Option B: Google Drive (Using rclone)

```bash
# On your VM
curl https://rclone.org/install.sh | sudo bash

# Configure Google Drive
rclone config
# Follow prompts to add Google Drive

# Test upload
rclone copy ~/n8n-backups/ gdrive:n8n-backups/

# Add to backup script
nano ~/backup-n8n.sh
```

Add after creating backup:
```bash
# Upload to Google Drive
rclone copy "$BACKUP_FILE" gdrive:n8n-backups/ --progress
```

### Option C: GitHub (Encrypted)

For small backups (<100 MB), use encrypted git storage:

```bash
# Install git-crypt
sudo apt install git-crypt

# Create private backup repo
# On GitHub, create private repo: n8n-backups-encrypted

# Clone and setup
cd ~
git clone git@github.com:yourusername/n8n-backups-encrypted.git
cd n8n-backups-encrypted

# Initialize encryption
git-crypt init
git-crypt export-key ~/backup-key

# Add backups
cp ~/n8n-backups/*.tar.gz .
git add .
git commit -m "Backup $(date +%Y%m%d)"
git push
```

---

## Backup Storage Comparison

| Method | Free Space | Pros | Cons |
|--------|-----------|------|------|
| **Oracle Object Storage** | 20 GB | Same platform, fast, durable | Requires setup |
| **Google Drive** | 15 GB | Easy, accessible | Slower, requires rclone |
| **Dropbox** | 2 GB | Easy sync | Limited space |
| **GitHub (encrypted)** | 1 GB | Version control | Size limits |
| **Local Download** | Unlimited | Full control | Manual effort |

---

## Backup Best Practices

### 1. Regular Testing

**Test restores monthly:**
```bash
# Download backup from Object Storage
oci os object get -bn n8n-backups -ns $OCI_NAMESPACE \
  --name n8n-backup-LATEST.tar.gz \
  --file /tmp/test-restore.tar.gz

# Test restore (in staging environment)
~/restore-n8n.sh
```

### 2. Monitoring

**Check backup status:**
```bash
# View backup log
tail -f ~/backup.log

# Check last backup
ls -lht ~/n8n-backups/ | head -2

# Verify Object Storage
oci os object list -bn n8n-backups -ns $OCI_NAMESPACE --fields name,timeCreated,size
```

### 3. Encryption (Extra Security)

**Encrypt backups before upload:**

```bash
# Install gpg
sudo apt install gnupg

# Generate encryption key
gpg --gen-key

# Encrypt backup
gpg --encrypt --recipient your-email@example.com ~/n8n-backups/n8n-backup-*.tar.gz

# Upload encrypted version
oci os object put -bn n8n-backups -ns $OCI_NAMESPACE --file backup.tar.gz.gpg

# Decrypt when needed
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### 4. Retention Policy

**Recommended retention:**
- **Daily**: Keep 7 days (local)
- **Weekly**: Keep 4 weeks (Object Storage)
- **Monthly**: Keep 12 months (External/downloaded)

---

## Disaster Recovery Scenarios

### Scenario 1: Accidental Data Deletion

**Recovery Time**: 2-5 minutes

```bash
~/restore-n8n.sh
# Select recent backup
```

### Scenario 2: VM Corruption

**Recovery Time**: 10-30 minutes

1. Create new Oracle VM
2. Install n8n (run install.sh)
3. Download backup from Object Storage:
```bash
oci os object get -bn n8n-backups -ns $OCI_NAMESPACE \
  --name n8n-backup-LATEST.tar.gz \
  --file ~/n8n-backup.tar.gz
```
4. Extract manually or use restore script

### Scenario 3: Complete VM Deletion

**Recovery Time**: 1-2 hours

1. Create new Oracle VM (follow DEPLOYMENT_GUIDE.md)
2. Install OCI CLI and configure
3. Download latest backup from Object Storage
4. Restore data

### Scenario 4: Regional Outage

**Recovery Time**: 2-4 hours

1. Create VM in different region
2. Download from external backup (Google Drive, local, etc.)
3. Restore

---

## Backup Automation Summary

### What Happens Automatically

**Every day at 2:00 AM:**

1. ✅ PostgreSQL database exported
2. ✅ n8n data archived
3. ✅ Configuration files backed up
4. ✅ Compressed into .tar.gz
5. ✅ Uploaded to Object Storage (if configured)
6. ✅ Old local backups deleted (>30 days)
7. ✅ Old remote backups deleted (>90 days, optional)

### Manual Actions Required

- **Weekly**: Verify backup log (`cat ~/backup.log`)
- **Monthly**: Test restore process
- **Quarterly**: Download important backups locally

---

## Cost Analysis

### Within Always Free Limits

| Resource | Free Tier | Your Usage | Cost |
|----------|-----------|------------|------|
| Block Storage | 200 GB | ~10 GB | $0 |
| Object Storage | 20 GB | ~5 GB | $0 |
| API Calls | 50,000/month | ~100/month | $0 |
| Outbound Data | 10 GB/month | ~50 MB/month | $0 |
| **Total** | - | - | **$0** |

### If You Exceed Free Tier

- Object Storage: $0.0255/GB/month (~$0.03/month for 1 GB)
- Still cheaper than any alternative!

---

## Troubleshooting

### Backup Script Fails

```bash
# Check permissions
ls -la ~/backup-n8n.sh
chmod +x ~/backup-n8n.sh

# Check disk space
df -h
docker system prune -a

# Check logs
tail -100 ~/backup.log
```

### OCI CLI Authentication Fails

```bash
# Verify config
cat ~/.oci/config

# Check key permissions
ls -la ~/.oci/oci_api_key.pem
chmod 600 ~/.oci/oci_api_key.pem

# Test authentication
oci iam region list
```

### Object Storage Upload Fails

```bash
# Check namespace
oci os ns get

# Verify bucket exists
oci os bucket get --bucket-name n8n-backups

# Test with small file
echo "test" > test.txt
oci os object put -bn n8n-backups --file test.txt --name test.txt
```

---

## Quick Reference

### Backup Commands

```bash
# Create backup now
~/backup-n8n.sh

# List local backups
ls -lht ~/n8n-backups/

# List Object Storage backups
oci os object list -bn n8n-backups -ns $(oci os ns get --query 'data' --raw-output)

# Restore from backup
~/restore-n8n.sh

# Download from Object Storage
oci os object get -bn n8n-backups -ns $OCI_NAMESPACE --name FILENAME --file local-file.tar.gz

# View backup log
tail -f ~/backup.log
```

---

## Conclusion

With this multi-level backup strategy:

✅ **Daily automated backups** (local + Object Storage)
✅ **99.9% data durability** (Oracle redundancy)
✅ **Off-VM protection** (Object Storage)
✅ **Disaster recovery** (<2 hour RTO)
✅ **Zero cost** (within free tier)

**Your data is safe!** 🛡️

---

**Next Steps:**
1. Set up Oracle Object Storage (30 minutes)
2. Configure OCI CLI (15 minutes)
3. Test backup script (5 minutes)
4. Schedule monthly restore tests

Questions? Check the main [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) or open an issue.
