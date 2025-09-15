# Initial Setup - Ultimate Life Automation Platform

## Overview

This guide walks through the complete deployment of a Talos Linux Kubernetes cluster that hosts the **Ultimate Life Automation Platform** - a comprehensive ecosystem managing entertainment, documents, household operations, and system monitoring. The deployment is fully automated with cross-platform scripts and GitOps management via ArgoCD.

## Platform Capabilities

Your homelab will include:
- **25+ Applications** across entertainment, household, and system management
- **25TB+ Storage** for media, documents, and household data
- **Complete Automation** from content requests to household inventory
- **Enterprise Security** with VPN protection and encrypted communications
- **Professional Monitoring** with metrics, alerts, and performance tracking

## Prerequisites

### 1. Download Required Tools

On your Windows workstation (MOTOSTATION):

```powershell
# Download talosctl for Windows
# Visit: https://github.com/siderolabs/talos/releases
# Download talosctl-windows-amd64.exe and rename to talosctl.exe
# Add to PATH or place in C:\Windows\System32\

# Verify installation
talosctl version --client
```

### 2. Download Talos Linux ISO

Download the latest Talos Linux ISO for deployment:
- Visit: https://github.com/siderolabs/talos/releases
- Download: `talos-amd64.iso`
- Upload to Proxmox ISO storage

## Automated Deployment Process

### Quick Start (Recommended)

Use the provided scripts for a streamlined deployment:

#### Linux/macOS
```bash
# 1. Build custom Talos image with QEMU guest agent
./scripts/build-talos-image.sh

# 2. Generate configurations (creates secrets.yaml)
./scripts/generate-configs.sh

# 3. Apply configurations to nodes
./scripts/apply-configs.sh

# 4. Bootstrap the cluster
./scripts/bootstrap-cluster.sh

# 5. Verify deployment
./scripts/verify-access.sh

# 6. Deploy core infrastructure
kubectl apply -k kubernetes/core/

# 7. Deploy ArgoCD for GitOps
kubectl apply -k kubernetes/gitops/argocd/
./scripts/configure-argocd.sh

# 8. Deploy all applications via GitOps
kubectl apply -k kubernetes/gitops/applications/
```

#### Windows PowerShell
```powershell
# 1. Build custom Talos image with QEMU guest agent
.\scripts\build-talos-image.ps1

# 2. Generate configurations (creates secrets.yaml)
.\scripts\generate-configs.ps1

# 3. Apply configurations to nodes
.\scripts\apply-configs.ps1

# 4. Bootstrap the cluster
.\scripts\bootstrap-cluster.ps1

# 5. Verify deployment
.\scripts\verify-access.ps1

# 6. Deploy core infrastructure
kubectl apply -k kubernetes/core/

# 7. Deploy ArgoCD for GitOps
kubectl apply -k kubernetes/gitops/argocd/
.\scripts\configure-argocd.ps1

# 8. Deploy all applications via GitOps
kubectl apply -k kubernetes/gitops/applications/
```

## Manual Deployment Steps

### Phase 1: Generate Talos Configuration
talosctl gen config $CLUSTER_NAME https://${CLUSTER_ENDPOINT}:6443 `
  --with-secrets secrets.yaml `
  --config-patch talos/patches/common.yaml `
  --config-patch talos/patches/worker.yaml `
  --output talos/worker.yaml `
  --output-types worker
```

## Phase 2: Deploy VMs on Proxmox

### 2.1 VM Specifications

**Control Plane Nodes (3x)**:
- Name: talos-cp-01, talos-cp-02, talos-cp-03
- CPU: 4 cores
- RAM: 8GB
- Disk: 100GB (SSD if available)
- Network: VLAN 1200 (Servers)
- Boot: Talos ISO

**Worker Nodes (Optional)**:
- Can use same specs as control plane
- Or start with control plane nodes as workers

### 2.2 Create VMs via Proxmox

For each node:
1. Create VM with above specifications
2. Attach Talos ISO as boot device
3. Configure network with static IP
4. Start VM (it will boot to Talos installer)

## Phase 3: Bootstrap Cluster

### 3.1 Apply Configuration

For each control plane node:

```bash
# Apply configuration to nodes
talosctl apply-config --insecure `
  --nodes 192.168.1.241 `
  --file talos/controlplane.yaml `
  --endpoint 192.168.1.241

talosctl apply-config --insecure `
  --nodes 192.168.1.242 `
  --file talos/controlplane.yaml `
  --endpoint 192.168.1.242

talosctl apply-config --insecure `
  --nodes 192.168.1.243 `
  --file talos/controlplane.yaml `
  --endpoint 192.168.1.243
```

### 3.2 Bootstrap etcd

```bash
# Bootstrap on first node only
talosctl bootstrap --nodes 192.168.1.241 --endpoints 192.168.1.241
```

### 3.3 Configure talosctl

