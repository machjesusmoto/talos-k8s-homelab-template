# Cross-Platform Deployment Guide

This guide provides instructions for deploying your Talos Kubernetes cluster on both Linux and Windows platforms.

## Prerequisites

### Both Platforms
- Access to Proxmox environment with VM creation capabilities
- Network access to the target IP range (192.168.1.240-245)
- Internet access for downloading tools and images

### Linux Requirements
- Ubuntu 20.04+ or similar Linux distribution
- `curl`, `wget`, `bash` (standard on most distributions)
- `bc` command for calculations (install with `sudo apt install bc`)

### Windows Requirements
- Windows 10/11 with PowerShell 5.1+
- Windows Subsystem for Linux (WSL) recommended but not required
- Administrative privileges for tool installation

## Tool Installation

### Linux

#### Install Talos CLI
```bash
# Download and install talosctl
curl -sL https://talos.dev/install | sh

# Verify installation
talosctl version --client
```

#### Install kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### Windows

#### Install Talos CLI
Using PowerShell as Administrator:
```powershell
# Using winget (recommended)
winget install SiderolabsInc.talosctl

# Or using Chocolatey
choco install talosctl

# Verify installation
talosctl version --client
```

#### Install kubectl
```powershell
# Using winget (recommended)
winget install Kubernetes.kubectl

# Or using Chocolatey
choco install kubernetes-cli

# Verify installation
kubectl version --client
```

## Deployment Workflow

### Phase 1: Prepare Custom Talos Image

#### Linux
```bash
# Navigate to project directory
cd /path/to/k8s-homelab-migration

# Build custom Talos image with QEMU guest agent
chmod +x scripts/build-talos-image.sh
./scripts/build-talos-image.sh
```

#### Windows
```powershell
# Navigate to project directory
cd C:\path\to\k8s-homelab-migration

# Build custom Talos image
.\scripts\build-talos-image.ps1
```

### Phase 2: Deploy VMs in Proxmox

1. **Create 5 VMs** with the following specifications:
   - **Control Planes**: talos-cp-01, talos-cp-02, talos-cp-03
   - **Workers**: talos-worker-01, talos-worker-02
   - **Each VM**: 4 vCPU, 8GB RAM, 100GB disk
   - **Network**: VLAN 1200 (192.168.1.0/24)

2. **IP Assignments**:
   | Node | IP Address | Role |
   |------|------------|------|
   | talos-cp-01 | 192.168.1.241 | Control Plane |
   | talos-cp-02 | 192.168.1.242 | Control Plane |
   | talos-cp-03 | 192.168.1.243 | Control Plane |
   | talos-worker-01 | 192.168.1.244 | Worker |
   | talos-worker-02 | 192.168.1.245 | Worker |
   | VIP (API) | 192.168.1.240 | Load Balancer |

3. **Boot all VMs** from the custom Talos ISO

### Phase 3: Generate Talos Configuration

#### Linux
```bash
# Generate cluster configuration and secrets
chmod +x scripts/generate-configs.sh
./scripts/generate-configs.sh

# IMPORTANT: Backup the generated secrets.yaml file!
cp secrets.yaml secrets.yaml.backup
```

#### Windows
```powershell
# Generate cluster configuration and secrets
.\scripts\generate-configs.ps1

# IMPORTANT: Backup the generated secrets.yaml file!
Copy-Item secrets.yaml secrets.yaml.backup
```

### Phase 4: Apply Configurations

⚠️ **Critical Step**: The apply-configs script now automatically handles ISO ejection to prevent boot loops.

#### Linux
```bash
# Apply configurations to all nodes
chmod +x scripts/apply-configs.sh
./scripts/apply-configs.sh
```

#### Windows
```powershell
# Apply configurations to all nodes (with automatic ISO handling)
.\scripts\apply-configs.ps1
```

**What happens during this step**:
- Configurations are applied to each node
- Script attempts automatic ISO ejection (if Proxmox tools available)
- Nodes restart automatically with applied configurations
- Script waits for nodes to come back online

### Phase 5: Bootstrap Cluster

#### Linux
```bash
# Bootstrap the Kubernetes cluster
chmod +x scripts/bootstrap-cluster.sh
./scripts/bootstrap-cluster.sh
```

#### Windows
```powershell
# Bootstrap the Kubernetes cluster
.\scripts\bootstrap-cluster.ps1
```

### Phase 6: Verify Deployment

#### Linux
```bash
# Verify cluster health and access
chmod +x scripts/verify-access.sh
./scripts/verify-access.sh

# Setup kubectl (if not done automatically)
chmod +x scripts/setup-kubectl.sh
./scripts/setup-kubectl.sh
```

#### Windows
```powershell
# Verify cluster health and access
.\scripts\verify-access.ps1

# Setup kubectl (if not done automatically)
.\scripts\setup-kubectl.ps1
```

### Phase 7: Deploy Core Infrastructure

#### Linux
```bash
# Deploy core Kubernetes infrastructure
kubectl apply -k kubernetes/core/
```

#### Windows
```powershell
# Deploy core Kubernetes infrastructure
kubectl apply -k kubernetes/core/
```

