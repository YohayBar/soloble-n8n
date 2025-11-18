# Oracle Cloud VM Configuration Quick Reference

## Exact Settings for n8n on Always Free Tier

### ✅ What to Select

| Setting | Value | Notes |
|---------|-------|-------|
| **Capacity Type** | ✅ On-demand capacity | Guaranteed, Always Free eligible |
| **Availability Domain** | ✅ AD-1, AD-2, or AD-3 | Choose any available (try AD-1 first) |
| **Fault Domain** | ✅ Let Oracle choose | Automatic selection |
| **Cluster Placement Group** | ❌ UNCHECKED | Not needed for n8n |
| **Image Source** | ✅ Platform images | Default option |
| **Operating System** | ✅ Canonical Ubuntu | |
| **OS Version** | ✅ 24.04 or 22.04 | LTS versions |
| **Shape Series** | ✅ Ampere | ARM-based, Always Free |
| **Shape Name** | ✅ VM.Standard.A1.Flex | The only Always Free shape |
| **OCPUs** | ✅ 2 or 4 | Recommended: 4 |
| **Memory (GB)** | ✅ 12 or 24 | Recommended: 24 |
| **Boot Volume Size** | ✅ 200 GB | Maximum for Always Free |
| **VCN** | ✅ Default/Auto-created | Or existing VCN |
| **Subnet** | ✅ Public Subnet | Must be public |
| **Public IP** | ✅ CHECKED | Required for access |

---

## Detailed Explanation

### 1. Capacity Type

**✅ SELECT: On-demand capacity**

**Options:**
- ✅ On-demand capacity (Always Free eligible)
- ❌ Preemptible capacity (can be shut down anytime)
- ❌ Capacity reservation (for enterprise)

**Why On-demand?**
- Guaranteed to stay running
- Required for Always Free tier
- No surprise shutdowns

---

### 2. Availability Domain (AD)

**✅ SELECT: AD-1 (or any available)**

**What is it?**
- Physical data center location within your region
- Each region has 1-3 ADs

**Which to choose?**
1. Try **AD-1** first
2. If "Out of capacity" error → try **AD-2**
3. If still error → try **AD-3**

**Tip:** US regions usually have capacity in all ADs. Other regions may vary.

**Example:**
```
US-Ashburn-AD-1 ✅
US-Ashburn-AD-2 ✅
US-Ashburn-AD-3 ✅
```

---

### 3. Fault Domain

**✅ SELECT: "Let Oracle choose the fault domain"**

**What is it?**
- Hardware grouping within an AD for redundancy
- Helps distribute resources

**Should I change it?**
- ❌ No, leave as automatic
- Oracle distributes optimally

---

### 4. Cluster Placement Group

**✅ LEAVE UNCHECKED ❌**

**What is it?**
- Groups VMs together for low-latency networking
- Used for HPC (High-Performance Computing)
- Like database clusters, Hadoop, etc.

**Do I need it for n8n?**
- ❌ No! n8n runs on a single VM
- This is for multi-VM setups

**Setting:**
```
☐ Assign to a cluster placement group  ← LEAVE UNCHECKED
```

---

### 5. Image (Operating System)

**✅ SELECT: Canonical Ubuntu 24.04**

**Step by step:**
1. Click **"Change Image"**
2. Under "Image source": Keep **"Platform images"**
3. Under "Operating system": Select **"Canonical Ubuntu"**
4. Under "OS version": Select **"24.04"** (or 22.04)
5. Click **"Select Image"**

**Other options (not recommended):**
- ❌ Oracle Linux (Oracle-specific, unfamiliar)
- ❌ CentOS Stream (outdated)
- ❌ Rocky Linux (less documentation)
- ❌ Windows (not Always Free)

**Why Ubuntu?**
- ✅ Most popular for cloud deployments
- ✅ Best documentation
- ✅ n8n officially supports Ubuntu
- ✅ Easy to use (apt package manager)

---

### 6. Shape (VM Size)

**✅ SELECT: VM.Standard.A1.Flex with 4 OCPUs, 24 GB RAM**

**Step by step:**
1. Click **"Change Shape"**
2. Click **"Ampere"** tab (not AMD or Intel!)
3. Select **"VM.Standard.A1.Flex"**
4. Set **OCPUs: 4**
5. Set **Memory: 24 GB**
6. Verify badge shows: **"Always Free-eligible"**
7. Click **"Select Shape"**

**Shape Options Explained:**

| Shape Series | Always Free? | Architecture | For n8n? |
|--------------|--------------|--------------|----------|
| **Ampere** | ✅ Yes | ARM (aarch64) | ✅ **Use this!** |
| AMD | ❌ No | x86_64 | ❌ Costs money |
| Intel | ❌ No | x86_64 | ❌ Costs money |

**Resource Limits:**

| Resource | Always Free Limit | Recommended for n8n |
|----------|-------------------|---------------------|
| OCPUs | Up to 4 total | 4 (max it out!) |
| Memory | Up to 24 GB total | 24 GB (max it out!) |
| Instances | Can split across VMs | 1 VM with all resources |

**Examples of valid Always Free configurations:**

✅ **Option 1 (Recommended): 1 VM**
- 1 VM: 4 OCPUs, 24 GB RAM

