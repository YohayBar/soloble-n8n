# Complete Guide to ALL Oracle Cloud VM Options

This guide explains **every single option** you'll see when creating a VM instance, so you know exactly what to select and why.

---

## Table of Contents

1. [Basic Information](#1-basic-information)
2. [Capacity Type](#2-capacity-type)
3. [Placement](#3-placement)
4. [Image and Shape](#4-image-and-shape)
5. [Networking](#5-networking)
6. [Add SSH Keys](#6-add-ssh-keys)
7. [Boot Volume](#7-boot-volume)
8. [Management](#8-management)
9. [Advanced Options](#9-advanced-options)
10. [Tags](#10-tags)

---

## 1. Basic Information

### Name

**What it is:**
- Display name for your VM instance
- Shown in the console, logs, and billing

**What to enter:**
```
n8n-production
```
Or any descriptive name like:
- `my-n8n-server`
- `automation-vm`
- `workflow-engine`

**Rules:**
- 1-255 characters
- Can use letters, numbers, hyphens, underscores
- Must start with a letter

**Best practice:**
- Use descriptive names
- Include purpose: `n8n-production`
- Include environment: `n8n-prod` vs `n8n-dev`

---

### Compartment

**What it is:**
- Logical container for organizing cloud resources
- Used for access control and billing separation
- Like folders in a file system

**What you'll see:**
```
Compartment: (root) [default]
```

**What to select:**
✅ **Leave as default** (root compartment)

**When you'd use multiple compartments:**
- Large organizations: dev, test, prod environments
- Multiple projects: project-a, project-b
- Cost allocation: marketing, engineering

**For n8n:** Root compartment is fine!

---

## 2. Capacity Type

### Options Explained

#### **On-demand Capacity** ✅ RECOMMENDED

**What it is:**
- Standard VM provisioning
- Shared physical infrastructure
- Charged by usage (or free with Always Free)

**Cost:**
- $0/month (Always Free for Ampere)
- Pay-as-you-go if you exceed limits

**When to use:**
- ✅ Always Free workloads (like n8n!)
- ✅ Production applications
- ✅ Predictable workloads

**Select this!**

---

#### **Preemptible Capacity** ❌

**What it is:**
- Discounted instances that can be shut down anytime
- Oracle can terminate with 30 seconds notice
- Used for fault-tolerant, interruptible workloads

**Cost:**
- 50% cheaper than on-demand
- NOT part of Always Free tier

**When to use:**
- Batch processing jobs
- Video rendering
- Data analysis that can be paused
- Dev/test environments

**For n8n:** ❌ Don't use - your workflows would randomly stop!

---

#### **Capacity Reservation** ❌

**What it is:**
- Pre-reserve compute capacity
- Guarantees VM availability in specific AD
- Same price as on-demand

**When to use:**
- Enterprise: Guarantee capacity for future deployments
- Compliance: Must ensure resources are available
- Scaling events: Black Friday, product launches

**For n8n:** ❌ Not needed

---

#### **Dedicated VM Host** ❌

**What it is:**
- Rent entire physical server
- Only your VMs run on it
- Complete hardware isolation

**Cost:**
- $1,500-3,000/month

**When to use:**
- Regulatory compliance (HIPAA, PCI-DSS)
- Software licensing (Oracle DB, Windows)
- Performance-critical apps

**For n8n:** ❌ Way too expensive!

**Select: On-demand capacity** ✅

---

## 3. Placement

### Availability Domain (AD)

**What it is:**
- Independent data centers within a region
- Physical separation for disaster recovery
- Each region has 1-3 ADs

**Example:**
```
US-Ashburn-AD-1
US-Ashburn-AD-2
US-Ashburn-AD-3
```

**What to select:**
✅ **AD-1** (or first available)

**What if "Out of capacity"?**
- Try AD-2
- Try AD-3
- Try different region

**Does it matter which AD?**
- ❌ No performance difference
- ❌ No cost difference
- ✅ Pick any available

**Best practice:**
- Single VM: Any AD works
- Multiple VMs: Spread across ADs for redundancy

---

### Fault Domain

**What it is:**
- Hardware grouping within an AD
- Distributes VMs across different racks/power/network
- Protects against hardware failures

**Options:**
```
○ Let Oracle choose the fault domain  ← SELECT THIS ✅
○ Choose a fault domain
  □ FAULT-DOMAIN-1
  □ FAULT-DOMAIN-2
  □ FAULT-DOMAIN-3
```

**What to select:**
✅ **"Let Oracle choose the fault domain"**

**Why automatic?**
- Oracle optimally distributes workloads
- Balances capacity
- You don't need to manage

**When to manually choose:**
- Multiple VMs: Distribute across different fault domains
- High availability: Ensure VMs aren't on same rack

**For single n8n VM:** Let Oracle choose ✅

---

### Cluster Placement Group

**What it is:**
- Groups VMs together physically
- Provides low-latency networking between VMs
- Used for HPC (High-Performance Computing)

**Options:**
```
☐ Assign to a cluster placement group  ← LEAVE UNCHECKED ✅
```

**What to select:**
✅ **Leave UNCHECKED**

**When you'd use it:**
- Database clusters (RAC, Cassandra)
- HPC workloads (scientific computing)
- Distributed systems needing ultra-low latency

**For n8n:**
- ❌ Single VM doesn't need clustering
- ❌ No inter-VM communication needed

---

## 4. Image and Shape

### Image (Operating System)

#### Image Source

**Options:**
```
● Platform images  ← SELECT THIS ✅
○ Custom images
○ Boot volumes
○ Partner images
○ Community images
```

**Explanation:**

**Platform images** ✅
- Oracle-provided official OS images
- Regularly updated
- Security patches included
- Free

**Custom images**
- Your own uploaded images
- For advanced users

**Boot volumes**
- Clone from existing VM
- For replication

**Partner images**
- Third-party software (WordPress, cPanel)
- May have licensing costs

**Community images**
- User-contributed images
- Not officially supported

**Select: Platform images** ✅

---

#### Operating System Options

**Available OS options:**

| OS | Free? | For n8n? | Notes |
|----|-------|----------|-------|
| **Canonical Ubuntu** | ✅ Yes | ✅ **Recommended** | Best support, easy to use |
| Oracle Linux | ✅ Yes | ⚠️ OK | Oracle-specific, less common |
| CentOS Stream | ✅ Yes | ⚠️ OK | Being phased out |
| Rocky Linux | ✅ Yes | ⚠️ OK | RHEL clone |
| Oracle Autonomous Linux | ✅ Yes | ❌ No | Enterprise, complex |
| Windows Server | ❌ NO | ❌ No | Not Always Free, costs money |
| Fedora | ✅ Yes | ⚠️ OK | Bleeding edge, less stable |

**Select: Canonical Ubuntu** ✅

---

#### OS Version

**Ubuntu versions available:**
```
● 24.04 (Noble Numbat) - LTS  ← RECOMMENDED ✅
○ 22.04 (Jammy Jellyfish) - LTS  ← Also good ✅
○ 20.04 (Focal Fossa) - LTS  ← Older, avoid
○ 18.04 (Bionic Beaver) - LTS  ← Too old, avoid
```

**What is LTS?**
- Long Term Support
- 5 years of security updates
- More stable than non-LTS

**Select: Ubuntu 24.04** ✅ (or 22.04)

---

#### Image Build

**What it is:**
- Date of the OS image snapshot
- Newer = latest security patches

**Example:**
```
Image build: 2024.11.15  ← Latest
Image build: 2024.10.10  ← Older
```

**What to select:**
✅ **Latest build** (default, top of list)

---

### Shape (VM Size)

#### Shape Series

**Options:**
```
● Ampere  ← SELECT THIS ✅ (Always Free!)
○ AMD
○ Intel
○ Optimized (GPU, HPC)
```

**Comparison:**

| Series | Architecture | Always Free? | Cost/month | For n8n? |
|--------|--------------|--------------|------------|----------|
| **Ampere** | ARM (aarch64) | ✅ Yes | $0 | ✅ **Use this!** |
| AMD | x86_64 | ❌ No | $15-50 | ❌ Costs money |
| Intel | x86_64 | ❌ No | $15-50 | ❌ Costs money |
| GPU | x86_64 + GPU | ❌ No | $100+ | ❌ Not needed |

**Select: Ampere** ✅

---

#### Shape Name (Ampere Options)

**Available Ampere shapes:**

```
● VM.Standard.A1.Flex  ← SELECT THIS ✅ (Always Free!)
○ BM.Standard.A1.160  (Bare metal, not free)
```

**VM.Standard.A1.Flex:**
- Flexible CPUs and RAM
- Always Free eligible
- Up to 4 OCPUs, 24 GB RAM free

**Select: VM.Standard.A1.Flex** ✅

---

#### OCPU Configuration

**What is OCPU?**
- Oracle Compute Unit
- 1 OCPU = 2 physical CPU threads
- For Ampere: 1 OCPU = 1 ARM core

**Always Free limits:**
```
Total across all VMs: 4 OCPUs, 24 GB RAM
```

**Options:**
```
Number of OCPUs: [1] [2] [3] [4]
```

**Recommendations:**

| OCPUs | RAM | Best for | Recommended? |
|-------|-----|----------|--------------|
| 1 | 6 GB | Testing only | ❌ Too small |
| 2 | 12 GB | Light n8n usage | ⚠️ OK |
| **4** | **24 GB** | **Production n8n** | ✅ **Best!** |

**Select: 4 OCPUs** ✅

---

#### Memory Configuration

**Always Free limit:**
```
Maximum: 24 GB (with 4 OCPUs)
Ratio: 6 GB per OCPU
```

**Options:**
```
Amount of memory (GB): [6] [12] [18] [24]
```

**Recommendations:**

| Memory | For n8n? | Performance |
|--------|----------|-------------|
| 6 GB | ❌ No | Too little, will swap |
| 12 GB | ⚠️ OK | Minimum for production |
| **24 GB** | ✅ **Yes** | **Plenty of headroom** |

**Select: 24 GB** ✅

**Why max out resources?**
- ✅ It's free anyway!
- ✅ Better performance
- ✅ Room to grow
- ✅ Can run more services

---

#### Network Bandwidth

**What it is:**
- Maximum network throughput
- Auto-assigned based on OCPUs

**You'll see:**
```
Network bandwidth (Gbps): 4 (automatically assigned)
```

| OCPUs | Bandwidth |
|-------|-----------|
| 1 | 1 Gbps |
| 2 | 2 Gbps |
| 4 | 4 Gbps |

**Do you configure this?**
- ❌ No, automatic
- Based on OCPU count

**Is 4 Gbps enough for n8n?**
- ✅ Yes! Way more than needed
- n8n typically uses <100 Mbps

---

## 5. Networking

### Primary VNIC (Virtual Network Interface Card)

#### Virtual Cloud Network (VCN)

**What it is:**
- Your private cloud network
- Like a virtual data center
- Contains subnets, route tables, gateways

**Options:**
```
● Select existing virtual cloud network
  ○ vcn-20241117-1234 (default)

○ Create new virtual cloud network
```

**What to select:**
✅ **Select existing VCN** (default, auto-created)

**For first-time setup:**
- Oracle auto-creates a default VCN
- Pre-configured with internet gateway
- Ready to use

**When to create new VCN:**
- Multiple projects needing isolation
- Custom networking requirements
- Advanced users only

---

#### Subnet

**What it is:**
- Subdivision of VCN
- Can be public (internet-accessible) or private

**Options:**
```
● Select existing subnet
  ○ subnet-20241117-1234 (Public Subnet)  ← SELECT THIS ✅

○ Create new subnet
```

**Public vs Private subnet:**

| Type | Internet Access | For n8n? |
|------|-----------------|----------|
| **Public** | ✅ Yes | ✅ **Use this!** |
| Private | ❌ No | ❌ Can't access n8n |

**What to select:**
✅ **Public Subnet** (default)

**Why public?**
- Access n8n from browser
- SSH access
- Webhook integrations
- Email sending

---

#### Public IP Address

**Options:**
```
☑ Assign a public IPv4 address  ← MUST CHECK ✅

Advanced options:
  ○ Ephemeral public IP (changes if VM stopped)  ← Default ✅
  ○ Reserved public IP (permanent, persists)
```

**What to select:**
✅ **CHECK "Assign a public IPv4 address"**

**Ephemeral vs Reserved IP:**

| Type | Behavior | Cost | Best for |
|------|----------|------|----------|
| **Ephemeral** | Changes if VM stopped | Free | ✅ Most cases |
| Reserved | Never changes | $0.004/hour | Static IP needed |

**For n8n:**
- ✅ Ephemeral is fine (free)
- Use domain name, not IP anyway
- Reserved IP: Optional, if you want guaranteed static IP

**If you don't check this:**
- ❌ No internet access
- ❌ Can't SSH to VM
- ❌ Can't access n8n

---

#### Hostname for VNIC

**What it is:**
- DNS hostname within VCN
- Used for internal DNS resolution

**Options:**
```
☐ Use a custom hostname  ← LEAVE UNCHECKED ✅

Default: n8n-production (matches instance name)
```

**What to select:**
✅ **Leave unchecked** (use default)

**When to use custom hostname:**
- Multiple VMs needing specific DNS names
- Internal service discovery
- Advanced networking

**For n8n:** Default is fine!

---

#### Network Security Groups (NSG)

**What it is:**
- Additional firewall rules
- Like security lists but more flexible
- Applied directly to VNIC

**Options:**
```
☐ Use network security groups to control traffic  ← LEAVE UNCHECKED ✅
```

**What to select:**
✅ **Leave unchecked**

**Security Lists vs NSG:**
- Security Lists: Applied to subnet (simpler)
- NSG: Applied to individual VNICs (more flexible)

**For n8n:**
- Security Lists are enough
- We'll configure those separately
- Don't need NSG complexity

---

#### Private IP Address

**What it is:**
- IP address within VCN
- Used for internal communication
- Auto-assigned

**Options:**
```
● Automatically assign private IPv4 address  ← SELECT THIS ✅
○ Manually assign private IPv4 address
```

**What to select:**
✅ **Automatically assign**

**When to manually assign:**
- Specific internal IP requirements
- Integrating with existing network
- Advanced use cases

**For n8n:** Auto-assign is perfect!

---

## 6. Add SSH Keys

**What it is:**
- Authentication method to access VM
- More secure than passwords
- Required for Linux VMs

**Options:**

### Option 1: Generate a New Key Pair (Easiest) ✅

```
● Generate a key pair for me  ← RECOMMENDED ✅
  [Save Private Key]  ← Download this!
  [Save Public Key]   ← Optional
```

**What to do:**
1. Select "Generate a key pair for me"
2. Click **"Save Private Key"** → saves as `.key` file
3. Save to safe location (you can't download again!)

**For beginners:** Use this option!

---

### Option 2: Upload Public Key Files

```
○ Upload public key files (.pub)
  [Choose Files]
```

**What to do:**
1. Have existing SSH key pair (e.g., `id_rsa` and `id_rsa.pub`)
2. Upload the `.pub` file
3. Use corresponding private key to connect

**For advanced users:** If you already have SSH keys

---

### Option 3: Paste Public Keys

```
○ Paste public keys
  [Text box for SSH public key]
```

**What to do:**
1. Copy your public key (starts with `ssh-rsa` or `ssh-ed25519`)
2. Paste into text box

**For advanced users:** If you manage keys manually

---

### Option 4: No SSH Keys

```
○ No SSH keys
```

**What this means:**
- ❌ **Never use this!**
- Can't access VM via SSH
- Only console access (very slow)

**Don't select this for n8n!**

---

## 7. Boot Volume

### Boot Volume Size

**What it is:**
- Primary disk storage for OS and data
- SSD storage

**Always Free limit:**
- 200 GB total across all VMs

**Options:**
```
Boot volume size (GB): [50] [100] [150] [200]

Default: 50 GB
Maximum: Up to 32 TB (but only 200 GB free!)
```

**What to select:**
✅ **200 GB** (maximum free tier)

**Why 200 GB?**
- ✅ It's free!
- ✅ Plenty for n8n + PostgreSQL + backups
- ✅ Room to grow

**Storage breakdown:**
```
OS (Ubuntu): ~5 GB
Docker: ~5 GB
PostgreSQL data: ~10-50 GB (grows over time)
n8n workflows: ~5-10 GB
Backups: ~20-50 GB
Available: ~80-155 GB
```

---

### Boot Volume Performance

**What it is:**
- IOPS (Input/Output Operations Per Second)
- Determines disk speed

**Options:**
```
○ Lower cost (0-3 IOPS/GB)
● Balanced (60 IOPS/GB)  ← DEFAULT, SELECT THIS ✅
○ Higher performance (75 IOPS/GB)
○ Ultra high performance (90-225 IOPS/GB)
```

**What to select:**
✅ **Balanced** (60 IOPS/GB)

**Performance comparison:**

| Tier | IOPS | Extra cost | For n8n? |
|------|------|------------|----------|
| Lower cost | 0-3 | $0 | ❌ Too slow |
| **Balanced** | 60 | **$0** | ✅ **Perfect!** |
| Higher | 75 | +$0.0015/GB/month | ❌ Unnecessary |
| Ultra high | 90-225 | +$0.003/GB/month | ❌ Overkill |

**Balanced gives you:**
- 200 GB × 60 IOPS = 12,000 IOPS
- More than enough for n8n!
- PostgreSQL runs great

---

### Encryption

**What it is:**
- Data-at-rest encryption
- Protects data on disk

**Options:**
```
● Encrypt using Oracle-managed keys  ← SELECT THIS ✅
○ Encrypt using customer-managed keys
```

**What to select:**
✅ **Oracle-managed keys**

**Oracle-managed vs Customer-managed:**

| Type | Who manages? | Complexity | Cost | For n8n? |
|------|--------------|------------|------|----------|
| **Oracle-managed** | Oracle | ✅ Simple | Free | ✅ **Use this!** |
| Customer-managed | You (via Vault) | ❌ Complex | Extra cost | ❌ Unnecessary |

**For n8n:**
- Oracle-managed encryption is secure
- Automatic key rotation
- No extra work

---

### Encrypt In-Transit Data

**What it is:**
- Encrypts data moving between VM and block storage
- Extra security layer

**Options:**
```
☐ Encrypt in-transit data  ← LEAVE UNCHECKED ✅
```

**What to select:**
✅ **Leave unchecked**

**Why unchecked?**
- Not needed for most workloads
- Data is already encrypted at rest
- Slight performance overhead
- Free tier doesn't require it

**When to use:**
- Ultra-high security requirements
- Compliance mandates
- Paranoid security

---

### Boot Volume Backup Policy

**What it is:**
- Automatic backups of boot volume
- Scheduled snapshots

**Options:**
```
○ Bronze (monthly backups)
○ Silver (weekly backups)
○ Gold (daily backups)
● Do not enable backup  ← SELECT THIS ✅
```

**What to select:**
✅ **Do not enable backup**

**Why disable?**
- ❌ Not included in Always Free tier
- ❌ Costs $0.0255/GB/month
- ✅ We have custom backup script (better!)

**Our backup strategy:**
- Local backups via script
- Optional Object Storage backups
- More flexible than boot volume backups

---

### Use Oracle Cloud Agent to Automatically Tune Performance

**What it is:**
- Agent that optimizes VM settings
- Monitors and adjusts automatically

**Options:**
```
☐ Use Oracle Cloud Agent  ← OPTIONAL
```

**What to select:**
✅ **Leave unchecked** (or check, doesn't matter)

**What it does:**
- Monitoring and metrics
- Performance optimization
- Security scanning

**For n8n:**
- Optional, not required
- No cost
- Can be enabled later if needed

---

## 8. Management

### Cloud-Init Script (Advanced)

**What it is:**
- Script that runs on first boot
- Automates initial VM setup
- Like installation automation

**Options:**
```
☐ Paste cloud-init script
☐ Choose cloud-init script file
```

**What to select:**
✅ **Leave unchecked** (for now)

**When you'd use it:**
- Automated deployments
- CI/CD pipelines
- Fleet management

**For n8n:**
- Not needed for manual setup
- We'll install via SSH

**Example use:**
```bash
#!/bin/bash
apt update
apt install -y docker.io
# ... more commands
```

---

### Management Agent

**What it is:**
- Oracle's monitoring/management agent
- Provides metrics, logs, etc.

**Options (expandable section):**
```
Management Agent plugins:
  ☑ Block Volume Management
  ☑ Compute Instance Monitoring
  ☑ OS Management Service Agent
```

**What to select:**
✅ **Leave defaults checked**

**What each does:**
- Block Volume Management: Disk management
- Monitoring: CPU/RAM metrics in console
- OS Management: Patching and updates

**Impact:**
- Free features
- Useful for monitoring
- Can disable later if not needed

---

## 9. Advanced Options

### Instance Options

#### Firmware

**What it is:**
- Boot firmware type
- UEFI vs Legacy BIOS

**Options:**
```
● UEFI_64  ← DEFAULT ✅
○ BIOS
```

**What to select:**
✅ **UEFI_64** (default)

**UEFI vs BIOS:**
- UEFI: Modern, secure boot, faster
- BIOS: Legacy, older systems

**For Ubuntu 24.04:**
- Requires UEFI
- Don't change this

---

#### Launch Mode

**What it is:**
- Security features for VM boot

**Options:**
```
● Native (recommended)  ← SELECT THIS ✅
○ Emulated
○ Paravirtualized
○ Custom
```

**What to select:**
✅ **Native**

**What each means:**
- Native: Best performance, uses hardware features
- Emulated: Slower, for compatibility
- Paravirtualized: For older OSes
- Custom: Advanced users only

---

#### TPM (Trusted Platform Module)

**What it is:**
- Hardware security chip (virtual)
- For encryption and secure boot

**Options:**
```
☐ Enable Trusted Platform Module (TPM)
```

**What to select:**
✅ **Leave unchecked**

**When to use:**
- Windows VMs with BitLocker
- Secure boot requirements
- Compliance needs

**For Linux n8n:**
- Not needed
- No benefit

---

#### Secure Boot

**What it is:**
- Prevents unauthorized OS/bootloader
- Validates boot components

**Options:**
```
☐ Enable Secure Boot
```

**What to select:**
✅ **Leave unchecked**

**When to use:**
- High security environments
- Windows VMs
- Compliance requirements

**For n8n:**
- Optional, not required
- Standard Ubuntu works without it

---

#### Measured Boot

**What it is:**
- Records boot measurements
- Detects boot tampering

**Options:**
```
☐ Enable Measured Boot
```

**What to select:**
✅ **Leave unchecked**

**When to use:**
- Enterprise security
- Attestation requirements
- Forensics

**For n8n:**
- Not needed
- Adds complexity

---

### Capacity Reservation

**What it is:**
- Reserve capacity in advance
- Guarantees VM availability

**Options:**
```
☐ Use capacity reservation
```

**What to select:**
✅ **Leave unchecked**

**When to use:**
- Enterprise: Need guaranteed capacity
- Predictable scaling events
- Business continuity requirements

**For n8n:**
- Not needed
- On-demand is sufficient

---

### Fault Domain (Repeat)

Already covered in Placement section.

---

## 10. Tags

### What are Tags?

**What it is:**
- Metadata key-value pairs
- For organization, cost tracking, automation

**Options:**
```
☐ Show tagging options
```

**What to select:**
✅ **Leave unchecked** (optional)

**Example tags:**
```
Environment: production
Application: n8n
Owner: john@example.com
Cost-Center: engineering
```

**When to use:**
- Multiple projects: Tag by project name
- Cost allocation: Track spending per team
- Automation: Scripts filter by tags
- Organization: Group related resources

**For single n8n VM:**
- Not necessary
- Can add later if needed

**Types of tags:**

### Defined Tags
- Created by admin
- Fixed key names
- Used for governance

### Free-form Tags
- Any key-value pairs
- Flexible
- For your own organization

**For n8n:** Skip tags unless you have multiple projects.

---

## Summary: Recommended Settings

Here's the complete configuration for n8n on Always Free tier:

```
┌─────────────────────────────────────────────────────────┐
│ BASIC INFORMATION                                       │
├─────────────────────────────────────────────────────────┤
│ Name: n8n-production                                    │
│ Compartment: (root)                                     │
│                                                         │
│ CAPACITY TYPE                                           │
├─────────────────────────────────────────────────────────┤
│ ● On-demand capacity                                    │
│                                                         │
│ PLACEMENT                                               │
├─────────────────────────────────────────────────────────┤
│ Availability domain: AD-1 (or first available)          │
│ Fault domain: Let Oracle choose                         │
│ Cluster placement group: ☐ Not assigned                │
│                                                         │
│ IMAGE AND SHAPE                                         │
├─────────────────────────────────────────────────────────┤
│ Image source: Platform images                           │
│ OS: Canonical Ubuntu 24.04                             │
│ Image build: Latest                                     │
│                                                         │
│ Shape: VM.Standard.A1.Flex (Ampere)                    │
│ OCPUs: 4                                                │
│ Memory: 24 GB                                           │
│ Network bandwidth: 4 Gbps (auto)                        │
│ Always Free-eligible: ✓ Yes                            │
│                                                         │
│ NETWORKING                                              │
├─────────────────────────────────────────────────────────┤
│ VCN: Default VCN                                        │
│ Subnet: Public Subnet                                   │
│ ☑ Assign public IPv4 address (Ephemeral)              │
│ Private IP: Auto-assign                                 │
│ Hostname: Default                                       │
│ Network security groups: ☐ None                        │
│                                                         │
│ SSH KEYS                                                │
├─────────────────────────────────────────────────────────┤
│ ● Generate key pair for me                             │
│ [Download and save private key!]                        │
│                                                         │
│ BOOT VOLUME                                             │
├─────────────────────────────────────────────────────────┤
│ Size: 200 GB                                            │
│ Performance: Balanced (60 IOPS/GB)                      │
│ Encryption: Oracle-managed keys                         │
│ Encrypt in-transit: ☐ No                               │
│ Backup policy: Do not enable                            │
│                                                         │
│ MANAGEMENT                                              │
├─────────────────────────────────────────────────────────┤
│ Cloud-init script: ☐ None                              │
│ Management agent: Default plugins enabled               │
│                                                         │
│ ADVANCED OPTIONS                                        │
├─────────────────────────────────────────────────────────┤
│ Firmware: UEFI_64                                       │
│ Launch mode: Native                                     │
│ TPM: ☐ Disabled                                         │
│ Secure boot: ☐ Disabled                                │
│ Measured boot: ☐ Disabled                              │
│ Capacity reservation: ☐ None                           │
│                                                         │
│ TAGS                                                    │
├─────────────────────────────────────────────────────────┤
│ None (optional)                                         │
└─────────────────────────────────────────────────────────┘

                    💰 Cost: $0/month forever
```

---

## Quick Decision Tree

**Not sure what to select? Use this:**

```
Is it already selected/checked by default?
├─ YES → Leave it alone ✅
└─ NO → Is it mentioned in the recommended config above?
   ├─ YES → Change to recommended value
   └─ NO → Leave default ✅
```

**When in doubt: Use defaults!** Oracle's defaults are sensible for most workloads.

---

## Options You Can Ignore (Safe to Skip)

These are optional and don't affect n8n:

- ✅ Tags
- ✅ TPM
- ✅ Secure Boot
- ✅ Measured Boot
- ✅ Capacity Reservation
- ✅ Network Security Groups
- ✅ Custom hostname
- ✅ Cloud-init script
- ✅ Encrypt in-transit
- ✅ Boot volume backups

**Just use the recommended settings!**

---

## Next Steps

After understanding all options:

1. **Create VM** with recommended settings
2. **Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** for installation
3. **Setup database** with [database/setup-database.sh](database/setup-database.sh)
4. **Configure backups** per [BACKUP_GUIDE.md](BACKUP_GUIDE.md)

**Questions?** All these guides are in your repository!

---

**You now understand EVERY option! 🎉**
