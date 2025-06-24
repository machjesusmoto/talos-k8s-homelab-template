# GitOps Setup with ArgoCD

## Overview

ArgoCD has been successfully deployed to manage the Kubernetes cluster through GitOps principles. This setup enables declarative, version-controlled infrastructure management with automatic synchronization.

## Access Information

### ArgoCD UI Access
- **LoadBalancer URL**: http://192.168.1.210
- **Ingress URL**: https://argocd.k8s.dttesting.com (with SSL certificate)
- **Username**: admin
- **Password**: Changed from initial (see security note below)

### Initial Admin Password
```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Security Note**: The admin password has been changed from the initial password. Store the new password securely.

## GitOps Structure

The repository follows the app-of-apps pattern:

```
kubernetes/
├── core/                    # Core infrastructure components
│   ├── cert-manager/
│   ├── ingress-nginx/
│   ├── kube-proxy/
│   ├── metallb/
│   └── nfs-csi/
└── gitops/
    ├── argocd/             # ArgoCD installation
    └── applications/       # ArgoCD application definitions
        ├── root-app.yaml   # Root application (app-of-apps)
        └── core-infrastructure.yaml
```

## Deployment Process

1. **Commit Changes**: Push all configuration to Git
   ```bash
   git add .
   git commit -m "Add ArgoCD GitOps configuration"
   git push origin main
   ```

2. **Apply Root Application**: Deploy the app-of-apps
   ```bash
   kubectl apply -f kubernetes/gitops/applications/root-app.yaml
   ```

3. **Monitor Sync**: Watch ArgoCD synchronize all applications
   - Access ArgoCD UI
   - View application status
   - Check sync progress

## Key Features Configured

1. **Automatic Sync**: Applications auto-sync with Git repository
2. **Self-Healing**: Automatic correction of configuration drift
3. **Pruning**: Removes resources not defined in Git
4. **Server-Side Apply**: Uses Kubernetes server-side apply for better conflict resolution

## Certificate Management

Let's Encrypt ClusterIssuers have been configured for DNS-01 challenge:

### Production ClusterIssuer
- **Name**: letsencrypt-prod
- **Email**: admin@dttesting.com
- **ACME Server**: Let's Encrypt Production
- **Solver**: DNS-01 with Cloudflare API

### Staging ClusterIssuer  
- **Name**: letsencrypt-staging
- **Email**: admin@dttesting.com
- **ACME Server**: Let's Encrypt Staging
- **Solver**: DNS-01 with Cloudflare API

### DNS-01 Challenge Configuration
- **Provider**: Cloudflare
- **Domain**: dttesting.com zone
- **Subdomain**: k8s.dttesting.com
- **API Token**: Stored in `cloudflare-api-token-secret` (excluded from git)

## Current Deployment Status

### Applications Deployed
1. **root-application**: ✅ Synced and Healthy
   - Manages all other ArgoCD applications
   
2. **core-infrastructure**: ✅ Synced (with minor warnings)
   - kube-proxy: ✅ Running (required for service routing)
   - MetalLB: ✅ Running (LoadBalancer services)
   - NGINX Ingress: ✅ Running
   - cert-manager: ✅ Running (with webhook settling)
   - NFS CSI Driver: ✅ Running

### Known Issues (Non-blocking)
- **BGPPeers CRD**: Out of sync (not needed for L2 mode)
- **Shared resource warnings**: Multiple apps managing cert-manager CRDs (expected)
- **Core-infrastructure OutOfSync**: Minor sync drift - components are healthy

## Installing ArgoCD CLI

```bash
# Linux
curl -sSL -o ~/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x ~/bin/argocd

# Windows (PowerShell as Administrator)
$url = "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-windows-amd64.exe"
Invoke-WebRequest -Uri $url -OutFile "$env:LOCALAPPDATA\Microsoft\WindowsApps\argocd.exe"
```

## ArgoCD CLI Login

```bash
# Login to ArgoCD (will prompt for TLS warning)
echo y | ~/bin/argocd login 192.168.1.210 --username admin --password '<your-password>' --insecure --grpc-web
```

## DNS-01 Challenge Setup

### 1. Cloudflare API Token Setup
Create an API token at [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens):
- **Template**: Edit zone DNS
- **Permissions**: Zone:DNS:Edit, Zone:Zone:Read  
- **Zone Resources**: Include specific zone: dttesting.com

### 2. Apply API Token Secret
```bash
# Edit the secret file with your token
kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token=your-cloudflare-api-token \
  -n cert-manager
```

### 3. DNS Configuration
Add DNS records in Cloudflare:
```
Type: A or CNAME
Name: *.k8s.dttesting.com  
Value: Your home IP or dynamic DNS
```

### 4. Local DNS (Optional)
For local access without internet routing:
```
*.k8s.dttesting.com → 192.168.1.200 (NGINX LoadBalancer IP)
```

### 5. Certificate Usage
Add to any Ingress for automatic SSL:
```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod  # or letsencrypt-staging
spec:
  tls:
  - hosts:
    - your-app.k8s.dttesting.com
    secretName: your-app-tls
```

## Next Steps

1. **Configure RBAC**: Set up additional users and permissions

2. **Add Applications**: Create ArgoCD applications for your workloads

3. **Setup Notifications**: Configure Slack/email alerts for sync status

4. **Enable SSO**: Configure Dex for OIDC/LDAP authentication

## Troubleshooting

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### View Application Sync Status
```bash
kubectl get applications -n argocd
```

### Check Logs
```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server
```

## Scripts

Configuration scripts are available for both platforms:
- **Windows**: `scripts/configure-argocd.ps1`
- **Linux**: `scripts/configure-argocd.sh`

These scripts automate the GitOps structure creation and initial configuration.