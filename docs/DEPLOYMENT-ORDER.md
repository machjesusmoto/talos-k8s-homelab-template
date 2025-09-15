# Kubernetes Homelab Deployment Order Guide

This document outlines the critical deployment order for a successful Kubernetes homelab setup. Following this order ensures dependencies are met and prevents common deployment failures.

## Phase 1: Cluster Bootstrap
**Prerequisites**: Talos nodes configured and running

1. **Generate and Apply Talos Configurations**
   ```bash
   ./scripts/generate-configs.sh
   ./scripts/apply-configs.sh
   ./scripts/bootstrap-cluster.sh
   ```

2. **Verify Cluster Access**
   ```bash
   ./scripts/verify-access.sh
   kubectl get nodes
   ```

## Phase 2: Core Infrastructure (Required)
**Must be deployed in this exact order**

### 1. kube-proxy (Critical - First Component)
**Why**: Talos with `proxy.disabled: true` requires manual kube-proxy deployment for service routing
```bash
kubectl apply -k kubernetes/gitops/infrastructure/kube-proxy/
```

### 2. NFS CSI Driver
**Why**: Required for persistent volume claims used by many applications
```bash
kubectl apply -k kubernetes/gitops/infrastructure/nfs-csi/
```

### 3. MetalLB
**Why**: Provides LoadBalancer service type for bare metal clusters
```bash
kubectl apply -k kubernetes/gitops/infrastructure/metallb/
# Wait for controller to be ready
kubectl wait --for=condition=ready pod -l app=metallb,component=controller -n metallb-system --timeout=300s
```

### 4. Traefik IngressClass
**Why**: Required before any Ingress resources can be created
```bash
kubectl apply -f kubernetes/apps/traefik/ingressclass.yaml
```

### 5. cert-manager
**Why**: Manages SSL certificates for HTTPS services
```bash
kubectl apply -k kubernetes/gitops/infrastructure/cert-manager/
# Wait for webhooks to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=webhook -n cert-manager --timeout=300s
```

### 6. Ingress Controller (NGINX or Traefik)
**Why**: Routes external traffic to services
```bash
kubectl apply -k kubernetes/gitops/infrastructure/ingress-nginx/
# OR for Traefik
kubectl apply -k kubernetes/gitops/infrastructure/traefik/
```

## Phase 3: GitOps Setup (Recommended)
**Deploy ArgoCD for automated GitOps management**

```bash
# Deploy ArgoCD
kubectl apply -k kubernetes/gitops/argocd/

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Apply root application (manages all other apps)
kubectl apply -f kubernetes/gitops/applications/root-app.yaml
```

## Phase 4: Security and Networking

### 1. Network Policy Controller (If using Flannel CNI)
**Important**: Flannel does not enforce network policies by default!
Options:
- Install Calico for network policy enforcement
- Install kube-router as a network policy controller
- Use a different CNI that supports network policies

### 2. VPN Services (Gluetun)
**Deploy before download clients if VPN protection is required**
```bash
# Create VPN credentials secret first
kubectl create namespace gluetun
kubectl apply -f kubernetes/apps/gluetun/vpn-secret-template.yaml  # Edit with your credentials

# Deploy Gluetun
kubectl apply -k kubernetes/apps/gluetun/
```

## Phase 5: Storage Classes
**Configure storage classes for different application needs**

```yaml
# Example: NFS storage class for media
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-media
provisioner: nfs.csi.k8s.io
parameters:
  server: 192.168.1.100  # Your NFS server
  share: /mnt/pool/media
```

## Phase 6: Applications

### Deploy Order for Media Stack
1. **Namespace Creation**
   ```bash
   kubectl create namespace downloads
   kubectl create namespace media
   kubectl create namespace automation
   ```

2. **Download Clients** (with VPN if configured)
   - qBittorrent
   - NZBget/SABnzbd

3. **Media Automation**
   - Prowlarr (indexer management)
   - Radarr (movies)
   - Sonarr (TV shows)
   - Lidarr (music)
   - Bazarr (subtitles)

4. **Media Servers**
   - Plex/Jellyfin/Emby

## Common Deployment Issues and Solutions

### Issue 1: Ingress Returns 404
**Cause**: Missing IngressClass
**Solution**: Create Traefik IngressClass before deploying any Ingress resources
```bash
kubectl apply -f kubernetes/apps/traefik/ingressclass.yaml
```

### Issue 2: Pods Stuck in Pending
**Cause**: No available storage or incorrect storage class
**Solution**: Verify NFS CSI driver is running and storage classes exist
```bash
kubectl get storageclass
kubectl get pv
kubectl describe pod <pending-pod>
```

### Issue 3: Network Policies Not Working
**Cause**: Flannel CNI doesn't enforce network policies
**Solution**: Install a network policy controller or use a different CNI

### Issue 4: Certificate Challenges Failing
**Cause**: DNS provider not configured or API token issues
**Solution**: Verify cert-manager ClusterIssuer configuration and API tokens

### Issue 5: Services Unreachable
**Cause**: kube-proxy not deployed (with Talos proxy.disabled: true)
**Solution**: Deploy kube-proxy as the first infrastructure component

## Verification Commands

After each phase, verify successful deployment:

```bash
# Check all pods are running
kubectl get pods -A | grep -v Running | grep -v Completed

# Check services have endpoints
kubectl get endpoints -A

# Check ingress resources
kubectl get ingress -A

# Check certificates
kubectl get certificates -A

# Check for events indicating issues
kubectl get events -A --field-selector type=Warning
```

## Rollback Procedures

If deployment fails:

1. **Delete in reverse order**
   ```bash
   # Example: Remove application before infrastructure
   kubectl delete -k kubernetes/apps/media-stack/
   kubectl delete -k kubernetes/gitops/infrastructure/cert-manager/
   ```

2. **Clean up stuck resources**
   ```bash
   # Force delete stuck namespaces
   kubectl delete namespace <namespace> --force --grace-period=0
   ```

3. **Reset and retry**
   - Fix configuration issues
   - Reapply in correct order

## Important Notes

1. **Never skip kube-proxy deployment** when using Talos with proxy disabled
2. **Always create IngressClass** before deploying Ingress resources
3. **Verify each component** is ready before proceeding to the next
4. **Network policies require a controller** - Flannel alone won't enforce them
5. **VPN protection for download clients** requires special configuration (sidecar or proxy)
6. **GitOps deployment order** is managed by ArgoCD sync waves and dependencies