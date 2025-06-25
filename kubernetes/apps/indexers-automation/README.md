# Indexers and Automation Stack

The final piece of the homelab automation puzzle - centralized indexer management and intelligent content requests to complete your fully automated media ecosystem.

## Components

### Indexer Management
- **Prowlarr v1.21**: Centralized indexer management for all *arr applications
- **URL**: https://prowlarr.k8s.dttesting.com
- **Features**: Multi-indexer sync, API key management, search aggregation

### Request Management
- **Overseerr v1.33**: Beautiful media request and discovery platform
- **URL**: https://overseerr.k8s.dttesting.com
- **Features**: Plex integration, user management, automated approvals

### Cloudflare Bypass
- **FlareSolverr v3**: Cloudflare and DDoS-GUARD bypass solution
- **Internal Service**: `flaresolverr.automation.svc.cluster.local:8191`
- **Features**: Automated CAPTCHA solving, proxy support

## Storage Configuration

### Application Data
- **Prowlarr Config**: 5GB for indexer configurations, API keys, and logs
- **Overseerr Config**: 2GB for user data, requests, and media database

### No Media Storage Required
These applications manage metadata and requests only - no direct media storage needed.

## Architecture Overview

```
User Request (Overseerr) 
    ↓
*arr Applications (Sonarr/Radarr/etc)
    ↓
Prowlarr (Indexer Search)
    ↓
Download Clients (qBittorrent/NZBget)
    ↓
Media Storage & Processing
```

## Initial Configuration

### Prowlarr Setup
**Access**: https://prowlarr.k8s.dttesting.com

#### First-Time Configuration
1. **Authentication**: Set up authentication in Settings → General
2. **Indexers**: Add your torrent and usenet indexers
3. **Applications**: Connect to all *arr applications
4. **FlareSolverr**: Configure for Cloudflare-protected indexers

#### *arr Application Integration
Configure each *arr app to sync with Prowlarr:

**Sync Settings**:
- **Sonarr**: `http://sonarr.media.svc.cluster.local:8989`
- **Radarr**: `http://radarr.media.svc.cluster.local:7878`
- **Lidarr**: `http://lidarr.media.svc.cluster.local:8686`
- **Readarr**: `http://readarr.media.svc.cluster.local:8787`

#### Indexer Categories
- **Movies**: 2000-2999
- **TV**: 5000-5999
- **Music**: 3000-3999
- **Books**: 8000-8999
- **XXX**: 6000-6999

### Overseerr Setup
**Access**: https://overseerr.k8s.dttesting.com

#### Initial Configuration Wizard
1. **Plex Server**: Connect to your Plex Media Server
2. **Libraries**: Select which libraries to monitor
3. **Admin Account**: Set up the primary admin user
4. ***arr Integration**: Configure Sonarr and Radarr connections

#### *arr Application Setup
**Radarr Configuration**:
- **Server**: `http://radarr.media.svc.cluster.local:7878`
- **API Key**: Generate in Radarr Settings → General
- **Quality Profile**: Select default quality profile
- **Root Folder**: `/media/movies`

**Sonarr Configuration**:
- **Server**: `http://sonarr.media.svc.cluster.local:8989`
- **API Key**: Generate in Sonarr Settings → General
- **Quality Profile**: Select default quality profile
- **Root Folder**: `/media/tv`
- **Season Folder**: Enable season folders

#### User Management
- **User Roles**: Admin, User, Local User
- **Request Limits**: Set daily/weekly request quotas
- **Auto-Approval**: Configure automatic approval rules
- **Notifications**: Set up Discord, email, or other notifications

### FlareSolverr Integration

#### Prowlarr FlareSolverr Setup
1. **Settings → Indexers → Add FlareSolverr**:
   - **Name**: FlareSolverr
   - **Host**: `http://flaresolverr.automation.svc.cluster.local:8191`
   - **Test**: Verify connectivity

2. **Configure Protected Indexers**:
   - **Select indexers** that use Cloudflare protection
   - **Set FlareSolverr Proxy**: Select configured FlareSolverr instance
   - **Test indexers** to verify bypass functionality

## VPN Integration

### Prowlarr + VPN
Prowlarr is configured with VPN protection:
- **Gluetun Integration**: Routes traffic through VPN
- **IP Protection**: Prevents indexer IP leaks
- **Fail-Safe**: Stops operation if VPN fails

### FlareSolverr + VPN
FlareSolverr also routes through VPN:
- **Consistent IP**: Same IP as other download traffic
- **Enhanced Privacy**: Cloudflare bypass through VPN
- **Reduced Detection**: Consistent geographic location

## Automation Workflows

### Movie Request Flow
1. **User** searches and requests movie in Overseerr
2. **Overseerr** automatically sends request to Radarr
3. **Radarr** searches through Prowlarr indexers
4. **Prowlarr** aggregates results from all configured indexers
5. **Radarr** selects best release and sends to download client
6. **Download client** downloads via VPN protection
7. **Radarr** processes and moves to media library
8. **Overseerr** notifies user of availability

### TV Show Request Flow
1. **User** requests TV show or specific episodes in Overseerr
2. **Overseerr** sends series request to Sonarr
3. **Sonarr** monitors for new episodes automatically
4. **Prowlarr** provides indexer search capabilities
5. **Automatic downloads** for monitored episodes
6. **Season pack optimization** for efficient downloading
7. **Episode processing** and library organization

