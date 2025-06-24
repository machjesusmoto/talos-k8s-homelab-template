# Configure ArgoCD for GitOps
# This script sets up ArgoCD to manage the cluster via GitOps

param(
    [string]$GitRepoUrl = "https://github.com/machjesusmoto/k8s-homelab-migration.git",
    [string]$GitBranch = "main"
)

Write-Host "Configuring ArgoCD for GitOps..." -ForegroundColor Green

# Wait for ArgoCD to be fully ready
Write-Host "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the ArgoCD admin password
$adminPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

Write-Host "ArgoCD Admin Password: $adminPassword" -ForegroundColor Yellow
Write-Host "Save this password securely!" -ForegroundColor Red

# Create the root application that will manage all other applications
Write-Host "`nCreating ArgoCD root application..." -ForegroundColor Green

# Create app-of-apps pattern directory
New-Item -ItemType Directory -Force -Path "kubernetes/gitops/applications"

# Create the root application manifest
$rootAppManifest = @"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-application
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: $GitRepoUrl
    targetRevision: $GitBranch
    path: kubernetes/gitops/applications
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
"@

# Save the root application manifest
$rootAppManifest | Out-File -FilePath "kubernetes/gitops/applications/root-app.yaml" -Encoding UTF8

# Create kustomization for applications directory
@"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - core-infrastructure.yaml
"@ | Out-File -FilePath "kubernetes/gitops/applications/kustomization.yaml" -Encoding UTF8

# Create application for core infrastructure
@"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-infrastructure
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: $GitRepoUrl
    targetRevision: $GitBranch
    path: kubernetes/core
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
"@ | Out-File -FilePath "kubernetes/gitops/applications/core-infrastructure.yaml" -Encoding UTF8

Write-Host "`nArgoCD configuration files created!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Commit and push these changes to your Git repository"
Write-Host "2. Apply the root application: kubectl apply -f kubernetes/gitops/applications/root-app.yaml"
Write-Host "3. Access ArgoCD UI at: https://argocd.homelab-k8s.dttesting.com"
Write-Host "4. Login with username 'admin' and the password shown above"

# Create cluster issuer for cert-manager
Write-Host "`nCreating Let's Encrypt cluster issuer..." -ForegroundColor Green
@"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@dttesting.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
"@ | Out-File -FilePath "kubernetes/core/cert-manager/cluster-issuer.yaml" -Encoding UTF8

Write-Host "Configuration complete!" -ForegroundColor Green