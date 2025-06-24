# Talos Kubernetes Homelab - Greenfield Deployment

A modern, secure, and production-grade Kubernetes homelab built on Talos Linux.

## Overview

This project deploys a highly available Kubernetes cluster using Talos Linux, designed for running containerized services with enterprise-grade security and operational patterns.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Talos Linux K8s Cluster                   │
├─────────────────────────────────────────────────────────────┤
│  Control Plane (3 nodes)    │  Worker Nodes (2 nodes)       │
│  ├── talos-cp-01           │  ├── talos-worker-01         │
│  ├── talos-cp-02           │  └── talos-worker-02         │
│  └── talos-cp-03           │                               │
├─────────────────────────────────────────────────────────────┤
│                 Core Infrastructure                          │
│  ├── ArgoCD (GitOps Controller)                            │
│  ├── MetalLB (LoadBalancer Services)                       │
│  ├── Ingress-nginx (HTTP/HTTPS Ingress)                    │
│  ├── cert-manager (TLS Certificates)                       │
│  └── NFS CSI Driver (Persistent Storage)                   │
├─────────────────────────────────────────────────────────────┤
│                    Kubernetes Workloads                      │
│  ├── Media Stack (*arr apps, downloaders)                   │
│  ├── Monitoring (Prometheus, Grafana)                       │
│  └── Home Automation (Home Assistant, etc.)                │
└─────────────────────────────────────────────────────────────┘

External Services:
- Plex Media Server (Dedicated VM with GPU)
- TrueNAS Scale (Storage)
- Active Directory (Authentication)
```

### Resource Allocation

All nodes: **4 vCPU, 8GB RAM, 100GB disk**
- Total cluster: **20 vCPU, 40GB RAM**
- Highly available control plane
- Dedicated worker nodes for workload isolation

### Why Talos Linux?

- **Immutable**: Read-only OS, no SSH, no shell
- **Secure**: Hardened by default, API-only access with mTLS
- **Minimal**: Only what's needed to run Kubernetes
- **Declarative**: Everything configured through YAML

## Prerequisites

- [ ] Proxmox hosts ready
- [ ] Network configured (VLANs, DNS)
- [ ] TrueNAS NFS exports configured
- [ ] Talos Linux CLI (`talosctl`) installed
- [ ] kubectl installed

## Quick Start

### Linux
```bash
# 1. Build custom Talos image with QEMU guest agent
./scripts/build-talos-image.sh

# 2. Deploy VMs in Proxmox, then generate configs
./scripts/generate-configs.sh

# 3. Apply configurations to all nodes
./scripts/apply-configs.sh

# 4. Bootstrap cluster
./scripts/bootstrap-cluster.sh

# 5. Verify deployment
./scripts/verify-access.sh
```

### Windows
```powershell
# 1. Build custom Talos image with QEMU guest agent
.\scripts\build-talos-image.ps1

# 2. Deploy VMs in Proxmox, then generate configs
.\scripts\generate-configs.ps1

# 3. Apply configurations to all nodes
.\scripts\apply-configs.ps1

# 4. Bootstrap cluster
.\scripts\bootstrap-cluster.ps1

