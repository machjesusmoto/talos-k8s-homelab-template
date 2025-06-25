# Application Deployment Guide

## Overview

This guide covers deploying applications to the Kubernetes homelab using GitOps with ArgoCD. Applications automatically receive SSL certificates via DNS-01 challenge and are managed through Git repositories.

## Deployment Architecture

### GitOps Flow
1. **Code**: Application manifests in `kubernetes/apps/`
2. **Commit**: Push changes to Git repository
3. **Deploy**: ArgoCD automatically syncs applications
4. **SSL**: cert-manager issues certificates automatically
5. **Access**: Applications available at `<app>.k8s.dttesting.com`

### Directory Structure
```
kubernetes/
├── apps/                           # Application definitions
│   └── <app-name>/
│       ├── namespace.yaml          # Application namespace
│       ├── deployment.yaml         # Application deployment
│       ├── service.yaml            # Service definition
│       ├── ingress.yaml            # Ingress with SSL
│       ├── configmap.yaml          # Configuration (optional)
│       └── kustomization.yaml      # Kustomize configuration
└── gitops/
    └── applications/
        ├── <app-name>.yaml         # ArgoCD application
        └── kustomization.yaml      # Application registry
```

## Deployed Applications

### Homer Dashboard ✅
- **URL**: https://homer.k8s.dttesting.com
- **Description**: Homelab dashboard and application launcher
- **Status**: Deployed with automatic SSL certificate
- **Features**: 
  - Responsive dashboard
  - Service discovery
  - Dark/Light theme
  - Custom configuration

## Deploying New Applications

### 1. Create Application Structure

```bash
# Create application directory
mkdir -p kubernetes/apps/<app-name>
cd kubernetes/apps/<app-name>
```

### 2. Create Namespace
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <app-name>
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/part-of: homelab
```

### 3. Create Deployment
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: <app-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: <app-name>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <app-name>
    spec:
      containers:
      - name: <app-name>
        image: <image:tag>
        ports:
        - containerPort: <port>
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

### 4. Create Service
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-name>
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app.kubernetes.io/name: <app-name>
```

### 5. Create Ingress with SSL
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-name>
  namespace: <app-name>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - <app-name>.k8s.dttesting.com
    secretName: <app-name>-tls
  rules:
  - host: <app-name>.k8s.dttesting.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <app-name>
            port:
              number: 80
```

### 6. Create Kustomization
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: <app-name>

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml

commonLabels:
  app.kubernetes.io/name: <app-name>
  app.kubernetes.io/part-of: homelab
```

### 7. Create ArgoCD Application
```yaml
# kubernetes/gitops/applications/<app-name>.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/machjesusmoto/k8s-homelab-migration.git
    targetRevision: main
    path: kubernetes/apps/<app-name>
  destination:
    server: https://kubernetes.default.svc
    namespace: <app-name>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
```

### 8. Register Application with ArgoCD
```yaml
# Add to kubernetes/gitops/applications/kustomization.yaml
resources:
  - core-infrastructure.yaml
  - homer.yaml
  - <app-name>.yaml  # Add this line
```

### 9. Deploy Application
```bash
# Commit and push changes
git add kubernetes/apps/<app-name>/ kubernetes/gitops/applications/
git commit -m "Add <app-name> application"
git push origin main

# ArgoCD will automatically detect and deploy the application
```

## Verification Commands

### Check Application Status
```bash
# View all applications
kubectl get applications -n argocd

# Get detailed application info
argocd app get <app-name>

# Check application health
kubectl get pods -n <app-name>
kubectl get svc -n <app-name>
kubectl get ingress -n <app-name>
```

### Check SSL Certificate
```bash
# Check certificate status
kubectl get certificates -n <app-name>
kubectl describe certificate <app-name>-tls -n <app-name>

# Check DNS challenges (if certificate pending)
kubectl get challenges -n <app-name>
kubectl describe challenge <challenge-name> -n <app-name>
```

### Test Application Access
```bash
# Port forward for local testing
kubectl port-forward -n <app-name> svc/<app-name> 8080:80

# Test HTTP access
curl http://localhost:8080

# Test HTTPS access (once certificate is ready)
curl https://<app-name>.k8s.dttesting.com
```

## DNS Configuration

### Cloudflare DNS Records
For each application, ensure DNS record exists:
```
Type: A or CNAME
Name: <app-name>.k8s.dttesting.com
Value: Your home IP or CNAME to dynamic DNS
```

### Critical: Split-Brain DNS Configuration
If using an internal domain that's also managed by Cloudflare (common homelab setup):

**Problem**: Internal DNS server (Unbound, pfSense) intercepts DNS-01 ACME challenges, preventing cert-manager from validating certificates.

**Solution**: Configure DNS forwarding for the subdomain to Cloudflare:

**For Unbound DNS**:
```
forward-zone:
    name: "k8s.dttesting.com"
    forward-addr: 1.1.1.1
    forward-addr: 1.0.0.1
```

**For pfSense DNS Resolver**:
- Services > DNS Resolver > General Settings
- Add Domain Override: `k8s.dttesting.com` → `1.1.1.1`

**Verification**:
```bash
# Test from inside your network
dig _acme-challenge.test.k8s.dttesting.com TXT
# Should query Cloudflare, not return NXDOMAIN
```

