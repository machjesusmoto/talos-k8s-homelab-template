# Download Clients Stack

Complete download automation with both torrent and usenet clients, designed for seamless integration with media management applications.

## Components

### Torrent Client
- **qBittorrent v4.6**: Modern BitTorrent client with web interface
- **URL**: https://qbittorrent.k8s.dttesting.com
- **Features**: RSS feeds, search plugins, sequential downloading, IP filtering

### Usenet Client
- **NZBget v21**: High-performance binary newsreader
- **URL**: https://nzbget.k8s.dttesting.com
- **Features**: Multi-threaded downloading, post-processing, duplicate detection

## Storage Configuration

### Download Storage
- **Active Downloads**: 5TB ReadWriteMany for completed downloads
- **Incomplete Downloads**: 2TB ReadWriteMany for in-progress downloads
- **qBittorrent Config**: 5GB for settings, RSS feeds, and search plugins
- **NZBget Config**: 2GB for configuration and scripts

### Directory Structure
```
/downloads/                    # Completed downloads
├── movies/                    # Movie downloads
├── tv/                        # TV show downloads
├── music/                     # Music downloads
├── books/                     # Book/audiobook downloads
└── manual/                    # Manual downloads

/incomplete-downloads/         # In-progress downloads
├── qbittorrent/              # qBittorrent working directory
└── nzbget/                   # NZBget intermediate directory
```

## VPN Integration

Both download clients are configured with Gluetun VPN integration:
- **VPN Protection**: All traffic routed through VPN tunnel
- **Kill Switch**: Downloads stop if VPN connection fails
- **IP Verification**: Built-in IP leak protection
- **Provider Support**: Works with major VPN providers

### VPN Configuration
The download clients include gluetun annotations:
```yaml
annotations:
  gluetun.io/enabled: "true"
```

## Initial Setup

### qBittorrent Configuration
**Access**: https://qbittorrent.k8s.dttesting.com
**Default Login**: admin / adminadmin (change immediately)

#### Essential Settings
1. **Downloads**:
   - Default save path: `/downloads`
   - Incomplete downloads: `/incomplete-downloads/qbittorrent`
   - Enable "Keep incomplete torrents in"

2. **Connection**:
   - Port: 6881 (both TCP/UDP)
   - Enable UPnP/NAT-PMP: Disabled (using VPN)
   - Use different port on each startup: Disabled

3. **Speed Limits**:
   - Global download limit: Configure based on connection
   - Global upload limit: Configure based on upload capacity
   - Alternative rate limits: For scheduling

4. **BitTorrent**:
   - Enable DHT, PeX, and LSD
   - Encryption: Require encryption
   - Maximum ratio: 2.0 (or as preferred)

#### Category Setup
Configure categories for *arr integration:
- **movies-radarr**: `/downloads/movies`
- **tv-sonarr**: `/downloads/tv`
- **music-lidarr**: `/downloads/music`
- **books-readarr**: `/downloads/books`

### NZBget Configuration
**Access**: https://nzbget.k8s.dttesting.com
**Default Login**: admin / admin123! (change in deployment)

#### Essential Settings
1. **Paths**:
   - MainDir: `/downloads`
   - InterDir: `/intermediate`
   - TempDir: `/intermediate/tmp`
   - QueueDir: `/config/queue`

2. **News Servers**:
   - Add your usenet provider settings
   - Configure SSL connection (port 563)
   - Set retention period and connections

3. **Categories**:
   - **movies**: `/downloads/movies`
   - **tv**: `/downloads/tv`
   - **music**: `/downloads/music`
   - **books**: `/downloads/books`

4. **Post-Processing**:
   - Enable unpack scripts
   - Configure cleanup settings
   - Set up notification scripts

## Integration with *arr Applications

### qBittorrent Integration
Configure in each *arr application:

#### Download Client Settings
- **Name**: qBittorrent
- **Host**: `qbittorrent.downloads.svc.cluster.local`
- **Port**: 8080
- **Username**: admin
- **Password**: [configured password]
- **Category**: [app-specific category]
- **Directory**: `/downloads/[media-type]`

### NZBget Integration
Configure in each *arr application:

#### Download Client Settings
- **Name**: NZBget
- **Host**: `nzbget.downloads.svc.cluster.local`
- **Port**: 6789
- **Username**: admin
- **Password**: admin123!
- **Category**: [app-specific category]
- **Directory**: `/downloads/[media-type]`

## Performance Optimization

### qBittorrent Performance
- **Memory Usage**: 2GB limit with 512MB request
- **CPU Allocation**: 1 CPU core limit for intensive operations
- **Connection Limits**: Configure based on VPN provider limits
- **Disk Cache**: Enable disk cache for better I/O performance

