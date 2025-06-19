# Migration Progress Tracker

## Phase 0: Infrastructure Prerequisites
- [ ] Generate SSH keys on MOTOSTATION
- [ ] Create Ansible vault: `cd ansible && ansible-vault create vault.yml`
- [ ] Add passwords to vault:
  ```yaml
  vault_ssh_password: "your-current-password"
  vault_sudo_password: "your-current-sudo-password"
  ```
- [ ] Run `ansible-playbook -i inventory/hosts-initial.yml playbooks/setup-ssh-keys.yml --ask-vault-pass`
- [ ] Verify with `./scripts/verify-access.sh`

## Phase 1: Dev Cluster Setup
- [ ] Run `ansible-playbook -i inventory/hosts.yml playbooks/prepare-nodes.yml`
- [ ] Run `ansible-playbook -i inventory/hosts.yml playbooks/install-k3s-dev.yml`
- [ ] Setup kubectl with `./scripts/setup-kubectl.sh dev`
- [ ] Deploy NFS provisioner: `kubectl apply -f storage/nfs-provisioner.yml`
- [ ] Add Traefik helm repo: `helm repo add traefik https://helm.traefik.io/traefik`
- [ ] Install Traefik: `helm install traefik traefik/traefik -n traefik --create-namespace -f traefik/values-dev.yml`
- [ ] Deploy test app: `kubectl apply -f apps/media/overseerr/overseerr-dev.yml`
- [ ] Verify app is running: `kubectl get all -n media`

## Phase 2: Learn & Experiment
- [ ] Create Helm charts for media stack
- [ ] Deploy Gluetun VPN configuration
- [ ] Test data migration procedures
- [ ] Set up Prometheus/Grafana monitoring

## Phase 3: Production Cluster
- [ ] Install K3s on production nodes
- [ ] Configure HA with embedded etcd
- [ ] Deploy MetalLB for load balancing
- [ ] Configure production storage and networking

## Phase 4: Application Migration
- [ ] Migrate CheckMK
- [ ] Migrate download stack (gluetun, qbittorrent, nzbget)
- [ ] Migrate *arr applications
- [ ] Update DNS records
- [ ] Decommission Docker Swarm

## Phase 5: GitOps & Automation
- [ ] Deploy ArgoCD
- [ ] Create Git repository structure
- [ ] Configure Renovate bot
- [ ] Set up CI/CD pipelines

## Commands Quick Reference

### Ansible Commands
```bash
# Setup SSH keys (if needed)
ansible-playbook -i inventory/hosts-initial.yml playbooks/setup-ssh-keys.yml --ask-vault-pass

# Prepare nodes
ansible-playbook -i inventory/hosts.yml playbooks/prepare-nodes.yml

# Install K3s
ansible-playbook -i inventory/hosts.yml playbooks/install-k3s-dev.yml
```

### Kubectl Commands
```bash
# Setup kubectl
./scripts/setup-kubectl.sh dev

# Get nodes
kubectl get nodes

# Get all resources
kubectl get all --all-namespaces

# Watch pod creation
kubectl get pods -w -n media
```

### Helm Commands
```bash
# Add repo
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

# Install
helm install traefik traefik/traefik -n traefik --create-namespace -f traefik/values-dev.yml

# List releases
helm list --all-namespaces
```