```bash
# Set up talosctl config
talosctl config merge talos/talosconfig

# Set endpoints
talosctl config endpoints 192.168.1.241 192.168.1.242 192.168.1.243

# Set nodes
talosctl config nodes 192.168.1.241 192.168.1.242 192.168.1.243
```

### 3.4 Verify Cluster

```bash
# Check node status
talosctl health

# Get kubeconfig
talosctl kubeconfig -n 192.168.1.241

# Verify with kubectl
kubectl get nodes
```

## Phase 4: Configure Virtual IP

The VIP (192.168.1.240) will be managed by Talos for HA access to the Kubernetes API.

This is configured in the control plane patches (see `talos/patches/controlplane.yaml`).

## Deployed Applications

After successful deployment, your platform includes:

### 🏗️ **Infrastructure & Core (5 services)**
- **Talos Kubernetes** - 5-node HA cluster on Proxmox
- **NFS Storage** - 25TB+ distributed storage infrastructure
- **Traefik** - Reverse proxy with automatic SSL certificates
- **ArgoCD** - GitOps continuous deployment
- **ArgoCD Image Updater** - Automated container updates

### 🛡️ **Security & Privacy (2 services)**
- **Gluetun VPN** - Per-container VPN protection
- **Let's Encrypt** - Automatic SSL certificate management

### ⚡ **Management & Monitoring (4 services)**
- **Portainer** - Container management at portainer.k8s.dttesting.com
- **Prometheus** - Metrics collection at prometheus.k8s.dttesting.com
- **Grafana** - Monitoring dashboards at grafana.k8s.dttesting.com
- **Homer** - Service dashboard at homer.k8s.dttesting.com

### 📄 **Document Management (3 services)**
- **Paperless-ngx** - OCR document management at paperless.k8s.dttesting.com
- **PostgreSQL** - Database for document metadata
- **Redis** - Caching and task queue

### 🎬 **Media Automation (5 services)**
- **Sonarr** - TV show management at sonarr.k8s.dttesting.com
- **Radarr** - Movie management at radarr.k8s.dttesting.com
- **Lidarr** - Music management at lidarr.k8s.dttesting.com
- **Bazarr** - Subtitle management at bazarr.k8s.dttesting.com
- **Readarr** - Book management at readarr.k8s.dttesting.com

### ⬇️ **Download Automation (2 services)**
- **qBittorrent** - Torrent client at qbittorrent.k8s.dttesting.com
- **NZBget** - Usenet client at nzbget.k8s.dttesting.com

### 🔍 **Discovery & Requests (3 services)**
- **Prowlarr** - Indexer management at prowlarr.k8s.dttesting.com
- **Overseerr** - Content requests at overseerr.k8s.dttesting.com
- **FlareSolverr** - Cloudflare bypass service

### 🔔 **Notifications & Development (2 services)**
- **Notifiarr** - Notification hub at notifiarr.k8s.dttesting.com
- **Code-Server** - VS Code development at code-server.k8s.dttesting.com

### 🏠 **Household Management (1 service)**
- **Grocy** - Household ERP system at grocy.k8s.dttesting.com

## Next Steps

Once the cluster is running, proceed to configuration:
1. [Configure Applications](docs/post-deployment-config.md)
2. [Set up Notifications](docs/notification-setup.md)
3. [Troubleshooting Guide](docs/03-troubleshooting.md)

## Troubleshooting

### View Talos Logs
```bash
talosctl logs -n 192.168.1.241
```

### Check Service Status
```bash
talosctl service -n 192.168.1.241
```

### Access Container Logs
```bash
talosctl logs -n 192.168.1.241 -k kubelet
```

## Post-Deployment: GitOps Setup

After the cluster is running, set up ArgoCD for GitOps management:

### 1. Access ArgoCD
- **LoadBalancer**: http://192.168.1.210
- **Ingress**: https://argocd.homelab-k8s.dttesting.com

### 2. Get Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Configure GitOps
```bash
# Commit all changes
git add .
git commit -m "Add cluster configuration and ArgoCD setup"
git push origin main

# Apply root application
kubectl apply -f kubernetes/gitops/applications/root-app.yaml
```

### 4. Monitor in ArgoCD UI
- Login with admin credentials
- View application sync status
- Enable auto-sync for continuous deployment

## Important Notes

### Secrets Management
- **CRITICAL**: The `secrets.yaml` file contains all cluster secrets
- **NEVER** commit this file to Git
- Back it up securely - you'll need it for cluster recovery

### Network Configuration
- All nodes use DHCP with reserved IPs
- Control plane VIP: 192.168.1.240
- MetalLB IP range: 192.168.1.200-239

### Interface Names
- Proxmox VMs use `ens18` (not `eth0`)
- Configuration uses `deviceSelector` for flexibility

### Post-Bootstrap Requirements
- kube-proxy deployment is required (included in core infrastructure)
- This fixes pod-to-service connectivity when Talos has `proxy.disabled: true`
