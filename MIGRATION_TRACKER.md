# Talos Kubernetes Deployment Tracker

## Phase 1: Preparation ⏳
- [ ] Download talosctl for Windows
- [ ] Download Talos Linux ISO
- [ ] Generate custom ISO with QEMU guest agent
- [ ] Upload ISO to Proxmox storage
- [ ] Review network requirements (VLANs, IPs)
- [ ] Ensure DNS is configured for cluster

## Phase 2: VM Creation 🖥️
### Control Plane Nodes
- [ ] Create talos-cp-01 VM (192.168.1.241)
  - [ ] 4 CPU, 8GB RAM, 100GB disk
  - [ ] Network: VLAN 1200
  - [ ] Boot from Talos ISO
- [ ] Create talos-cp-02 VM (192.168.1.242)
  - [ ] Same specifications
- [ ] Create talos-cp-03 VM (192.168.1.243)
  - [ ] Same specifications

### Worker Nodes
- [ ] Create talos-worker-01 VM (192.168.1.244)
  - [ ] 4 CPU, 8GB RAM, 100GB disk
  - [ ] Network: VLAN 1200
  - [ ] Boot from Talos ISO
- [ ] Create talos-worker-02 VM (192.168.1.245)
  - [ ] Same specifications

### All VMs
- [ ] Start all VMs (they'll wait for configuration)
- [ ] Verify serial console access in Proxmox

## Phase 3: Generate Configurations 🔧
- [ ] Run `./scripts/generate-configs.sh`
- [ ] Back up `secrets.yaml` securely!
- [ ] Review generated configurations
- [ ] Verify network settings in patches

## Phase 4: Deploy Cluster 🚀
- [ ] Run `./scripts/apply-configs.sh`
- [ ] Wait for all 5 nodes to accept configuration
- [ ] Run `./scripts/bootstrap-cluster.sh`
- [ ] Verify cluster health with `talosctl health`
- [ ] Test `kubectl get nodes` shows all 5 nodes

## Phase 5: Core Infrastructure 🏗️
- [ ] Deploy namespaces
- [ ] Deploy NFS CSI driver
- [ ] Deploy MetalLB for LoadBalancer services
- [ ] Deploy Ingress Controller (Traefik/Nginx)
- [ ] Deploy cert-manager for TLS

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
