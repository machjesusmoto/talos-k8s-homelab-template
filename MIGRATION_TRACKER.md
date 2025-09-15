# Talos Kubernetes Deployment Tracker

## Phase 1: Preparation ⏳

- [X] Download talosctl for Windows
- [X] Download Talos Linux ISO
- [X] Generate custom ISO with QEMU guest agent
- [X] Upload ISO to Proxmox storage
- [X] Review network requirements (VLANs, IPs)
- [X] Ensure DNS is configured for cluster

## Phase 2: VM Creation 🖥️

### Control Plane Nodes

- [X] Create talos-cp-01 VM (192.168.1.241)
  - [X] 4 CPU, 8GB RAM, 100GB disk
  - [X] Network: VLAN 1200
  - [X] Boot from Talos ISO
- [X] Create talos-cp-02 VM (192.168.1.242)
  - [X] Same specifications
- [X] Create talos-cp-03 VM (192.168.1.243)
  - [X] Same specifications

### Worker Nodes

- [X] Create talos-worker-01 VM (192.168.1.244)
  - [X] 4 CPU, 8GB RAM, 100GB disk
  - [X] Network: VLAN 1200
  - [X] Boot from Talos ISO
- [X] Create talos-worker-02 VM (192.168.1.245)
  - [X] Same specifications

### All VMs

- [X] Start all VMs (they'll wait for configuration)
- [X] Verify serial console access in Proxmox

## Phase 3: Generate Configurations 🔧

- [X] Run `./scripts/generate-configs.sh`
- [X] Back up `secrets.yaml` securely!
- [X] Review generated configurations
- [X] Verify network settings in patches

## Phase 4: Deploy Cluster 🚀

- [X] Run `./scripts/apply-configs.sh`
- [X] Wait for all 5 nodes to accept configuration
- [X] Run `./scripts/bootstrap-cluster.sh`
- [X] Verify cluster health with `talosctl health`
- [X] Test `kubectl get nodes` shows all 5 nodes

## Phase 5: Core Infrastructure 🏗️

- [X] Deploy namespaces
- [X] Deploy NFS CSI driver
- [X] Deploy MetalLB for LoadBalancer services
- [X] Deploy Ingress Controller (Traefik/Nginx)
- [X] Deploy cert-manager for TLS

## Phase 6: GitOps Setup 🔄

- [ ] Choose GitOps tool (Flux or ArgoCD)
- [ ] Deploy GitOps controller
- [ ] Configure repository sync
- [ ] Test automated deployment

## Phase 7: Application Deployment 📦

- [ ] Deploy monitoring stack (Prometheus/Grafana)
- [ ] Deploy media applications
  - [ ] Sonarr
  - [ ] Radarr
  - [ ] Prowlarr
  - [ ] Overseerr
  - [ ] qBittorrent (with Gluetun)
  - [ ] NZBGet
- [ ] Configure application networking

## Phase 8: Production Readiness ✅

- [ ] Configure backups
- [ ] Set up monitoring alerts
- [ ] Document runbooks
- [ ] Test disaster recovery
- [ ] Performance tuning

## Commands Quick Reference

```bash
# Generate custom ISO
./scripts/build-talos-image.ps1

# Generate configs
./scripts/generate-configs.sh

# Apply to nodes
./scripts/apply-configs.sh

# Bootstrap cluster
./scripts/bootstrap-cluster.sh

# Check cluster health
talosctl health

# Get nodes status
kubectl get nodes -o wide

# Watch pods
kubectl get pods -A -w
```

## Resource Summary

**Total Cluster Resources:**

- vCPU: 20 cores
- RAM: 40 GB
- Storage: 500 GB
- Nodes: 5 (3 control plane, 2 workers)

**Available for Workloads:**

- vCPU: ~16 cores
- RAM: ~30 GB (leaving 2GB per node for OS/K8s)

## Important Notes

⚠️ **Security**: Keep `secrets.yaml` secure - it contains all cluster secrets!

📝 **DNS**: Ensure all nodes can resolve each other's hostnames

🔧 **Troubleshooting**: Use `talosctl logs -n <node-ip>` to debug issues

🚀 **Next Steps**: After cluster is running, focus on GitOps for all deployments

💡 **Scaling**: Easy to add more workers later if needed
