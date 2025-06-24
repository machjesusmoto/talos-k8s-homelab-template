# GitOps Setup with ArgoCD

## Overview

ArgoCD has been successfully deployed to manage the Kubernetes cluster through GitOps principles. This setup enables declarative, version-controlled infrastructure management with automatic synchronization.

## Access Information

### ArgoCD UI Access
- **LoadBalancer URL**: http://192.168.1.210
- **Ingress URL**: https://argocd.homelab-k8s.dttesting.com
- **Username**: admin
- **Password**: Retrieved from secret (see below)

### Get Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

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

A Let's Encrypt production ClusterIssuer has been configured:
- **Email**: admin@dttesting.com
- **ACME Server**: Let's Encrypt Production
- **Solver**: HTTP-01 with nginx ingress

## Next Steps

1. **Change Admin Password**: 
   ```bash
   argocd account update-password
   ```

2. **Configure RBAC**: Set up additional users and permissions

3. **Add Applications**: Create ArgoCD applications for your workloads

4. **Setup Notifications**: Configure Slack/email alerts for sync status

5. **Enable SSO**: Configure Dex for OIDC/LDAP authentication

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