# Media Management Stack

Complete *arr stack for managing your entertainment collection with automatic downloads, organization, and quality management.

## Components

### TV Shows Management
- **Sonarr v4**: TV show collection manager with automatic series monitoring
- **URL**: https://sonarr.k8s.dttesting.com
- **Features**: Episode tracking, quality profiles, release monitoring

### Movie Management  
- **Radarr v5**: Movie collection manager with automatic film monitoring
- **URL**: https://radarr.k8s.dttesting.com
- **Features**: Movie tracking, quality profiles, collection management

### Music Management
- **Lidarr v2**: Music collection manager for artists and albums
- **URL**: https://lidarr.k8s.dttesting.com
- **Features**: Artist monitoring, album tracking, metadata management

### Subtitle Management
- **Bazarr v1**: Automatic subtitle download and management
- **URL**: https://bazarr.k8s.dttesting.com
- **Features**: Multi-language subtitles, integration with Sonarr/Radarr

### Book Management
- **Readarr v0.3**: Book and audiobook collection manager
- **URL**: https://readarr.k8s.dttesting.com
- **Features**: Author monitoring, book tracking, format preferences

## Storage Configuration

### Application Data
- **Sonarr Config**: 5GB for database, settings, and metadata
- **Radarr Config**: 5GB for database, settings, and metadata
- **Lidarr Config**: 5GB for database, settings, and metadata
- **Bazarr Config**: 2GB for subtitle cache and settings
- **Readarr Config**: 5GB for database, settings, and metadata

### Media Storage
- **Shared Media Volume**: 10TB ReadWriteMany for all media content
- **Structure**:
  ```
  /media/
  ├── tv/           # TV shows organized by series
  ├── movies/       # Movies organized by title (year)
  ├── music/        # Music organized by artist/album
  ├── books/        # Books and audiobooks
  └── downloads/    # Temporary download staging area
  ```

## Initial Configuration

### Access Setup
All applications use the same user credentials:
- **User ID (PUID)**: 1000
- **Group ID (PGID)**: 1000
- **Timezone**: America/New_York
- **Umask**: 022 (proper file permissions)

### First-Time Setup
1. **Access each application** via their respective URLs
2. **Run initial setup wizard** for each service
3. **Configure media paths**:
   - TV Shows: `/media/tv`
   - Movies: `/media/movies`
   - Music: `/media/music`
   - Books: `/media/books`
4. **Set download client** paths to `/downloads`

## Integration Configuration

### Download Client Integration
Configure each *arr app to use your download clients:
1. **Settings → Download Clients**
2. **Add download client** (qBittorrent, NZBget, etc.)
3. **Set download directory** to `/downloads`
4. **Configure category mappings**:
   - Sonarr: `tv-sonarr`
   - Radarr: `movies-radarr`
   - Lidarr: `music-lidarr`
   - Readarr: `books-readarr`

### Indexer Setup
1. **Settings → Indexers**
2. **Add indexers** for content discovery
3. **Configure API keys** for private trackers
4. **Set search preferences** and rate limits

### Quality Profiles
Set up quality profiles for each media type:

#### Sonarr TV Quality Profile
- **4K HDR**: WEBDL-2160p, Bluray-2160p
- **1080p**: WEBDL-1080p, Bluray-1080p, HDTV-1080p
- **720p**: WEBDL-720p, Bluray-720p, HDTV-720p

#### Radarr Movie Quality Profile
- **4K**: WEBDL-2160p, Bluray-2160p, Remux-2160p
- **1080p**: WEBDL-1080p, Bluray-1080p, Remux-1080p
- **720p**: WEBDL-720p, Bluray-720p

#### Lidarr Music Quality Profile
- **Lossless**: FLAC, ALAC
- **High Quality**: MP3-320, MP3-V0
- **Standard**: MP3-256, MP3-192

### Bazarr Subtitle Configuration
1. **Connect to Sonarr and Radarr**:
   - Sonarr URL: `http://sonarr:8989`
   - Radarr URL: `http://radarr:7878`
   - API Keys: Generate in each application
2. **Configure subtitle providers**
3. **Set language preferences**
4. **Enable automatic subtitle download**

## Media Organization

### Naming Conventions
Configure consistent naming in each application:

#### Sonarr TV Shows
```
Series Folder: {Series Title} ({Series Year})
Season Folder: Season {season:00}
Episode File: {Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}
```

#### Radarr Movies
```
Movie Folder: {Movie Title} ({Release Year})
Movie File: {Movie Title} ({Release Year}) {Quality Full}
```

