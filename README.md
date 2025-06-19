# Talos Kubernetes Homelab - Greenfield Deployment

A modern, secure, and production-grade Kubernetes homelab built on Talos Linux.

## Overview

This project deploys a highly available Kubernetes cluster using Talos Linux, designed for running containerized services with enterprise-grade security and operational patterns.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Talos Linux K8s Cluster                   │
├─────────────────────────────────────────────────────────────┤
│  Control Plane (3 nodes)    │  Worker Nodes (optional)      │
│  ├── talos-cp-01           │  ├── talos-worker-01         │
│  ├── talos-cp-02           │  ├── talos-worker-02         │
│  └── talos-cp-03           │  └── talos-worker-03         │
├─────────────────────────────────────────────────────────────┤
│                    Kubernetes Workloads                      │
│  ├── Media Stack (*arr apps, downloaders)                   │
│  ├── Monitoring (Prometheus, Grafana)                       │
│  ├── GitOps (Flux/ArgoCD)                                  │
│  └── Ingress (Traefik/Nginx)                               │
└─────────────────────────────────────────────────────────────┘

External Services:
- Plex Media Server (Dedicated VM with GPU)
- TrueNAS Scale (Storage)
- Active Directory (Authentication)
```

### Why Talos Linux?

- **Immutable**: Read-only OS, no SSH, no shell
- **Secure**: Hardened by default, API-only access with mTLS
- **Minimal**: Only what's needed to run Kubernetes
- **Declarative**: Everything configured through YAML

## Prerequisites

- [ ] Proxmox hosts ready
- [ ] Network configured (VLANs, DNS)
- [ ] TrueNAS NFS exports configured
- [ ] Talos Linux ISO downloaded
- [ ] `talosctl` installed on workstation

## Quick Start

1. **Configure Talos** (see `talos/controlplane.yaml` and `talos/worker.yaml`)
2. **Deploy VMs** using provided Proxmox scripts
3. **Bootstrap cluster** with `talosctl`
4. **Deploy applications** via GitOps

## Project Structure

```
.
├── talos/              # Talos configuration files
├── kubernetes/         # Kubernetes manifests
│   ├── core/          # Core infrastructure
│   ├── apps/          # Applications
│   └── gitops/        # GitOps controllers
├── scripts/           # Helper scripts
└── docs/              # Documentation
```

## IP Allocations

| Node | IP Address | Role |
|------|------------|------|
| talos-cp-01 | 192.168.1.241 | Control Plane |
| talos-cp-02 | 192.168.1.242 | Control Plane |
| talos-cp-03 | 192.168.1.243 | Control Plane |
| VIP | 192.168.1.240 | Kubernetes API |

## Getting Started

See [docs/01-initial-setup.md](docs/01-initial-setup.md) for detailed instructions.