### Quality Management
- **Prowlarr**: Filters releases by size, format, and quality
- ***arr Apps**: Apply quality profiles and upgrade rules
- **Download Clients**: Handle prioritization and bandwidth management
- **Post-Processing**: Automatic quality verification and organization

## Advanced Features

### Custom Filters (Prowlarr)
```yaml
# Size filters
minimum_size: 100MB
maximum_size: 50GB

# Quality filters
preferred_formats:
  - WEB-DL
  - BluRay
  - REMUX

# Language preferences
languages:
  - English
  - Multi
```

### Request Rules (Overseerr)
- **Auto-Approval**: Based on user role and content rating
- **Request Limits**: Daily/weekly quotas per user
- **Content Filtering**: Block specific content types
- **Seasonal Rules**: Different approval rules for different times

### Monitoring and Analytics
- **Request Statistics**: Track popular content and user activity
- **Indexer Performance**: Monitor search success rates
- **Download Metrics**: Track completion rates and speeds
- **User Engagement**: Analyze request patterns and preferences

## Security and Privacy

### Access Control
- **Overseerr**: User authentication with role-based permissions
- **Prowlarr**: Admin-only access with secure API keys
- **FlareSolverr**: Internal service only, no external access

### Data Protection
- **VPN Routing**: All indexer traffic through VPN tunnel
- **API Security**: Secure API key management across applications
- **Request Logging**: Configurable logging levels for privacy
- **User Data**: Encrypted configuration storage

### Network Security
- **Internal Communication**: All inter-service communication within cluster
- **TLS Encryption**: HTTPS access for all public endpoints
- **Firewall Rules**: Restricted external access to essential ports only

## Monitoring and Troubleshooting

### Health Checks
```bash
# Check all automation services
kubectl get pods -n automation

# Monitor application logs
kubectl logs -n automation deployment/prowlarr -f
kubectl logs -n automation deployment/overseerr -f
kubectl logs -n automation deployment/flaresolverr -f

# Test VPN connectivity
kubectl exec -n automation deployment/prowlarr -- curl ifconfig.me
```

### Performance Monitoring
```bash
# Check resource usage
kubectl top pods -n automation

# Monitor storage usage
kubectl exec -n automation deployment/prowlarr -- df -h /config
kubectl exec -n automation deployment/overseerr -- df -h /config

# Test FlareSolverr functionality
kubectl exec -n automation deployment/flaresolverr -- curl -X POST http://localhost:8191/v1 \
  -H "Content-Type: application/json" \
  -d '{"cmd": "request.get", "url": "http://httpbin.org/ip"}'
```

### Common Issues

#### Indexer Connection Problems
```bash
# Check indexer connectivity from Prowlarr
kubectl exec -n automation deployment/prowlarr -- nslookup indexer-domain.com

# Verify VPN is working
kubectl exec -n automation deployment/prowlarr -- curl ifconfig.me

# Test FlareSolverr integration
curl -X POST https://prowlarr.k8s.dttesting.com/api/v1/indexer/test
```

#### Overseerr Integration Issues
```bash
# Check *arr application connectivity
kubectl exec -n automation deployment/overseerr -- curl http://radarr.media.svc.cluster.local:7878/api/v3/system/status

# Verify Plex connectivity
kubectl logs -n automation deployment/overseerr | grep -i plex

# Test request processing
kubectl logs -n automation deployment/overseerr | grep -i request
```

## Backup and Recovery

### Configuration Backup
```bash
# Backup Prowlarr configuration
kubectl exec -n automation deployment/prowlarr -- tar -czf - /config > prowlarr-config-backup.tar.gz

# Backup Overseerr configuration
kubectl exec -n automation deployment/overseerr -- tar -czf - /config > overseerr-config-backup.tar.gz
```

### Database Export
```bash
# Export Prowlarr database
kubectl exec -n automation deployment/prowlarr -- sqlite3 /config/prowlarr.db .dump > prowlarr-db.sql

# Export Overseerr database
kubectl exec -n automation deployment/overseerr -- sqlite3 /config/db/db.sqlite3 .dump > overseerr-db.sql
```

## Performance Optimization

### Prowlarr Optimization
- **Indexer Priorities**: Set preferred indexers for faster searches
- **Search Limits**: Configure reasonable timeout and retry values
- **Caching**: Enable result caching for frequently searched content
- **Rate Limiting**: Respect indexer rate limits to avoid bans

### Overseerr Optimization
- **Plex Sync**: Optimize library scan frequency
- **Request Processing**: Configure batch processing for efficiency
- **User Limits**: Set appropriate request quotas
- **Notification Batching**: Group notifications to reduce spam

### FlareSolverr Optimization
- **Session Management**: Configure session recycling
- **Browser Settings**: Optimize headless browser performance
- **Memory Management**: Monitor and limit browser memory usage
- **Concurrent Requests**: Balance performance vs resource usage

This indexers and automation stack completes your ultimate homelab setup with intelligent content discovery, centralized indexer management, and beautiful request interfaces for users. The full automation pipeline is now complete from request to delivery!