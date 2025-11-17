# n8n on Oracle Cloud Always Free Tier

Deploy [n8n](https://n8n.io/) (workflow automation platform) on Oracle Cloud's Always Free tier - completely free, forever!

## What is this?

This repository provides everything you need to deploy n8n on Oracle Cloud's Always Free tier VM, giving you:

- **n8n workflow automation** - 400+ app integrations, email automation, cron scheduling
- **PostgreSQL database** - Reliable data storage
- **Nginx reverse proxy** - Production-ready with SSL/HTTPS
- **Automatic backups** - Scheduled daily backups with retention
- **Zero monthly costs** - Truly free forever (except optional domain ~$10/year)

## Why Oracle Cloud Always Free?

| Feature | Specification |
|---------|---------------|
| **Cost** | $0/month forever (no credit card charges) |
| **CPU** | 4 ARM cores (Ampere A1) |
| **RAM** | 24 GB |
| **Storage** | 200 GB block storage |
| **Bandwidth** | 10 TB/month outbound |
| **Perfect for** | 10-100 workflows, 700-7,000+ executions/month |

**Cost Comparison:**
- n8n Cloud: $240-600/year
- DigitalOcean: $72/year minimum
- AWS: $84/year minimum
- **Oracle Free Tier: $0/year** 🎉

## Quick Start

### Prerequisites

- Oracle Cloud account (free)
- Domain name (optional but recommended, ~$10/year)
- 2-3 hours for setup

### Installation

**Option 1: Automated Installation (Recommended)**

```bash
# On your Oracle Cloud VM
wget https://raw.githubusercontent.com/YohayBar/soloble-n8n/main/scripts/install.sh
chmod +x install.sh
./install.sh
```

**Option 2: Manual Installation**

Follow the comprehensive [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for step-by-step instructions.

## What's Included

```
soloble-n8n/
├── DEPLOYMENT_GUIDE.md          # Complete step-by-step guide
├── docker-compose.yml            # Docker orchestration
├── .env.example                  # Environment configuration template
├── nginx/
│   └── nginx.conf               # Nginx reverse proxy config
└── scripts/
    ├── install.sh               # Automated installation
    ├── backup.sh                # Backup automation
    └── restore.sh               # Restore from backup
```

## Features

- ✅ **Production-ready** - Nginx, SSL/HTTPS, PostgreSQL
- ✅ **Auto-start** - Systemd service for automatic restart on reboot
- ✅ **Secure** - Basic auth, SSL certificates, firewall configured
- ✅ **Automated backups** - Daily backups with 30-day retention
- ✅ **Easy restore** - One-command restore from backup
- ✅ **Well-documented** - Comprehensive guide with troubleshooting

## Use Cases

### Email Automation
- Welcome email sequences
- Follow-up campaigns
- Newsletter management
- Email parsing and routing
- Gmail, Outlook, SendGrid integration

### Cron Job Scheduling
- Daily/weekly reports
- Data synchronization
- Social media automation
- Database maintenance
- API monitoring

### Your Specific Use Case
- **10-100 workflows**
- **70+ executions per workflow/month**
- **Total: 700-7,000 executions/month**

This is well within the Always Free tier capabilities!

## Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment guide (14 steps)
- **[n8n Official Docs](https://docs.n8n.io/)** - Learn to build workflows
- **[n8n Community](https://community.n8n.io/)** - Get help and share workflows
- **[Workflow Templates](https://n8n.io/workflows/)** - Pre-built automation templates

## Quick Commands

```bash
# Start n8n
cd ~/n8n-docker
docker compose up -d

# Stop n8n
docker compose down

# View logs
docker compose logs -f

# Restart n8n
docker compose restart

# Update n8n to latest version
docker compose pull
docker compose up -d

# Create backup
~/backup-n8n.sh

# Restore from backup
~/restore-n8n.sh

# Check status
docker compose ps
```

## System Requirements

**Oracle Cloud VM:**
- VM.Standard.A1.Flex (ARM)
- Minimum: 2 OCPUs, 12 GB RAM
- Recommended: 4 OCPUs, 24 GB RAM
- 200 GB block storage
- Ubuntu 22.04 or 24.04

**n8n Requirements:**
- ~2 GB RAM for basic usage
- ~4 GB RAM for heavy workflows
- More CPU = faster workflow execution

## Security

- **Firewall**: UFW configured (SSH, HTTP, HTTPS only)
- **SSL/HTTPS**: Free Let's Encrypt certificates
- **Basic Auth**: Username/password protection
- **Regular Updates**: Easy update process
- **Backups**: Automated daily backups

**Security Best Practices:**
1. Use strong passwords (16+ characters)
2. Keep system updated: `sudo apt update && sudo apt upgrade`
3. Monitor logs regularly
4. Use environment variables for secrets
5. Enable 2FA where possible

## Troubleshooting

### Common Issues

**Can't connect to VM:**
- Check Oracle Cloud firewall rules
- Verify Ubuntu UFW: `sudo ufw status`
- Check SSH key permissions: `chmod 600 ~/.ssh/key`

**n8n not loading:**
- Check containers: `docker ps`
- View logs: `docker compose logs -f`
- Verify DNS propagation: `ping yourdomain.com`

**SSL certificate errors:**
- Ensure domain points to correct IP
- Wait 5-30 minutes for DNS propagation
- Test renewal: `sudo certbot renew --dry-run`

**Out of disk space:**
```bash
docker system prune -a  # Remove unused images
docker volume prune     # Remove unused volumes
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for more troubleshooting tips.

## Support

- **Issues**: [Open an issue](https://github.com/YohayBar/soloble-n8n/issues)
- **n8n Community**: https://community.n8n.io/
- **Oracle Cloud Docs**: https://docs.oracle.com/cloud/

## Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest improvements
- Submit pull requests
- Share your experience

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [n8n.io](https://n8n.io/) - Amazing workflow automation platform
- [Oracle Cloud](https://www.oracle.com/cloud/free/) - Generous Always Free tier
- Community contributors and testers

---

**Enjoy your free workflow automation platform! 🚀**

Questions? Check the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) or open an issue.
