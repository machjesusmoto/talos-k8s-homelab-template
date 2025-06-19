# K8s Homelab Migration from Docker Swarm

This repository contains all configurations, scripts, and documentation for migrating from Docker Swarm to Kubernetes.

## Project Structure

```
k8s-homelab-migration/
├── ansible/                 # Ansible playbooks and inventory
│   ├── inventory/          # Host definitions
│   └── playbooks/          # Automation playbooks
├── apps/                   # Application manifests
│   ├── infrastructure/     # Core infrastructure apps
│   ├── media/             # Media stack (*arr apps)
│   ├── networking/        # Network apps (VPN, etc)
│   └── monitoring/        # Monitoring stack
├── charts/                # Helm charts
├── clusters/              # Cluster-specific configs
│   ├── development/       # Dev cluster
│   ├── test/             # Test cluster
│   └── production/       # Production cluster
├── scripts/              # Helper scripts
├── storage/              # Storage configurations
├── traefik/              # Traefik ingress configs
└── argocd/               # ArgoCD GitOps configs
```

## Migration Phases

### Phase 0: Infrastructure Prerequisites ✅
- [ ] Configure SSH key-based authentication on all hosts
- [ ] Setup passwordless sudo
- [ ] Verify Ansible connectivity

### Phase 1: Dev Cluster Setup (Week 1)
- [ ] Install K3s on dev nodes
- [ ] Configure kubectl access
- [ ] Deploy NFS provisioner
- [ ] Install Traefik ingress
- [ ] Deploy test application

### Phase 2: Learn & Experiment (Week 2-3)
- [ ] Deploy media stack to dev
- [ ] Test Helm charts
- [ ] Configure Gluetun VPN
- [ ] Test data migration
- [ ] Setup monitoring

### Phase 3: Production Cluster (Week 4)
- [ ] Install K3s on production nodes
- [ ] Configure HA control plane
- [ ] Setup MetalLB
- [ ] Configure production storage
- [ ] Validate cluster health

### Phase 4: Application Migration (Week 5-6)
- [ ] Migrate monitoring apps
- [ ] Migrate download stack
- [ ] Migrate media apps
- [ ] Update DNS records
- [ ] Decommission Swarm

### Phase 5: GitOps & Automation (Week 7-8)
- [ ] Deploy ArgoCD
- [ ] Create Git repository structure
- [ ] Configure Renovate
- [ ] Setup CI/CD pipeline
- [ ] Document operations

## Quick Start

1. Ensure SSH key access is configured:
   ```bash
   ./scripts/verify-access.sh
   ```

2. Install K3s on development cluster:
   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts.yml playbooks/install-k3s-dev.yml
   ```

3. Configure kubectl:
   ```bash
   ./scripts/setup-kubectl.sh dev
   ```

## Important IPs

### Development Cluster
- docker-dev-01: 192.168.1.244
- docker-dev-02: 192.168.1.245
- docker-dev-03: 192.168.1.246

### Test Cluster  
- docker-test-01: 192.168.1.251
- docker-test-02: 192.168.1.252
- docker-test-03: 192.168.1.253

### Production Cluster
- docker-prod-01: 192.168.1.241
- docker-prod-02: 192.168.1.242
- docker-prod-03: 192.168.1.243
- Keepalived VIP: 192.168.1.240

### Storage
- TrueNAS: 192.168.1.12
- NFS Base Path: /mnt/rz3_storage/primary_dataset/media