✅ **Option 2: 2 VMs**
- VM 1: 2 OCPUs, 12 GB RAM
- VM 2: 2 OCPUs, 12 GB RAM

✅ **Option 3: 4 VMs**
- 4 VMs: 1 OCPU, 6 GB RAM each

**For n8n, use Option 1** (all resources on one VM).

---

### 7. Boot Volume

**✅ SELECT: 200 GB**

**Settings:**
- **Boot volume size:** `200 GB` (slider to maximum)
- **Boot volume performance:** Leave as default (Balanced)
- **Encryption:** Leave as default (Oracle-managed keys)

**Why 200 GB?**
- Maximum for Always Free
- Plenty for n8n + PostgreSQL + backups
- No cost difference

---

### 8. Networking

**✅ Public IP: MUST BE CHECKED**

**Settings:**
- **VCN:** Use default or existing
- **Subnet:** Must be **Public Subnet** (not private!)
- **Public IP:** ✅ **CHECK "Assign a public IPv4 address"**

**Why public IP?**
- ✅ Access n8n from browser
- ✅ SSH access
- ✅ Webhook integrations
- ✅ Email sending/receiving

**Private IP only:**
- ❌ No external access
- ❌ Can't access n8n from internet
- ❌ Need VPN or bastion host

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Choosing AMD/Intel Shape
**Problem:** Not Always Free, costs $15-50/month
**Solution:** Choose **Ampere** shape only

### ❌ Mistake 2: Private Subnet
**Problem:** Can't access VM from internet
**Solution:** Choose **Public Subnet** and check **Assign public IP**

### ❌ Mistake 3: Too Few Resources
**Problem:** n8n runs slowly with 1 OCPU, 6 GB
**Solution:** Use maximum: **4 OCPUs, 24 GB RAM**

### ❌ Mistake 4: Checking Cluster Placement Group
**Problem:** Unnecessary complexity
**Solution:** Leave **unchecked**

### ❌ Mistake 5: Preemptible Capacity
**Problem:** VM can be shut down anytime
**Solution:** Choose **On-demand capacity**

### ❌ Mistake 6: Wrong OS Version
**Problem:** Older Ubuntu (18.04, 20.04) lacks support
**Solution:** Choose **Ubuntu 22.04 or 24.04 LTS**

---

## Quick Checklist

Before clicking "Create", verify:

- ✅ Capacity type: **On-demand**
- ✅ Availability domain: **Any available (AD-1, AD-2, or AD-3)**
- ✅ Cluster placement: **Unchecked**
- ✅ Image: **Ubuntu 24.04** (or 22.04)
- ✅ Shape: **VM.Standard.A1.Flex (Ampere)**
- ✅ OCPUs: **4**
- ✅ Memory: **24 GB**
- ✅ Boot volume: **200 GB**
- ✅ Public IP: **Checked**
- ✅ Badge shows: **"Always Free-eligible"**

---

## Troubleshooting

### "Out of Capacity" Error

**Problem:** Oracle ran out of Ampere VMs in that AD

**Solutions:**
1. Try different Availability Domain (AD-2, AD-3)
2. Try different region (e.g., Phoenix, Frankfurt)
3. Try again in a few hours (capacity changes)
4. Create with fewer resources first (2 OCPU, 12 GB), upgrade later

### Can't Find "Ampere" Option

**Problem:** Region doesn't support Ampere yet

**Solution:**
- Switch region in top-right dropdown
- Recommended regions: US-Ashburn, US-Phoenix, Frankfurt, London

### No "Always Free-eligible" Badge

**Problem:** Selected wrong shape or region

**Solution:**
- Verify shape is **VM.Standard.A1.Flex**
- Verify shape series is **Ampere**
- Check region supports Always Free (most do)

---

## My Recommended Configuration

```
Instance Name: n8n-production
Capacity Type: On-demand capacity
Availability Domain: [Your-Region]-AD-1
Fault Domain: Let Oracle choose
Cluster Placement Group: [ ] Not assigned

Image: Canonical Ubuntu 24.04 (latest build)

Shape: VM.Standard.A1.Flex (Ampere)
  OCPUs: 4
  Memory: 24 GB
  Network bandwidth: 4 Gbps
  Always Free: ✓ Yes

Networking:
  VCN: Default VCN
  Subnet: Public Subnet
  ☑ Assign a public IPv4 address

Boot Volume:
  Size: 200 GB
  Performance: Balanced

SSH Keys: Generate new pair (save the private key!)
```

**Cost: $0/month forever** 🎉

---

## Visual Summary

```
┌─────────────────────────────────────────────┐
│  Oracle Cloud Always Free VM                │
│                                             │
│  Shape: VM.Standard.A1.Flex (Ampere)       │
│  CPU: 4 ARM cores @ 3.0 GHz                │
│  RAM: 24 GB                                 │
│  Storage: 200 GB SSD                        │
│  Network: 4 Gbps, Public IP                 │
│  OS: Ubuntu 24.04 LTS                       │
│                                             │
│  Perfect for:                               │
│  ✓ n8n workflow automation                  │
│  ✓ PostgreSQL database                      │
│  ✓ 10-100 users                            │
│  ✓ 7,000+ executions/month                 │
│  ✓ AI processing                            │
│                                             │
│  Cost: $0/month forever                     │
└─────────────────────────────────────────────┘
```

---

**Questions?** Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for full step-by-step instructions!
