#!/bin/bash
# Script to fix current deployment issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Fixing deployment issues...${NC}"

# 1. Fix DNS propagation issue by forcing cert-manager to retry
echo -e "${YELLOW}1. Restarting cert-manager to force DNS propagation check...${NC}"
kubectl rollout restart deployment cert-manager -n cert-manager
kubectl rollout restart deployment cert-manager-webhook -n cert-manager

# Wait for rollout
echo "Waiting for cert-manager restart..."
kubectl rollout status deployment cert-manager -n cert-manager --timeout=300s
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s

# 2. Fix Paperless-ngx by switching to non-root container
echo -e "${YELLOW}2. Fixing Paperless-ngx deployment...${NC}"
cat > /tmp/paperless-patch.yaml <<'EOF'
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: paperless
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          runAsGroup: 1000
          capabilities:
            drop:
            - ALL
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
EOF

kubectl patch deployment paperless-ngx -n paperless --patch-file=/tmp/paperless-patch.yaml

# 3. Apply missing secrets if configurations.yaml exists
if [ -f "$PROJECT_ROOT/configurations.yaml" ]; then
    echo -e "${YELLOW}3. Generating and applying secrets from configurations.yaml...${NC}"
    
    # Make generate script executable
    chmod +x "$PROJECT_ROOT/scripts/generate-app-secrets.sh"
    
    # Generate secrets
    "$PROJECT_ROOT/scripts/generate-app-secrets.sh"
    
    # Apply generated secrets
    echo "Applying generated secrets..."
    [ -f "$PROJECT_ROOT/kubernetes/core/cert-manager/cloudflare-secret.yaml" ] && \
        kubectl apply -f "$PROJECT_ROOT/kubernetes/core/cert-manager/cloudflare-secret.yaml"
    
    [ -f "$PROJECT_ROOT/kubernetes/apps/gluetun/vpn-secret.yaml" ] && \
        kubectl apply -f "$PROJECT_ROOT/kubernetes/apps/gluetun/vpn-secret.yaml"
    
    [ -f "$PROJECT_ROOT/kubernetes/apps/paperless-ngx/paperless-secrets.yaml" ] && \
        kubectl apply -f "$PROJECT_ROOT/kubernetes/apps/paperless-ngx/paperless-secrets.yaml"
else
    echo -e "${RED}Warning: configurations.yaml not found. Skipping secret generation.${NC}"
    echo "Please create configurations.yaml from the template and run this script again."
fi

# 4. Force ArgoCD sync for OutOfSync applications
echo -e "${YELLOW}4. Syncing OutOfSync ArgoCD applications...${NC}"
for app in code-server core-infrastructure download-clients media-management; do
    echo "Syncing $app..."
    kubectl patch application $app -n argocd \
        -p '{"operation":{"sync":{"prune":true,"selfHeal":true}}}' \
        --type=merge || true
done

# 5. Delete stuck challenges to force recreation
echo -e "${YELLOW}5. Cleaning up stuck certificate challenges...${NC}"
# Only delete challenges older than 1 hour
kubectl get challenges -A -o json | \
    jq -r '.items[] | select(.metadata.creationTimestamp | fromdate < (now - 3600)) | 
    "\(.metadata.namespace) \(.metadata.name)"' | \
    while read ns name; do
        echo "Deleting old challenge: $ns/$name"
        kubectl delete challenge -n "$ns" "$name"
    done

# 6. Restart applications with issues
echo -e "${YELLOW}6. Restarting problematic deployments...${NC}"
kubectl rollout restart deployment gluetun -n gluetun || true
kubectl rollout restart deployment paperless-ngx -n paperless || true

echo -e "${GREEN}Fix script complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Monitor certificate challenges: kubectl get challenges -A -w"
echo "2. Check application health: kubectl get pods -A | grep -v Running"
echo "3. View ArgoCD sync status: kubectl get applications -n argocd"
echo ""
echo -e "${YELLOW}If DNS challenges still fail after 5 minutes:${NC}"
echo "- Check Cloudflare DNS panel for _acme-challenge TXT records"
echo "- Verify DNS propagation: dig _acme-challenge.homer.k8s.dttesting.com TXT"
echo "- Consider using HTTP-01 challenges instead of DNS-01"