# 5. Verify deployment
.\scripts\verify-access.ps1
```

## Documentation

📖 **[Cross-Platform Deployment Guide](docs/cross-platform-guide.md)** - Complete instructions for both Linux and Windows

📋 **[Migration Tracker](MIGRATION_TRACKER.md)** - Phase-by-phase deployment checklist

🤖 **[Claude Code Integration](CLAUDE.md)** - Guide for using with Claude Code

📚 **[Detailed Setup Guide](docs/01-initial-setup.md)** - In-depth deployment instructions

🚀 **[GitOps Setup with ArgoCD](docs/02-gitops-setup.md)** - ArgoCD deployment and configuration

🔧 **[Troubleshooting Guide](docs/03-troubleshooting.md)** - Common issues and solutions

## Project Structure

```
.
├── talos/              # Talos configuration files
│   ├── patches/        # Node-specific configurations
│   └── schematic.yaml  # Custom image definition
├── kubernetes/         # Kubernetes manifests
│   ├── core/          # Core infrastructure
│   ├── apps/          # Applications
│   └── gitops/        # GitOps controllers
├── scripts/           # Cross-platform helper scripts
│   ├── *.sh          # Linux/bash scripts
│   └── *.ps1         # Windows/PowerShell scripts
└── docs/              # Documentation
```

## IP Allocations

| Node | IP Address | Role |
|------|------------|------|
| talos-cp-01 | 192.168.1.241 | Control Plane |
| talos-cp-02 | 192.168.1.242 | Control Plane |
| talos-cp-03 | 192.168.1.243 | Control Plane |
| talos-worker-01 | 192.168.1.244 | Worker |
| talos-worker-02 | 192.168.1.245 | Worker |
| VIP | 192.168.1.240 | Kubernetes API |

## Cross-Platform Scripts

All deployment operations are available on both platforms:

| Operation | Linux | Windows | Description |
|-----------|-------|---------|-------------|
| Build Image | `build-talos-image.sh` | `build-talos-image.ps1` | Create custom Talos ISO |
| Generate Configs | `generate-configs.sh` | `generate-configs.ps1` | Create cluster configurations |
| Apply Configs | `apply-configs.sh` | `apply-configs.ps1` | Configure all nodes |
| Bootstrap | `bootstrap-cluster.sh` | `bootstrap-cluster.ps1` | Initialize Kubernetes |
| Verify | `verify-access.sh` | `verify-access.ps1` | Check cluster health |
| Setup kubectl | `setup-kubectl.sh` | `setup-kubectl.ps1` | Configure kubectl access |
| Execute Commands | `cluster-exec.sh` | `cluster-exec.ps1` | Run commands on nodes |

## Key Features

### Security First
- **No SSH access** - All management via Talos API
- **Immutable OS** - Read-only filesystem prevents tampering
- **mTLS everywhere** - Secure communication by default
- **Minimal attack surface** - Only Kubernetes components included

### High Availability
- **3 control plane nodes** with automatic leader election
- **Shared VIP** for API server access
- **etcd clustering** with automatic recovery
- **No single points of failure**

### Modern Operations
- **GitOps ready** - Designed for ArgoCD/Flux
- **Declarative configuration** - Everything as code
- **Automated updates** - Built-in update mechanisms
- **Comprehensive monitoring** - Ready for observability stack

## Getting Started

1. **Choose your platform**: Follow the [Cross-Platform Guide](docs/cross-platform-guide.md)
2. **Install prerequisites**: Talos CLI and kubectl
3. **Run the scripts**: Use the appropriate `.sh` or `.ps1` versions
4. **Deploy workloads**: Apply Kubernetes manifests
5. **Set up GitOps**: Configure automated deployments

## Troubleshooting

### Common Issues

1. **Network connectivity**: Ensure VLAN 1200 is configured and firewall allows ports 50000 (Talos) and 6443 (Kubernetes)
2. **VM configuration**: Verify all VMs have correct IP addresses and are running the custom Talos ISO
3. **Bootstrap timing**: Wait for all nodes to be Ready before proceeding to application deployment

### Getting Help

- Check `talosctl health` for cluster status
- Use `verify-access` scripts to test connectivity
- Review logs with `talosctl logs --follow`
- Consult the [Cross-Platform Guide](docs/cross-platform-guide.md) for detailed troubleshooting

## Contributing

This is a personal homelab project, but improvements and suggestions are welcome:

1. Ensure cross-platform compatibility (both Linux and Windows)
2. Test changes on both script formats
3. Update documentation for any new features
4. Follow the existing patterns for error handling and user feedback

## Security Note

⚠️ **Important**: The `secrets.yaml` file contains cluster secrets and should never be committed to version control. Always backup this file securely after generation.