#### Lidarr Music
```
Artist Folder: {Artist Name}
Album Folder: {Album Title} ({Release Year})
Track File: {track:00} - {Track Title}
```

### Import Settings
- **Use hardlinks** when possible to save space
- **Monitor existing files** for upgrades
- **Set minimum availability** for new releases
- **Configure retention policies** for downloads

## Monitoring and Automation

### Release Monitoring
- **Sonarr**: Monitor future episodes and missing seasons
- **Radarr**: Monitor upcoming movies and missing collections
- **Lidarr**: Monitor new releases from followed artists
- **Readarr**: Monitor new books from followed authors

### Quality Upgrades
- **Enable automatic upgrades** when better quality becomes available
- **Set cutoff quality** to prevent endless upgrading
- **Configure score-based selection** for release preferences

### Health Monitoring
Each application provides health checks:
- **System → Status**: Overall application health
- **System → Tasks**: Background task monitoring
- **System → Logs**: Detailed logging for troubleshooting

## Backup and Recovery

### Configuration Backup
```bash
# Backup all *arr configurations
kubectl exec -n media deployment/sonarr -- tar -czf - /config > sonarr-config-backup.tar.gz
kubectl exec -n media deployment/radarr -- tar -czf - /config > radarr-config-backup.tar.gz
kubectl exec -n media deployment/lidarr -- tar -czf - /config > lidarr-config-backup.tar.gz
kubectl exec -n media deployment/bazarr -- tar -czf - /config > bazarr-config-backup.tar.gz
kubectl exec -n media deployment/readarr -- tar -czf - /config > readarr-config-backup.tar.gz
```

### Database Export
```bash
# Export databases for each application
kubectl exec -n media deployment/sonarr -- sqlite3 /config/sonarr.db .dump > sonarr-db.sql
kubectl exec -n media deployment/radarr -- sqlite3 /config/radarr.db .dump > radarr-db.sql
kubectl exec -n media deployment/lidarr -- sqlite3 /config/lidarr.db .dump > lidarr-db.sql
```

## Troubleshooting

### Common Issues

#### Download Client Connection
```bash
# Check download client connectivity
kubectl exec -n media deployment/sonarr -- ping qbittorrent
kubectl exec -n media deployment/radarr -- nslookup nzbget

# Verify download paths are accessible
kubectl exec -n media deployment/sonarr -- ls -la /downloads
```

#### Permission Issues
```bash
# Check file permissions on media storage
kubectl exec -n media deployment/sonarr -- ls -la /media
kubectl exec -n media deployment/radarr -- id

# Fix permissions if needed
kubectl exec -n media deployment/sonarr -- chown -R 1000:1000 /media
```

#### Application Startup Issues
```bash
# Check application logs
kubectl logs -n media deployment/sonarr -f
kubectl logs -n media deployment/radarr -f

# Check resource usage
kubectl top pods -n media

# Restart problematic applications
kubectl rollout restart deployment/sonarr -n media
```

#### Database Corruption
```bash
# Check database integrity
kubectl exec -n media deployment/sonarr -- sqlite3 /config/sonarr.db "PRAGMA integrity_check;"

# Backup and repair if needed
kubectl exec -n media deployment/sonarr -- cp /config/sonarr.db /config/sonarr.db.backup
kubectl exec -n media deployment/sonarr -- sqlite3 /config/sonarr.db ".backup /config/sonarr-repair.db"
```

## Performance Optimization

### Resource Allocation
- **Sonarr/Radarr**: 2GB RAM, 1 CPU core for large libraries
- **Lidarr/Readarr**: 1GB RAM, 0.5 CPU core for moderate usage
- **Bazarr**: 512MB RAM, 0.5 CPU core for subtitle processing

### Database Optimization
- **Regular maintenance**: Vacuum databases monthly
- **Index optimization**: Let applications manage indexes
- **Log rotation**: Configure appropriate log retention

### Network Optimization
- **Use internal Kubernetes DNS** for service communication
- **Configure connection pooling** for database access
- **Implement rate limiting** for indexer requests

## Security Considerations

### Network Security
- **Internal service communication** uses cluster networking
- **External access** secured with TLS certificates
- **API keys** stored securely and rotated regularly

### Access Control
- **Web UI authentication** should be configured in each app
- **Reverse proxy** handles TLS termination
- **Network policies** can restrict inter-pod communication

### Data Protection
- **Regular configuration backups** to prevent data loss
- **Media file checksums** for integrity verification
- **Encrypted storage** for sensitive configuration data

This media management stack provides comprehensive automation for your entertainment collection with proper organization, quality management, and integration capabilities.