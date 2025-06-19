# Talos Kubernetes Deployment Tracker

## Phase 1: Preparation ⏳
- [ ] Download talosctl for Windows
- [ ] Download Talos Linux ISO
- [ ] Upload ISO to Proxmox storage
- [ ] Review network requirements (VLANs, IPs)
- [ ] Ensure DNS is configured for cluster

## Phase 2: VM Creation 🖥️
- [ ] Create talos-cp-01 VM (192.168.1.241)
  - [ ] 4 CPU, 8GB RAM, 100GB disk
  - [ ] Network: VLAN 1200
  - [ ] Boot from Talos ISO
- [ ] Create talos-cp-02 VM (192.168.1.242)
  - [ ] Same specifications
- [ ] Create talos-cp-03 VM (192.168.1.243)
  - [ ] Same specifications
- [ ] Start all VMs (they'll wait for configuration)

## Phase 3: Generate Configurations 🔧
- [ ] Run `./scripts/generate-configs.sh`
- [ ] Back up `secrets.yaml` securely!
- [ ] Review generated configurations
- [ ] Verify network settings in patches

## Phase 4: Deploy Cluster 🚀
- [ ] Run `./scripts/apply-configs.sh`
- [ ] Wait for nodes to accept configuration
- [ ] Run `./scripts/bootstrap-cluster.sh`
- [ ] Verify cluster health

## Phase 5: Core Infrastructure 🏗️
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
  - [ ] qBittorrent
  - [ ] NZBGet
- [ ] Configure application networking

## Phase 8: Production Readiness ✅
- [ ] Configure backups
- [ ] Set up monitoring alerts
- [ ] Document runbooks
- [ ] Test disaster recovery

## Commands Quick Reference

```bash
# Generate configs
./scripts/generate-configs.sh

# Apply to nodes
./scripts/apply-configs.sh

# Bootstrap cluster
./scripts/bootstrap-cluster.sh

# Check cluster health
talosctl health

# Get nodes status
kubectl get nodes

# Watch pods
kubectl get pods -A -w
```

## Important Notes

⚠️ **Security**: Keep `secrets.yaml` secure - it contains all cluster secrets!

📝 **DNS**: Ensure all nodes can resolve each other's hostnames

🔧 **Troubleshooting**: Use `talosctl logs -n <node-ip>` to debug issues

🚀 **Next Steps**: After cluster is running, focus on GitOps for all deployments
