#!/bin/bash
# Configure ArgoCD for GitOps
# This script sets up ArgoCD to manage the cluster via GitOps

set -euo pipefail

# Default values
GIT_REPO_URL="${GIT_REPO_URL:-https://github.com/machjesusmoto/k8s-homelab-migration.git}"
GIT_BRANCH="${GIT_BRANCH:-main}"

echo -e "\033[32mConfiguring ArgoCD for GitOps...\033[0m"

# Wait for ArgoCD to be fully ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the ArgoCD admin password
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "\033[33mArgoCD Admin Password: $ADMIN_PASSWORD\033[0m"
echo -e "\033[31mSave this password securely!\033[0m"

# Create the root application that will manage all other applications
echo -e "\n\033[32mCreating ArgoCD root application...\033[0m"

# Create app-of-apps pattern directory
mkdir -p kubernetes/gitops/applications

# Create the root application manifest
cat > kubernetes/gitops/applications/root-app.yaml <<EOF
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
    repoURL: $GIT_REPO_URL
    targetRevision: $GIT_BRANCH
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
EOF

# Create kustomization for applications directory
cat > kubernetes/gitops/applications/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - core-infrastructure.yaml
EOF

# Create application for core infrastructure
cat > kubernetes/gitops/applications/core-infrastructure.yaml <<EOF
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
    repoURL: $GIT_REPO_URL
    targetRevision: $GIT_BRANCH
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
EOF

echo -e "\n\033[32mArgoCD configuration files created!\033[0m"
echo -e "\n\033[33mNext steps:\033[0m"
echo "1. Commit and push these changes to your Git repository"
echo "2. Apply the root application: kubectl apply -f kubernetes/gitops/applications/root-app.yaml"
echo "3. Access ArgoCD UI at: https://argocd.homelab-k8s.dttesting.com"
echo "4. Login with username 'admin' and the password shown above"

# Create cluster issuer for cert-manager
echo -e "\n\033[32mCreating Let's Encrypt cluster issuer...\033[0m"
cat > kubernetes/core/cert-manager/cluster-issuer.yaml <<EOF
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
EOF

echo -e "\033[32mConfiguration complete!\033[0m"