### NZBget Performance
- **Memory Usage**: 1GB limit with 256MB request
- **CPU Allocation**: 0.5 CPU core for decompression
- **Article Connections**: 8-50 connections per server
- **Download Rate**: Configure to match internet connection

### Storage Optimization
- **Hardlinks**: Use hardlinks when possible to save space
- **Cleanup Scripts**: Automatic cleanup of old downloads
- **Monitoring**: Regular disk usage monitoring
- **Compression**: Enable compression for completed downloads

## Security Configuration

### Network Security
- **VPN Enforcement**: All traffic through VPN tunnel
- **Internal Communication**: Kubernetes cluster networking
- **TLS Encryption**: HTTPS access via Traefik
- **Port Isolation**: No direct external port exposure

### Access Control
- **Strong Passwords**: Change default credentials immediately
- **IP Filtering**: Configure IP filtering in qBittorrent
- **Authentication**: Enable authentication for web interfaces
- **Rate Limiting**: Configure download/upload rate limits

### Privacy Protection
- **VPN Always On**: Downloads only work when VPN is active
- **IP Leak Protection**: Built-in leak detection
- **DNS Protection**: Use VPN provider's DNS servers
- **No Logging**: Configure clients for minimal logging

## Monitoring and Maintenance

### Health Monitoring
```bash
# Check download client status
kubectl get pods -n downloads

# Monitor download client logs
kubectl logs -n downloads deployment/qbittorrent -f
kubectl logs -n downloads deployment/nzbget -f

# Check VPN connectivity
kubectl exec -n downloads deployment/qbittorrent -- curl ifconfig.me
```

### Performance Monitoring
```bash
# Check resource usage
kubectl top pods -n downloads

# Monitor storage usage
kubectl exec -n downloads deployment/qbittorrent -- df -h /downloads
kubectl exec -n downloads deployment/nzbget -- df -h /downloads

# Check download speeds
kubectl exec -n downloads deployment/qbittorrent -- curl -s http://localhost:8080/api/v2/transfer/info
```

### Maintenance Tasks
- **Weekly**: Review completed downloads and cleanup
- **Monthly**: Update indexer configurations and test connectivity
- **Quarterly**: Review VPN performance and settings
- **As Needed**: Update download client configurations

## Troubleshooting

### Common Issues

#### VPN Connection Problems
```bash
# Check VPN status
kubectl logs -n gluetun deployment/gluetun

# Test VPN connectivity from download clients
kubectl exec -n downloads deployment/qbittorrent -- curl ifconfig.me
kubectl exec -n downloads deployment/nzbget -- nslookup google.com
```

#### Download Issues
```bash
# Check qBittorrent logs
kubectl logs -n downloads deployment/qbittorrent --tail=50

# Check NZBget logs
kubectl logs -n downloads deployment/nzbget --tail=50

# Verify storage access
kubectl exec -n downloads deployment/qbittorrent -- ls -la /downloads
kubectl exec -n downloads deployment/nzbget -- ls -la /downloads
```

#### Permission Issues
```bash
# Check file permissions
kubectl exec -n downloads deployment/qbittorrent -- ls -la /downloads
kubectl exec -n downloads deployment/nzbget -- id

# Fix permissions if needed
kubectl exec -n downloads deployment/qbittorrent -- chown -R 1000:1000 /downloads
```

#### Storage Full Issues
```bash
# Check disk space
kubectl exec -n downloads deployment/qbittorrent -- df -h

# Clean up old downloads
kubectl exec -n downloads deployment/qbittorrent -- find /downloads -type f -mtime +30 -delete

# Check PVC status
kubectl get pvc -n downloads
```

## Advanced Configuration

### RSS Feed Setup (qBittorrent)
1. **Enable RSS Reader**: Tools → Options → RSS
2. **Add RSS Feeds**: From your favorite trackers
3. **Download Rules**: Automatic download based on patterns
4. **Categories**: Assign categories for automatic organization

### Post-Processing Scripts (NZBget)
- **Cleanup Scripts**: Remove unwanted files
- **Notification Scripts**: Send completion notifications
- **Quality Check Scripts**: Verify download integrity
- **Integration Scripts**: Trigger *arr application imports

### Backup Strategy
```bash
# Backup qBittorrent configuration
kubectl exec -n downloads deployment/qbittorrent -- tar -czf - /config > qbittorrent-config-backup.tar.gz

# Backup NZBget configuration
kubectl exec -n downloads deployment/nzbget -- tar -czf - /config > nzbget-config-backup.tar.gz

# Export download lists
kubectl exec -n downloads deployment/qbittorrent -- curl -s "http://localhost:8080/api/v2/torrents/info" > active-torrents.json
```

This download client stack provides robust, secure, and automated downloading capabilities with full VPN protection and seamless integration with your media management applications.