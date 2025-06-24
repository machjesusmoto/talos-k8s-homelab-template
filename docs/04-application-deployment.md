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
```bash
# Check ClusterIssuer status
kubectl get clusterissuers

# Debug certificate issues
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Manual certificate creation (testing)
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

## Example: Complete Application Deployment

The Homer dashboard deployment demonstrates all concepts:

1. **Structured manifests** in `kubernetes/apps/homer/`
2. **Automatic SSL** with letsencrypt-prod
3. **GitOps management** via ArgoCD
4. **Configuration management** with ConfigMap
5. **Security best practices** with non-root containers
6. **Resource constraints** and health checks

View the complete implementation in `kubernetes/apps/homer/` for reference.