# Prometheus + Grafana Monitoring Stack

Comprehensive monitoring solution with Prometheus for metrics collection and Grafana for visualization.

## Components

### Prometheus
- **Metrics Collection**: Scrapes metrics from Kubernetes and applications
- **Storage**: 50GB persistent storage with 30-day retention
- **Discovery**: Kubernetes service discovery for automatic target detection
- **URL**: https://prometheus.k8s.dttesting.com

### Grafana
- **Visualization**: Beautiful dashboards and alerting
- **Storage**: 10GB persistent storage for dashboards and settings
- **Pre-configured**: Prometheus datasource and sample dashboards
- **URL**: https://grafana.k8s.dttesting.com

## Access Information

### Grafana Login
- **URL**: https://grafana.k8s.dttesting.com
- **Username**: admin
- **Password**: admin123!
- **Note**: Change the default password after first login

### Prometheus
- **URL**: https://prometheus.k8s.dttesting.com
- **Access**: Direct access to Prometheus web UI and PromQL queries

## Monitored Targets

### Kubernetes Infrastructure
- **API Server**: Kubernetes API metrics
- **Nodes**: Node health and resource usage via cAdvisor
- **Pods**: Application metrics with annotation-based discovery
- **Services**: Service-level metrics

### Homelab Applications
- **ArgoCD**: GitOps metrics and application health
- **Traefik**: Reverse proxy metrics and request statistics
- **Gluetun**: VPN gateway health and connection status
- **ArgoCD Image Updater**: Image update statistics

### System Metrics
- **CPU Usage**: Per-node and per-pod CPU utilization
- **Memory Usage**: Memory consumption and limits
- **Network**: Network I/O and connection metrics
- **Storage**: Disk usage and I/O metrics

## Pre-installed Dashboards

### Homelab Overview
- Cluster status summary
- Resource utilization overview
- Application health status
- Key performance indicators

### Kubernetes Cluster
- Node status and resource usage
- Pod and deployment health
- Namespace resource consumption
- Persistent volume usage

## Prometheus Configuration

### Scrape Targets
The monitoring stack automatically discovers and monitors:

```yaml
# Kubernetes autodiscovery
- kubernetes-apiservers
- kubernetes-nodes  
- kubernetes-nodes-cadvisor
- kubernetes-pods (with annotations)
- kubernetes-services (with annotations)

# Static application targets
- argocd-metrics
- argocd-image-updater
- traefik
- gluetun
```

### Retention Policy
- **Time**: 30 days
- **Size**: 45GB maximum
- **Resolution**: 15-second scrape interval

## Adding Custom Metrics

### For Pods
Add annotations to your pod spec:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

### For Services
Add annotations to your service:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/scheme: "http"
```

## Custom Dashboards

### Importing Dashboards
1. Access Grafana web UI
2. Go to Dashboards → Import
3. Use dashboard ID or upload JSON file
4. Configure data source (Prometheus is pre-configured)

### Popular Dashboard IDs
- **Node Exporter Full**: 1860
- **Kubernetes Cluster Monitoring**: 7249
- **ArgoCD**: 14584
- **Traefik 2.0**: 11462

### Creating Custom Dashboards
1. Navigate to Dashboards → New
2. Add panels with PromQL queries
3. Configure visualizations
4. Save and organize in folders

## Alerting Setup

### Prometheus Alerts
Add alert rules to `/etc/prometheus/rules/`:

```yaml
groups:
- name: homelab.rules
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for {{ $labels.instance }}"
```

### Grafana Alerts
1. Create alert rules in dashboard panels
2. Configure notification channels (email, Slack, etc.)
3. Set up alert policies and routing

## Backup and Recovery

### Grafana Backup
```bash
# Backup Grafana data
kubectl exec -n monitoring deployment/grafana -- tar -czf - /var/lib/grafana > grafana-backup.tar.gz

# Restore Grafana data
kubectl exec -n monitoring deployment/grafana -- tar -xzf - -C / < grafana-backup.tar.gz
```

### Prometheus Backup
```bash
# Backup Prometheus data
kubectl exec -n monitoring deployment/prometheus -- tar -czf - /prometheus > prometheus-backup.tar.gz

# Note: Prometheus data is time-series, consider retention policy for backups
```

## Troubleshooting

### Check Component Status
```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Check Prometheus targets
curl -s http://prometheus.k8s.dttesting.com/api/v1/targets | jq .

# Check Grafana health
curl -s http://grafana.k8s.dttesting.com/api/health
```

### Common Issues

#### Prometheus Not Scraping Targets
1. Check service discovery configuration
2. Verify RBAC permissions
3. Check network policies
4. Verify target annotations

#### Grafana Dashboard Issues
1. Check datasource configuration
2. Verify Prometheus connectivity
3. Check dashboard JSON syntax
4. Review Grafana logs

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n monitoring

# Check storage usage
kubectl exec -n monitoring deployment/prometheus -- df -h /prometheus
kubectl exec -n monitoring deployment/grafana -- df -h /var/lib/grafana
```

## Performance Tuning

### Prometheus Optimization
- Adjust scrape intervals based on requirements
- Configure recording rules for complex queries
- Optimize storage retention based on disk space
- Use remote storage for long-term retention

### Grafana Optimization
- Use caching for frequently accessed dashboards
- Optimize query performance with proper time ranges
- Configure data source query timeout
- Use template variables for dynamic dashboards

## Security Considerations

### Access Control
- Change default Grafana admin password
- Configure user authentication (LDAP, OAuth)
- Implement role-based access control
- Use HTTPS for all external access

### Network Security
- Restrict Prometheus access to internal networks
- Use service mesh for inter-service communication
- Implement network policies
- Regular security updates for containers

## Monitoring Best Practices

### Metrics Strategy
1. **RED Method**: Rate, Errors, Duration for services
2. **USE Method**: Utilization, Saturation, Errors for resources
3. **Four Golden Signals**: Latency, traffic, errors, saturation

### Dashboard Design
- Use consistent color schemes and layouts
- Include meaningful legends and units
- Provide context with annotations
- Organize dashboards by team/service

### Alerting Guidelines
- Alert on symptoms, not causes
- Avoid alert fatigue with proper thresholds
- Use meaningful alert descriptions
- Test alert delivery mechanisms

This monitoring stack provides comprehensive observability for your homelab infrastructure with room for customization and expansion.