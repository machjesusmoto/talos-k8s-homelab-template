# Notifiarr - Ultimate Notification Hub

The missing piece! Notifiarr provides comprehensive notifications and monitoring for your entire *arr stack and download ecosystem.

## Overview

**Notifiarr** is a unified notification system that integrates with all your *arr applications, download clients, and media servers to provide real-time alerts and Discord bot functionality.

- **URL**: https://notifiarr.k8s.dttesting.com
- **Login**: Password configured in deployment (notifiarr123!)
- **Official Site**: https://notifiarr.com

## Key Features

### 🔔 **Comprehensive Notifications**
- **Real-time alerts** for downloads, imports, and failures
- **Discord integration** with rich embeds and bot commands
- **Telegram support** for mobile notifications
- **Webhook endpoints** for custom integrations

### 📊 **Application Monitoring**
- **Health checks** for all *arr applications
- **Performance metrics** and error tracking
- **Uptime monitoring** with alerting
- **Service dependency mapping**

### 🤖 **Discord Bot Features**
- **Interactive commands** for managing downloads
- **Status updates** with beautiful embeds
- **User permissions** and role-based access
- **Custom triggers** and automated responses

### 📈 **Analytics & Reporting**
- **Download statistics** across all clients
- **Quality metrics** and completion rates
- **User activity tracking** (via Overseerr integration)
- **Historical data** and trending analysis

## Integrations Configured

### *arr Applications
- **Sonarr**: TV show notifications and management
- **Radarr**: Movie notifications and management
- **Lidarr**: Music notifications and management
- **Readarr**: Book notifications and management

### Download Clients
- **qBittorrent**: Torrent download status and control
- **NZBget**: Usenet download status and control

### Media Servers (Optional)
- **Plex**: Library updates and user activity
- **Tautulli**: Advanced Plex analytics integration

### External Services
- **Discord**: Rich notifications and bot functionality
- **Telegram**: Mobile notifications and alerts
- **Webhooks**: Custom integrations and automation

## Initial Setup

### 1. Get Notifiarr API Key
1. **Visit**: https://notifiarr.com
2. **Sign up/Login** with Discord account
3. **Generate API key** in your dashboard
4. **Update the secret**:
   ```bash
   kubectl edit secret notifiarr-secrets -n notifications
   # Replace: DN_API_KEY: "your-notifiarr-api-key-here"
   ```

### 2. Configure API Keys
You'll need to gather API keys from each application:

#### *arr Applications
```bash
# Get API keys from each *arr app Settings → General
# Sonarr: http://sonarr.k8s.dttesting.com/settings/general
# Radarr: http://radarr.k8s.dttesting.com/settings/general
# Lidarr: http://lidarr.k8s.dttesting.com/settings/general
# Readarr: http://readarr.k8s.dttesting.com/settings/general
```

#### Download Clients
```bash
# qBittorrent: Get password from web UI settings
# NZBget: Already configured with admin123!
```

### 3. Discord Integration
1. **Create Discord webhook** in your server
2. **Update webhook URL** in notifiarr-secrets
3. **Configure bot permissions** in Notifiarr dashboard
4. **Test notifications** with a download

### 4. Update Configuration
```bash
# Edit the deployment to add your API keys
kubectl edit deployment notifiarr -n notifications

# Restart to apply changes
kubectl rollout restart deployment/notifiarr -n notifications
```

## Notification Types

### Download Events
- **Started**: When downloads begin
- **Completed**: When downloads finish
- **Failed**: When downloads encounter errors
- **Imported**: When media is processed and moved
- **Quality Upgraded**: When better versions are found

### System Events
- **Application Health**: When services go up/down
- **Storage Alerts**: When disk space is low
- **Performance Issues**: When systems are overloaded
- **Security Events**: When unusual activity is detected

### User Events (via Overseerr)
- **New Requests**: When users request content
- **Request Approved**: When requests are approved
- **Content Available**: When requested content is ready
- **Request Denied**: When requests are declined

## Discord Bot Commands

### Media Management
```
/movies search <title>          # Search for movies
/tv search <title>              # Search for TV shows
/music search <artist>          # Search for music
/books search <title>           # Search for books
```

### Download Management
```
/downloads status               # Show current downloads
/downloads pause <name>         # Pause specific download
/downloads resume <name>        # Resume specific download
/downloads cancel <name>        # Cancel specific download
```

### System Status
```
/status apps                    # Show *arr application status
/status downloads               # Show download client status
/status storage                 # Show storage usage
/status system                  # Show overall system health
```

### Statistics
```
/stats downloads                # Download statistics
/stats quality                  # Quality distribution
/stats activity                 # Recent activity summary
/stats top                      # Top requested content
```