### Local DNS (Optional)
For local access without internet routing:
```
<app-name>.k8s.dttesting.com → 192.168.1.200 (NGINX LoadBalancer IP)
```

## SSL Certificate Management

### Automatic Certificate Issuance
- Certificates are automatically requested when ingress is created
- DNS-01 challenge validates domain ownership via Cloudflare
- Production certificates from Let's Encrypt
- Certificates auto-renew before expiration

### Certificate Troubleshooting

#### Basic Certificate Debugging
```bash
# Check ClusterIssuer status
kubectl get clusterissuers

# Debug certificate issues
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate status and challenges
kubectl get certificates -A
kubectl get challenges -A
kubectl describe challenge <challenge-name> -n <namespace>
```

#### DNS-01 Challenge Troubleshooting
```bash
# 1. Verify certificate is requesting DNS-01 challenge
kubectl describe certificate <cert-name> -n <namespace>

# 2. Check challenge status - look for "DNS record not yet propagated"
kubectl describe challenge <challenge-name> -n <namespace>

# 3. Test DNS resolution from inside your network
dig _acme-challenge.<app-name>.k8s.dttesting.com TXT

# 4. If DNS resolution fails, check your internal DNS configuration
# 5. Restart certificate process after fixing DNS
kubectl delete certificate <cert-name> -n <namespace>
# Certificate will be automatically recreated
```

#### Manual Certificate Testing
```bash
# Create test certificate to verify issuer configuration
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: default
spec:
  secretName: test-cert-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  dnsNames:
  - test.k8s.dttesting.com
EOF

# Monitor challenge progress
kubectl get challenges -w
```

## Available Namespaces

Pre-configured namespaces for common application types:
- `homer` - Dashboard and landing page
- `monitoring` - Prometheus, Grafana, etc.
- `media` - Plex, Jellyfin, etc.
- `downloads` - Download clients and managers
- `gitops` - ArgoCD and GitOps tools

## Best Practices

### Security
- Use non-root containers when possible
- Set resource limits and requests
- Use readOnlyRootFilesystem when possible
- Drop unnecessary capabilities

### Configuration Management
- Use ConfigMaps for configuration files
- Use Secrets for sensitive data
- Mount configurations as volumes, not environment variables

### Resource Management
- Set appropriate resource requests and limits
- Use horizontal pod autoscaling for variable workloads
- Consider persistent volumes for stateful applications

### GitOps Workflow
- Test changes in staging ClusterIssuer first
- Use meaningful commit messages
- Review ArgoCD sync status after deployment
- Monitor application health and resource usage

## Common Deployment Issues

### PVC Storage Class Conflicts

**Issue**: ArgoCD sync fails with "PersistentVolumeClaim is invalid: spec: Forbidden: spec is immutable"

**Cause**: Application was initially deployed with a different storage class (often empty `""`) but configuration now specifies `nfs-apps`

**Solution**:
1. Delete the application deployments to release PVC locks
2. Delete the problematic PVCs 
3. Trigger ArgoCD sync to recreate with correct storage class

```bash
# Example fix for any application with PVC issues
kubectl delete deployment <app-name> -n <namespace>
kubectl delete pvc <pvc-name> -n <namespace>
~/bin/argocd app sync <app-name>
```

**Prevention**: Always specify the correct storage class in initial deployments

### DNS-01 Certificate Challenges

**Issue**: Certificates stuck in "DNS record not yet propagated" state

**Cause**: Internal DNS intercepting queries for your domain instead of using Cloudflare

**Solution**: Configure DNS forwarding for your subdomain to Cloudflare (see troubleshooting guide)

### Application Sync Failures

**Issue**: ArgoCD shows "OutOfSync" or sync errors

**Common Causes & Solutions**:
- **Resource conflicts**: Delete existing resources and resync
- **Image pull errors**: Check image names and registry access
- **Configuration errors**: Validate YAML syntax and Kubernetes manifests
- **Resource quotas**: Check namespace resource limits

```bash
# Force sync with pruning
~/bin/argocd app sync <app-name> --force --prune

# Check application details
kubectl describe application <app-name> -n argocd
```

## Example: Complete Application Deployment

The Homer dashboard deployment demonstrates all concepts:

1. **Structured manifests** in `kubernetes/apps/homer/`
2. **Automatic SSL** with letsencrypt-prod
3. **GitOps management** via ArgoCD
4. **Configuration management** with ConfigMap
5. **Security best practices** with non-root containers
6. **Resource constraints** and health checks

## Current Application Status

### Successfully Deployed Applications

| Application | Status | URL | Storage | Notes |
|-------------|--------|-----|---------|-------|
| **Homer** | ✅ Healthy | https://homer.k8s.dttesting.com | ConfigMap | Dashboard and launcher |
| **Portainer** | ✅ Healthy | https://portainer.k8s.dttesting.com | nfs-apps | Container management |
| **Traefik** | ✅ Healthy | https://traefik.k8s.dttesting.com | nfs-apps | Reverse proxy |
| **RustDesk** | ✅ Healthy | TCP/UDP services | nfs-apps | Remote desktop server |

### Storage Classes in Use

- **nfs-apps**: TrueNAS NFS storage for application data
- **nfs-media**: TrueNAS NFS storage for media files  
- **nfs-csi**: General purpose NFS storage

All applications use the `nfs-apps` storage class for consistent persistent storage management.

View the complete implementation in `kubernetes/apps/homer/` for reference.