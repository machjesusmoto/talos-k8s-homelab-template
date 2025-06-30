# Turnkey Kubernetes Homelab Deployment Guide

This guide will walk you through deploying a complete Kubernetes homelab with Talos Linux and a comprehensive application suite.

## Prerequisites

- 5 VMs or physical machines (3 control planes, 2 workers)
- Network access to download images and configurations
- Domain name with Cloudflare DNS (for SSL certificates)
- NFS server for storage (optional but recommended)

## Quick Start (30 minutes to fully running cluster)

### Step 1: Clone and Configure

1. **Fork and clone this repository**:
   ```bash
   git clone https://github.com/yourusername/k8s-homelab-migration.git
   cd k8s-homelab-migration
   ```

2. **Create your configuration file**:
   ```bash
   cp configurations.yaml.template configurations.yaml
   ```

3. **Edit configurations.yaml with your values**:
   - Update all IP addresses to match your network
   - Set your domain name and Cloudflare credentials
   - Configure storage (NFS server IP)
   - Change all default passwords
   - Update VPN settings if using Gluetun

### Step 2: Deploy Infrastructure

Choose your platform:

#### Linux/WSL:
```bash
# 1. Generate Talos configurations
./scripts/generate-configs.sh

# 2. Apply configurations to nodes
./scripts/apply-configs.sh

# 3. Bootstrap the cluster
./scripts/bootstrap-cluster.sh

# 4. Verify deployment
./scripts/verify-access.sh

# 5. Fix any deployment issues
./scripts/fix-deployment-issues.sh
```

#### Windows PowerShell:
```powershell
# 1. Generate Talos configurations
.\scripts\generate-configs.ps1

# 2. Apply configurations to nodes
.\scripts\apply-configs.ps1

# 3. Bootstrap the cluster
.\scripts\bootstrap-cluster.ps1

# 4. Verify deployment
.\scripts\verify-access.ps1

# 5. Fix any deployment issues
.\scripts\fix-deployment-issues.ps1
```

### Step 3: Access Your Applications

After deployment, your applications will be available at:

- **ArgoCD**: `https://argocd.yourdomain.com`
- **Homer Dashboard**: `https://homer.yourdomain.com`
- **Sonarr**: `https://sonarr.yourdomain.com`
- **Radarr**: `https://radarr.yourdomain.com`
- **Bazarr**: `https://bazarr.yourdomain.com`
- **qBittorrent**: `https://qbittorrent.yourdomain.com`
- **Prowlarr**: `https://prowlarr.yourdomain.com`
- **Grafana**: `https://grafana.yourdomain.com`
- **Paperless-ngx**: `https://paperless.yourdomain.com`
- **Grocy**: `https://grocy.yourdomain.com`
- **Code Server**: `https://code.yourdomain.com`

## Configuration Details

### Required Configuration Values

Before deployment, you **must** update these values in `configurations.yaml`:

#### Network Configuration
```yaml
cluster:
  control_planes:
    - ip: "YOUR_CP1_IP"      # First control plane
    - ip: "YOUR_CP2_IP"      # Second control plane  
    - ip: "YOUR_CP3_IP"      # Third control plane
  workers:
    - ip: "YOUR_WORKER1_IP"  # First worker
    - ip: "YOUR_WORKER2_IP"  # Second worker

network:
  cluster_vip: "YOUR_VIP"              # Kubernetes API endpoint
  metallb_ip_range: "YOUR_LB_RANGE"    # LoadBalancer IP range

storage:
  nfs_server: "YOUR_NFS_SERVER"        # NFS server IP
```

#### Domain and SSL
```yaml
domain:
  base: "yourdomain.com"               # Your domain
  email: "you@yourdomain.com"          # Let's Encrypt email

cloudflare:
  email: "you@cloudflare.com"          # Cloudflare account email
  api_token: "your-cf-token"           # API token with DNS permissions
```

#### Application Passwords
```yaml
# Change ALL of these passwords!
downloads:
  qbittorrent:
    admin_password: "strong-password"
  nzbget:
    admin_password: "strong-password"

paperless:
  admin_password: "strong-password"
  secret_key: "long-random-string"

# ... and all other passwords in the file
```

### Optional Configuration

#### Proxmox Integration
```yaml
proxmox:
  enabled: true                        # Enable VM management
  node: "your-proxmox-node"           # Proxmox node name
  vm_mappings:                        # VM ID mappings
    "192.168.1.241": 241
    # ... etc
```

#### VPN Configuration
```yaml
vpn:
  provider: "airvpn"                  # Your VPN provider
  wireguard_private_key: "key"        # Get from VPN provider
  wireguard_public_key: "key"         # Get from VPN provider
  # ... other VPN settings
```

## Troubleshooting

### Common Issues

1. **Pods stuck in CrashLoopBackOff**:
   ```bash
   ./scripts/fix-deployment-issues.sh
   ```

2. **Certificate issues**:
   - Check Cloudflare API token permissions
   - Verify DNS records are created
   - Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`

3. **Network connectivity**:
   - Verify VIP is accessible: `ping YOUR_VIP`
   - Check MetalLB IP range doesn't conflict
   - Ensure firewall allows traffic

4. **Storage issues**:
   - Verify NFS server is accessible
   - Check NFS exports are configured
   - Test NFS mount manually

### Getting Help

- **View cluster status**: `kubectl get pods -A`
- **Check node health**: `./scripts/verify-access.sh`
- **Execute commands on nodes**: `./scripts/cluster-exec.sh all "uptime"`
- **View logs**: `kubectl logs -n <namespace> <pod-name>`

## What Gets Deployed

### Core Infrastructure
- **Talos Linux**: Immutable Kubernetes OS
- **MetalLB**: LoadBalancer service
- **NGINX Ingress**: HTTP/HTTPS routing  
- **cert-manager**: Automatic SSL certificates
- **ArgoCD**: GitOps deployment management

### Media Management
- **Sonarr**: TV show management
- **Radarr**: Movie management
- **Lidarr**: Music management
- **Readarr**: Book management
- **Bazarr**: Subtitle management

### Download Clients
- **qBittorrent**: Torrent client
- **NZBget**: Usenet client
- **Gluetun**: VPN gateway

### Automation & Indexers
- **Prowlarr**: Indexer management
- **Overseerr**: Media requests
- **Flaresolverr**: Cloudflare solver

### Productivity
- **Paperless-ngx**: Document management
- **Grocy**: Household management
- **Code Server**: VS Code in browser

### Monitoring & Management
- **Grafana**: Metrics visualization
- **Prometheus**: Metrics collection
- **Homer**: Application dashboard
- **Portainer**: Container management

## Security Considerations

- All applications use SSL certificates
- Default passwords must be changed
- Applications are isolated by namespace
- Network policies restrict communication
- Regular security updates via GitOps

## Customization

The deployment is fully customizable:
- Add/remove applications by modifying GitOps configurations
- Adjust resource limits in application manifests
- Configure additional storage or networking
- Integrate with external authentication systems

For advanced customization, see the individual application configurations in `kubernetes/apps/`.