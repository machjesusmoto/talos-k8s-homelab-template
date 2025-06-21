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

# Or manual installation
$version = "v1.9.0"  # Check latest version at github.com/siderolabs/talos
$url = "https://github.com/siderolabs/talos/releases/download/$version/talosctl-windows-amd64.exe"
Invoke-WebRequest -Uri $url -OutFile "$env:ProgramFiles\talosctl.exe"

# Verify installation
talosctl version --client
```

#### Install kubectl
```powershell
# Using winget (recommended)
winget install Kubernetes.kubectl

# Or using Chocolatey
choco install kubernetes-cli

# Or manual installation
$version = "v1.31.0"  # Check latest stable version
$url = "https://dl.k8s.io/release/$version/bin/windows/amd64/kubectl.exe"
Invoke-WebRequest -Uri $url -OutFile "$env:ProgramFiles\kubectl.exe"

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

# The script will output the custom ISO download URL
```

#### Windows
```powershell
# Navigate to project directory
cd C:\path\to\k8s-homelab-migration

# Build custom Talos image
.\scripts\build-talos-image.ps1

# The script will output the custom ISO download URL
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

#### Linux
```bash
# Apply configurations to all nodes
chmod +x scripts/apply-configs.sh
./scripts/apply-configs.sh
```

#### Windows
```powershell
# Apply configurations to all nodes
.\scripts\apply-configs.ps1
```

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

## Common Commands

### Cluster Management

#### Linux
```bash
# Check cluster health
talosctl health

# Get cluster information
talosctl cluster show

# Execute commands on nodes
./scripts/cluster-exec.sh cp "uptime"
./scripts/cluster-exec.sh workers "df -h"
./scripts/cluster-exec.sh all "free -h"

# View logs
talosctl logs --follow
```

#### Windows
```powershell
# Check cluster health
talosctl health

# Get cluster information
talosctl cluster show

# Execute commands on nodes
.\scripts\cluster-exec.ps1 cp "uptime"
.\scripts\cluster-exec.ps1 workers "df -h"
.\scripts\cluster-exec.ps1 all "free -h"

# View logs
talosctl logs --follow
```

### Kubernetes Operations

Both platforms use the same kubectl commands:
```bash
# Get cluster nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -A

# Apply core infrastructure
kubectl apply -k kubernetes/core/

# Deploy applications
kubectl apply -k kubernetes/apps/
```

## Troubleshooting

### Common Issues

1. **Network connectivity problems**:
   - Ensure VLAN 1200 is properly configured
   - Check firewall rules for ports 50000 (Talos) and 6443 (Kubernetes)
   - Verify DNS resolution for all nodes

2. **Configuration application failures**:
   - Ensure all VMs are running and accessible
   - Check that the custom ISO is properly mounted
   - Verify IP addresses match the configuration

3. **Bootstrap failures**:
   - Ensure only the first control plane node (192.168.1.241) is bootstrapped
   - Wait for all nodes to be Ready before proceeding
   - Check `talosctl health` output for specific errors

### Platform-Specific Notes

#### Linux
- Use `sudo` for operations requiring elevated privileges
- Scripts use bash-specific features (arrays, etc.)
- File paths use forward slashes

#### Windows
- Run PowerShell as Administrator when needed
- Scripts use PowerShell cmdlets and .NET methods
- File paths use backslashes
- Some commands may need different syntax (e.g., environment variables)

## Security Considerations

1. **secrets.yaml**: Never commit this file to version control
2. **Backup**: Always backup secrets.yaml before making changes
3. **Access**: Limit access to talosctl configuration files
4. **Network**: Use firewalls to restrict access to cluster nodes
5. **Updates**: Regularly update Talos and Kubernetes versions

## Next Steps

After successful deployment:

1. **Deploy Core Infrastructure**: Storage, networking, ingress
2. **Set up GitOps**: ArgoCD or Flux for automated deployments
3. **Configure Monitoring**: Prometheus, Grafana, alerts
4. **Migrate Applications**: Move services from Docker Swarm
5. **Implement Backup**: Velero or similar backup solutions

## Script Reference

| Operation | Linux Script | Windows Script |
|-----------|-------------|----------------|
| Build Image | `build-talos-image.sh` | `build-talos-image.ps1` |
| Generate Configs | `generate-configs.sh` | `generate-configs.ps1` |
| Apply Configs | `apply-configs.sh` | `apply-configs.ps1` |
| Bootstrap | `bootstrap-cluster.sh` | `bootstrap-cluster.ps1` |
| Verify Access | `verify-access.sh` | `verify-access.ps1` |
| Setup kubectl | `setup-kubectl.sh` | `setup-kubectl.ps1` |
| Cluster Exec | `cluster-exec.sh` | `cluster-exec.ps1` |

All scripts include error handling, progress indicators, and helpful output to guide you through the deployment process.
