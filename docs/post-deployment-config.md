# Post-Deployment Configuration Guide

This guide covers the essential configuration steps to set up your Ultimate Life Automation Platform after successful deployment.

## Table of Contents
- [Access and Initial Setup](#access-and-initial-setup)
- [Security Configuration](#security-configuration)
- [Media Management Setup](#media-management-setup)
- [Download Client Configuration](#download-client-configuration)
- [Notification Setup](#notification-setup)
- [Document Management Configuration](#document-management-configuration)
- [Household Management Setup](#household-management-setup)
- [Monitoring and Alerts](#monitoring-and-alerts)
- [VPN Configuration](#vpn-configuration)
- [Backup and Maintenance](#backup-and-maintenance)

## Access and Initial Setup

### Primary Dashboard Access
- **Homer Dashboard**: https://homer.k8s.dttesting.com
- **Portainer Management**: https://portainer.k8s.dttesting.com
- **ArgoCD GitOps**: https://argocd.k8s.dttesting.com

### Change Default Passwords

**Priority 1 - ArgoCD Admin Password**:
```bash
# Get current admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login to ArgoCD UI with admin and the password above
# Go to User Info → Update Password
# Set a strong permanent password
```

**Priority 2 - Application Passwords**:
1. **Grafana**: https://grafana.k8s.dttesting.com (admin / admin123!)
2. **qBittorrent**: https://qbittorrent.k8s.dttesting.com (admin / adminadmin)
3. **NZBget**: https://nzbget.k8s.dttesting.com (admin / admin123!)
4. **Overseerr**: https://overseerr.k8s.dttesting.com (setup wizard)
5. **Paperless-ngx**: https://paperless.k8s.dttesting.com (admin / admin123!)
6. **Grocy**: https://grocy.k8s.dttesting.com (no auth by default)

## Security Configuration

### 1. Configure VPN Settings

**Get Gluetun VPN Configuration**:
```bash
# Check current VPN status
kubectl logs -n gluetun deployment/gluetun --tail=20

# Update VPN provider settings
kubectl edit configmap gluetun-config -n gluetun
```

Required VPN settings:
- **VPN_SERVICE_PROVIDER**: Your VPN provider (surfshark, nordvpn, etc.)
- **VPN_TYPE**: openvpn or wireguard
- **OPENVPN_USER**: Your VPN username
- **OPENVPN_PASSWORD**: Your VPN password
- **SERVER_REGIONS**: Preferred server regions

### 2. SSL Certificate Verification

Check all certificates are working:
```bash
# Verify certificates
kubectl get certificates -A

# Check certificate status
kubectl describe certificate -A | grep -A 5 -B 5 "Ready: False"
```

### 3. Enable Application Authentication

**Configure Grocy Authentication**:
1. Access https://grocy.k8s.dttesting.com
2. Go to Settings → User Management
3. Enable authentication and create admin user

**Secure Portainer**:
1. Access https://portainer.k8s.dttesting.com
2. Create admin account on first access
3. Configure environment access

## Media Management Setup

### 1. Configure Storage Paths

All media applications share common storage paths:
- **TV Shows**: `/media/tv`
- **Movies**: `/media/movies`
- **Music**: `/media/music`
- **Books**: `/media/books`
- **Downloads**: `/downloads`

### 2. Set Up Quality Profiles

**Sonarr Configuration**:
1. Access https://sonarr.k8s.dttesting.com
2. Settings → Profiles → Add Quality Profile
3. Recommended profile: `WEBDL-1080p` > `HDTV-1080p` > `WEBDL-720p`
4. Settings → Media Management:
   - Show folder format: `{Series Title} ({Series Year})`
   - Season folder format: `Season {season:00}`
   - Episode file format: `{Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}`

**Radarr Configuration**:
1. Access https://radarr.k8s.dttesting.com
2. Settings → Profiles → Add Quality Profile
3. Recommended profile: `WEBDL-1080p` > `Bluray-1080p` > `WEBDL-720p`
4. Settings → Media Management:
   - Movie folder format: `{Movie Title} ({Release Year})`
   - Movie file format: `{Movie Title} ({Release Year}) {Quality Full}`

### 3. Configure Root Folders

For each *arr application:
1. Settings → Media Management → Root Folders
2. Add root folder pointing to appropriate media directory
3. Test accessibility and permissions

## Download Client Configuration

### 1. qBittorrent Setup

**Initial Configuration**:
1. Access https://qbittorrent.k8s.dttesting.com
2. Login with admin / adminadmin (change password immediately)
3. Options → Downloads:
   - Default save path: `/downloads`
   - Keep incomplete downloads in: `/incomplete-downloads/qbittorrent`
   - Default Torrent Management Mode: Manual

**Categories Setup**:
1. Right-click in torrents area → Add Category
2. Create categories:
   - `movies-radarr` → `/downloads/movies`
   - `tv-sonarr` → `/downloads/tv`
   - `music-lidarr` → `/downloads/music`
   - `books-readarr` → `/downloads/books`

### 2. NZBget Setup

**Basic Configuration**:
1. Access https://nzbget.k8s.dttesting.com
2. Login with admin / admin123! (change password)
3. Settings → Paths:
   - MainDir: `/downloads`
   - InterDir: `/incomplete-downloads/nzbget`
   - NzbDir: `/config/nzb`
   - QueueDir: `/config/queue`

**Add Usenet Server**:
1. Settings → News-Servers → Add Server
2. Configure your usenet provider settings
3. Test connection

### 3. Connect Download Clients to *arr Apps

**For each *arr application**:
1. Settings → Download Clients → Add Download Client
2. **qBittorrent settings**:
   - Host: `qbittorrent.downloads.svc.cluster.local`
   - Port: `8080`
   - Username: admin
   - Password: [your password]
   - Category: [appropriate category]
3. **NZBget settings**:
   - Host: `nzbget.downloads.svc.cluster.local`
   - Port: `6789`
   - Username: admin
   - Password: [your password]

## Notification Setup

### 1. Configure Notifiarr

**Get Notifiarr API Key**:
1. Visit https://notifiarr.com
2. Sign up/login with Discord
3. Generate API key in dashboard

**Update Notifiarr Configuration**:
```bash
# Edit the secret
kubectl edit secret notifiarr-secrets -n notifications

# Update DN_API_KEY with your actual API key
# Restart Notifiarr
kubectl rollout restart deployment/notifiarr -n notifications
```

### 2. Get API Keys from Applications

**For each *arr application**:
1. Go to Settings → General
2. Copy API Key
3. Update Notifiarr environment variables:

```bash
kubectl edit deployment notifiarr -n notifications
# Update environment variables:
# DN_SONARR_0_API_KEY
# DN_RADARR_0_API_KEY
# DN_LIDARR_0_API_KEY
# DN_READARR_0_API_KEY
```

### 3. Set Up Discord Notifications

**Create Discord Webhook**:
1. In Discord, go to Server Settings → Integrations → Webhooks
2. Create New Webhook
3. Copy webhook URL
4. Update Notifiarr secret:
```bash
kubectl edit secret notifiarr-secrets -n notifications
# Add DN_DISCORD_WEBHOOK: "your-webhook-url"
```

## Document Management Configuration

### 1. Paperless-ngx Setup

**Initial Configuration**:
1. Access https://paperless.k8s.dttesting.com
2. Login with admin / admin123! (change password)
3. Settings → General:
   - Set application URL to https://paperless.k8s.dttesting.com
   - Configure timezone
   - Set up OCR languages

**Document Scanning Setup**:
1. Settings → Document Scanner
2. Configure scanner settings for your setup
3. Test with sample document upload

### 2. Set Up Document Categories

1. Documents → Document Types → Add
2. Create types: Bills, Contracts, Receipts, Insurance, etc.
3. Set up tags for organization
4. Configure correspondents (banks, utilities, etc.)

## Household Management Setup

### 1. Grocy Initial Configuration

**Basic Setup**:
1. Access https://grocy.k8s.dttesting.com
2. Settings → User Settings:
   - Configure currency (USD)
   - Set default location
   - Configure date/time format

**Product Database Setup**:
1. Stock → Products → Add Product
2. Start with common items:
   - Milk, Bread, Eggs (with barcodes if available)
   - Cleaning supplies
   - Personal care items

### 2. Shopping List Configuration

1. Stock → Locations → Add locations:
   - Fridge
   - Pantry
   - Freezer
   - Cleaning supplies
2. Configure minimum stock levels for automatic shopping list generation

## Monitoring and Alerts

### 1. Grafana Dashboard Setup

**Access and Configure**:
1. Access https://grafana.k8s.dttesting.com
2. Login with admin / admin123! (change password)
3. Pre-configured dashboards should be available
4. Import additional dashboards:
   - Node Exporter Full (ID: 1860)
   - Kubernetes Cluster Monitoring (ID: 7249)

### 2. Set Up Alerting

**Configure Alert Channels**:
1. Alerting → Notification Channels → Add Channel
2. Set up Discord, Email, or other preferred notification method
3. Test notifications

**Create Alert Rules**:
1. Create alerts for:
   - High CPU usage (>80%)
   - High memory usage (>90%)
   - Low disk space (<10%)
   - Application downtime

## VPN Configuration

### 1. Verify VPN Connectivity

**Test VPN from Download Clients**:
```bash
# Test IP from qBittorrent
kubectl exec -n downloads deployment/qbittorrent -- curl ifconfig.me

# Test IP from Prowlarr
kubectl exec -n automation deployment/prowlarr -- curl ifconfig.me

# Both should show your VPN IP, not your real IP
```

### 2. Configure VPN Kill Switch

Ensure applications stop if VPN fails:
1. Check Gluetun kill switch is enabled
2. Test by stopping Gluetun and verifying downloads stop

## Backup and Maintenance

### 1. Essential Backups

**Database Backups**:
```bash
# Paperless-ngx database
kubectl exec -n paperless deployment/postgres -- pg_dump -U paperless paperless > paperless-backup.sql

# Backup application configurations
kubectl exec -n media deployment/sonarr -- tar -czf - /config > sonarr-config-backup.tar.gz
```

**Configuration Backup Script**:
```bash
#!/bin/bash
# Create comprehensive backup
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="homelab-backup-$BACKUP_DATE"

mkdir -p $BACKUP_DIR

# Backup important configurations
kubectl get secret -A -o yaml > $BACKUP_DIR/all-secrets.yaml
kubectl get configmap -A -o yaml > $BACKUP_DIR/all-configmaps.yaml
kubectl get pvc -A -o yaml > $BACKUP_DIR/all-pvcs.yaml

# Create archive
tar -czf homelab-backup-$BACKUP_DATE.tar.gz $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "Backup created: homelab-backup-$BACKUP_DATE.tar.gz"
```

### 2. Maintenance Schedule

**Weekly Tasks**:
- Check application health in Grafana
- Review download activity and clean up completed downloads
- Update shopping lists in Grocy

**Monthly Tasks**:
- Update application passwords and API keys
- Review and clean up old media files
- Check storage usage and expand if needed
- Test backup and restore procedures

**Quarterly Tasks**:
- Review and update VPN configuration
- Update certificate management
- Performance optimization review
- Security audit and updates

## Integration Testing

### 1. Test Complete Media Pipeline

1. **Request Content**: Use Overseerr to request a movie/TV show
2. **Verify Search**: Check Prowlarr finds indexers
3. **Monitor Download**: Verify download starts in qBittorrent/NZBget
4. **Check Processing**: Ensure *arr app processes the download
5. **Confirm Notifications**: Verify Notifiarr sends Discord notification

### 2. Test Document Workflow

1. **Upload Document**: Add document to Paperless-ngx
2. **Verify OCR**: Check text extraction works
3. **Test Search**: Search for document content
4. **Check Classification**: Verify automatic tagging

### 3. Test Household Management

1. **Add Product**: Create product in Grocy with barcode
2. **Consume Item**: Use mobile interface to consume stock
3. **Check Shopping List**: Verify item appears when below minimum
4. **Plan Meal**: Create recipe and add to meal plan

## Advanced Configuration

### 1. Mobile Access Optimization

- Configure responsive designs for mobile use
- Set up mobile bookmarks for quick access
- Test barcode scanning in Grocy
- Verify mobile notifications work

### 2. Family User Management

- Set up user accounts in applications that support it
- Configure appropriate permissions
- Create family-friendly dashboards
- Set up separate notification preferences

### 3. Performance Optimization

- Monitor resource usage in Grafana
- Adjust resource limits based on actual usage
- Optimize storage performance
- Configure application-specific performance settings

This configuration guide ensures your Ultimate Life Automation Platform is fully functional and secure. Take your time with each section and test thoroughly before moving to the next.