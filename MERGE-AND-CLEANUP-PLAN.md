# Action Plan: Merge Template to Production and Clean Secrets

## Overview
This plan outlines the steps to merge talos-k8s-homelab-template into k8s-homelab-production, clean sensitive data from both repositories, and redeploy with fresh secrets.

## Pre-requisites
- Access to both repositories
- Backup of any production-specific configurations
- Time for a full cluster rebuild

## Step-by-Step Process

### 1. Backup Current State
```bash
# Create backups of both repos
cd ~
tar -czf template-backup-$(date +%Y%m%d).tar.gz talos-k8s-homelab-template/
tar -czf production-backup-$(date +%Y%m%d).tar.gz k8s-homelab-production/
```

### 2. Merge Template into Production
```bash
# Navigate to production repo
cd ~/k8s-homelab-production

# Add template as remote
git remote add template https://github.com/machjesusmoto/talos-k8s-homelab-template.git
git fetch template

# Merge template changes
git checkout main
git merge template/main --allow-unrelated-histories

# Resolve any conflicts (favor template versions for non-production-specific files)
# Keep production-specific: ArgoCD apps, any custom configurations
# Take from template: Scripts, documentation, examples
```

### 3. Remove Secrets from Working Directory
```bash
# In production repo
rm -f secrets.yaml
rm -f kubernetes/apps/gluetun/vpn-secret.yaml
rm -f kubernetes/apps/traefik/cloudflare-secret.yaml
rm -f talos/controlplane-*.yaml
rm -f talos/worker-*.yaml
find . -name "*-secret.yaml" -not -name "*-template.yaml" -delete

# Verify removal
git status
```

### 4. Copy and Run Cleanup Script
```bash
# Copy updated cleanup script from template
cp ~/talos-k8s-homelab-template/remove-sensitive-files-modern.sh .

# Run cleanup on production repo
chmod +x remove-sensitive-files-modern.sh
./remove-sensitive-files-modern.sh
# Type 'yes' when prompted

# After cleanup, re-add remote and push
git remote add origin https://github.com/yourusername/k8s-homelab-production.git
git push origin --force --all
git push origin --force --tags
```

### 5. Clean Template Repository
```bash
# Go to template repo
cd ~/talos-k8s-homelab-template

# Run the same cleanup
./remove-sensitive-files-modern.sh
# Type 'yes' when prompted

# Re-add remote and force push
git remote add origin https://github.com/machjesusmoto/talos-k8s-homelab-template.git
git push origin --force --all
git push origin --force --tags
```

### 6. Regenerate Secrets for Production
```bash
cd ~/k8s-homelab-production

# Generate new Talos secrets
./scripts/generate-configs.sh

# Create new VPN secret from template
cp kubernetes/apps/gluetun/vpn-secret-template.yaml kubernetes/apps/gluetun/vpn-secret.yaml
# Edit with your VPN credentials

# Create other necessary secrets from templates
# Update any API tokens, passwords, etc.
```

### 7. Destroy and Rebuild Cluster
```bash
# From Proxmox or your hypervisor:
# 1. Shut down all Kubernetes VMs
# 2. Reset VMs to boot from Talos ISO

# From your workstation:
cd ~/k8s-homelab-production

# Apply new configurations
./scripts/apply-configs.sh

# Bootstrap cluster
./scripts/bootstrap-cluster.sh

# Verify cluster
./scripts/verify-access.sh
```

### 8. Deploy Applications
```bash
# Deploy ArgoCD
kubectl apply -k kubernetes/gitops/argocd/

# Wait for ArgoCD
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Deploy root application
kubectl apply -f kubernetes/gitops/applications/root-app.yaml
```

### 9. Post-Deployment Verification
```bash
# Check all pods
kubectl get pods -A

# Verify no old secrets exist
git log --all --full-history -- secrets.yaml
# Should return nothing

# Test applications
# - Access ArgoCD UI
# - Verify ingress/certificates
# - Test VPN connectivity
```

## Important Notes

1. **GitHub Caching**: Even after force push, GitHub may cache old commits for ~90 days. Consider making repos private temporarily.

2. **Forks/Clones**: If repos were public, notify any users who may have forked to clean their copies.

3. **New Secrets**: Store new secrets.yaml backup securely (not in Git!)

4. **Timing**: This process will cause downtime. Plan accordingly.

5. **Verification**: After cleanup, verify secrets are gone:
   ```bash
   # This should return empty
   git log --all --full-history -- secrets.yaml
   ```

## Rollback Plan
If issues occur:
1. Restore from backups created in step 1
2. Use old secrets.yaml from backup (if cluster wasn't rebuilt yet)
3. Check backup branches: `git branch -a | grep backup`

## Success Criteria
- [ ] Both repositories have clean history (no secrets)
- [ ] Production cluster running with new secrets
- [ ] All applications deployed and functional
- [ ] No sensitive data in Git history
- [ ] Documentation updated with lessons learned