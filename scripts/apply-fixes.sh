#!/bin/bash
# Apply fixes for current deployment issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Applying deployment fixes...${NC}"

# 1. Create minimal VPN secret for Gluetun
echo -e "${YELLOW}1. Creating Gluetun VPN secret (update with real credentials later)...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: gluetun-vpn-secret
  namespace: gluetun
type: Opaque
stringData:
  VPN_SERVICE_PROVIDER: "custom"
  VPN_TYPE: "openvpn"
  OPENVPN_USER: "vpn-user-placeholder"
  OPENVPN_PASSWORD: "vpn-pass-placeholder"
  SERVER_REGIONS: "Netherlands"
EOF

# 2. Fix Paperless-ngx permissions
echo -e "${YELLOW}2. Fixing Paperless-ngx security context...${NC}"
kubectl patch deployment paperless-ngx -n paperless --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/securityContext", "value": {"runAsNonRoot": true, "runAsUser": 1000, "runAsGroup": 1000, "fsGroup": 1000}},
  {"op": "replace", "path": "/spec/template/spec/containers/0/securityContext", "value": {"runAsNonRoot": true, "runAsUser": 1000, "runAsGroup": 1000, "allowPrivilegeEscalation": false, "capabilities": {"drop": ["ALL"]}}}
]'

# 3. Force sync OutOfSync applications
echo -e "${YELLOW}3. Syncing OutOfSync ArgoCD applications...${NC}"
for app in code-server core-infrastructure download-clients media-management; do
    echo "Syncing $app..."
    kubectl patch application $app -n argocd \
        -p '{"operation":{"sync":{"prune":true,"selfHeal":true}}}' \
        --type=merge || echo "Warning: Failed to sync $app"
done

# 4. Restart problematic deployments
echo -e "${YELLOW}4. Restarting fixed deployments...${NC}"
kubectl rollout restart deployment gluetun -n gluetun || true
kubectl rollout restart deployment paperless-ngx -n paperless || true

# 5. Clean up stuck certificate challenges (they'll retry later)
echo -e "${YELLOW}5. Cleaning up stuck certificate challenges...${NC}"
kubectl delete challenges -A --all 2>/dev/null || true

echo -e "${GREEN}Fixes applied!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update configurations.yaml with real VPN credentials"
echo "2. Re-run generate-app-secrets.sh to create proper secrets"
echo "3. Monitor application health: kubectl get pods -A | grep -v Running"
echo "4. Certificates will retry automatically over the next few hours"