**Components deployed**:
- kube-proxy (required for service routing)
- MetalLB (LoadBalancer services)
- Ingress-nginx (HTTP/HTTPS ingress)
- cert-manager (TLS certificates)
- NFS CSI driver (persistent storage)

### Phase 8: Deploy ArgoCD for GitOps

#### Linux
```bash
# Deploy ArgoCD
kubectl apply -k kubernetes/gitops/argocd/

# Configure ArgoCD for GitOps
chmod +x scripts/configure-argocd.sh
./scripts/configure-argocd.sh

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### Windows
```powershell
# Deploy ArgoCD
kubectl apply -k kubernetes/gitops/argocd/

# Configure ArgoCD for GitOps
.\scripts\configure-argocd.ps1

# Get admin password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
```

**ArgoCD Access**:
- LoadBalancer: http://192.168.1.210
- Ingress: https://argocd.homelab-k8s.dttesting.com
- Username: admin

### Phase 9: Enable GitOps

```bash
# Commit all changes
git add .
git commit -m "Add cluster configuration and ArgoCD setup"
git push origin main

# Apply root application for GitOps
kubectl apply -f kubernetes/gitops/applications/root-app.yaml
```

## Troubleshooting

### Common Issues

1. **VIP Connectivity Problems**:
   - Error: `dial tcp 192.168.1.240:6443: connect: no route to host`
   - **Solution**: VIP configuration issue - ensure `dhcp: true` in controlplane.yaml
   - **Fix**: Update patches and reapply configurations

2. **ISO Boot Loop**:
   - Nodes keep booting from ISO after configuration
   - **Solution**: Ensure ISO is detached after applying configurations
   - **Prevention**: Updated apply-configs script handles this automatically

3. **Certificate Verification Errors**:
   - Error: `x509: certificate signed by unknown authority`
   - **Solution**: Usually means configs weren't applied properly
   - **Fix**: Ensure nodes rebooted cleanly from disk after config application

4. **Network connectivity problems**:
   - Ensure VLAN 1200 is properly configured
   - Check firewall rules for ports 50000 (Talos) and 6443 (Kubernetes)
   - Verify DNS resolution for all nodes

### Recovery Steps

If deployment fails:

1. **Reboot all nodes** from Talos ISO (clean slate)
2. **Pull latest changes**: `git pull origin main`
3. **Regenerate configurations**: Run generate-configs script
4. **Reapply with ISO handling**: Run apply-configs script
5. **Bootstrap**: Run bootstrap script

## Script Reference

| Operation | Linux Script | Windows Script | Key Features |
|-----------|-------------|----------------|---------------|
| Build Image | `build-talos-image.sh` | `build-talos-image.ps1` | Custom Talos ISO with QEMU agent |
| Generate Configs | `generate-configs.sh` | `generate-configs.ps1` | Creates cluster configurations |
| Apply Configs | `apply-configs.sh` | `apply-configs.ps1` | **Auto ISO ejection, restart handling** |
| Bootstrap | `bootstrap-cluster.sh` | `bootstrap-cluster.ps1` | **Fixed VIP connectivity, better error handling** |
| Verify Access | `verify-access.sh` | `verify-access.ps1` | Comprehensive health checking |
| Setup kubectl | `setup-kubectl.sh` | `setup-kubectl.ps1` | Configure kubectl access |
| Cluster Exec | `cluster-exec.sh` | `cluster-exec.ps1` | Run commands on nodes |
| **Diagnose** | - | `diagnose-cluster.ps1` | **Troubleshoot configuration issues** |
| **Configure ArgoCD** | `configure-argocd.sh` | `configure-argocd.ps1` | **Setup GitOps with ArgoCD** |

## Recent Improvements

### Enhanced Configuration Handling
- **Fixed VIP configuration**: Now uses `dhcp: true` with VIP overlay
- **Automatic ISO ejection**: Prevents boot loops after configuration
- **Better error handling**: Clear guidance for troubleshooting

### Cross-Platform Compatibility
- **Complete script parity**: Every operation available on both platforms
- **Platform-native approaches**: Uses appropriate tools and syntax
- **Consistent user experience**: Same functionality across platforms

### Robust Deployment Process
- **Prerequisites checking**: Validates requirements before proceeding
- **Progressive health checks**: Verifies each step before continuing
- **Recovery guidance**: Clear instructions for common issues

### GitOps Integration
- **ArgoCD deployment**: Enterprise-standard GitOps controller
- **App-of-apps pattern**: Scalable application management
- **Automatic sync**: Changes in Git automatically deployed to cluster
- **Self-healing**: Drift detection and automatic correction

All scripts include error handling, progress indicators, and helpful output to guide you through the deployment process.

## Complete Deployment Summary

The full deployment process:
1. Build custom Talos image
2. Generate cluster configurations
3. Apply configs to nodes (with auto ISO ejection)
4. Bootstrap the cluster
5. Verify cluster health
6. Deploy core infrastructure
7. Deploy and configure ArgoCD
8. Enable GitOps with root application
9. Access ArgoCD UI for monitoring

Total deployment time: ~30-45 minutes for a complete cluster with GitOps.
