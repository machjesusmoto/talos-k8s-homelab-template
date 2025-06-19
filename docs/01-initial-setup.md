# Initial Setup - Talos Kubernetes Cluster

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

## Phase 1: Generate Talos Configuration

### 1.1 Generate Secrets

```bash
# Generate cluster secrets (do this once and save securely!)
talosctl gen secrets -o secrets.yaml
```

### 1.2 Generate Configuration Files

```bash
# Set cluster name and endpoint
$CLUSTER_NAME="homelab"
$CLUSTER_ENDPOINT="192.168.1.240"  # Your VIP

# Generate control plane config
talosctl gen config $CLUSTER_NAME https://${CLUSTER_ENDPOINT}:6443 `
  --with-secrets secrets.yaml `
  --config-patch @talos/patches/common.yaml `
  --config-patch @talos/patches/controlplane.yaml `
  --output talos/controlplane.yaml `
  --output-types controlplane

# Generate worker config (if using separate workers)
talosctl gen config $CLUSTER_NAME https://${CLUSTER_ENDPOINT}:6443 `
  --with-secrets secrets.yaml `
  --config-patch @talos/patches/common.yaml `
  --config-patch @talos/patches/worker.yaml `
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

## Next Steps

Once the cluster is running:
1. [Deploy Core Infrastructure](02-core-infrastructure.md)
2. [Set up GitOps](03-gitops-setup.md)
3. [Deploy Applications](04-deploy-applications.md)

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