## Configuration Examples

### Discord Rich Notifications
```yaml
# Example notification format
embed:
  title: "📺 TV Show Downloaded"
  description: "The Office S09E23 - A.A.R.M."
  color: "0x00ff00"
  fields:
    - name: "Quality"
      value: "WEBDL-1080p"
    - name: "Size"
      value: "1.2 GB"
    - name: "Time"
      value: "12m 34s"
  thumbnail:
    url: "https://image.tmdb.org/poster.jpg"
```

### Custom Webhook Integration
```bash
# Send custom notifications to other services
curl -X POST "https://your-webhook-url.com" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "download_complete",
    "title": "Movie Downloaded",
    "quality": "WEBDL-1080p",
    "size": "4.2 GB"
  }'
```

## Monitoring and Alerts

### Health Monitoring
- **Application Uptime**: Track when services go offline
- **Response Times**: Monitor API response performance
- **Error Rates**: Alert on increased failure rates
- **Resource Usage**: Monitor CPU, memory, and storage

### Custom Alerts
- **Storage Warnings**: Alert when disk space < 10%
- **Download Failures**: Alert after 3 consecutive failures
- **Performance Degradation**: Alert when response times > 5s
- **Security Events**: Alert on unauthorized access attempts

### Performance Metrics
```bash
# View Notifiarr metrics
kubectl logs -n notifications deployment/notifiarr | grep -i metric

# Check application health
curl -s https://notifiarr.k8s.dttesting.com/api/v1/status | jq .

# Monitor notification delivery
kubectl logs -n notifications deployment/notifiarr -f | grep -i discord
```

## Troubleshooting

### Common Issues

#### API Key Problems
```bash
# Check if API key is valid
kubectl logs -n notifications deployment/notifiarr | grep -i "api key"

# Update API key
kubectl patch secret notifiarr-secrets -n notifications \
  -p '{"stringData":{"DN_API_KEY":"your-new-api-key"}}'
```

#### Discord Integration Issues
```bash
# Check Discord webhook connectivity
kubectl exec -n notifications deployment/notifiarr -- \
  curl -X POST "YOUR_DISCORD_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"Test from Kubernetes"}'

# Check Discord bot permissions
kubectl logs -n notifications deployment/notifiarr | grep -i discord
```

#### *arr Application Connectivity
```bash
# Test connection to Sonarr
kubectl exec -n notifications deployment/notifiarr -- \
  curl -s http://sonarr.media.svc.cluster.local:8989/api/v3/system/status

# Check all configured endpoints
kubectl describe configmap notifiarr-config -n notifications
```

### Log Analysis
```bash
# View comprehensive logs
kubectl logs -n notifications deployment/notifiarr -f

# Check specific notification types
kubectl logs -n notifications deployment/notifiarr | grep -i "download\|import\|failed"

# Monitor webhook delivery
kubectl logs -n notifications deployment/notifiarr | grep -i "webhook\|discord\|telegram"
```

## Advanced Configuration

### Custom Notification Rules
```yaml
# Example notification rules
rules:
  downloads:
    notify_on_start: true
    notify_on_complete: true
    notify_on_failure: true
    minimum_size: "100MB"
    
  quality:
    notify_on_upgrade: true
    preferred_qualities:
      - "WEBDL-1080p"
      - "BluRay-1080p"
      
  users:
    notify_admins_only: false
    rate_limit: "5_per_hour"
```

### Performance Optimization
```yaml
# Optimize notification delivery
performance:
  batch_notifications: true
  batch_size: 10
  batch_timeout: "30s"
  retry_attempts: 3
  retry_delay: "5s"
```

### Security Configuration
```yaml
# Security settings
security:
  require_authentication: true
  allowed_ips:
    - "10.0.0.0/8"
    - "192.168.0.0/16"
  rate_limiting: true
  max_requests_per_minute: 60
```

## Integration Benefits

### For *arr Stack
- **Immediate feedback** on search and download status
- **Failure notifications** to catch issues quickly
- **Quality tracking** to monitor upgrade success
- **Performance monitoring** for optimization opportunities

### For Download Clients
- **Real-time progress** updates for long downloads
- **Completion notifications** without manual checking
- **Error alerts** for failed or stalled downloads
- **Statistics tracking** for bandwidth and usage analysis

### For Users (via Discord)
- **Interactive control** over the entire media stack
- **Status updates** without accessing multiple UIs
- **Request notifications** when content becomes available
- **Community engagement** through shared Discord server

Notifiarr ties everything together into a cohesive, notification-rich ecosystem that keeps you informed about every aspect of your automated media pipeline!