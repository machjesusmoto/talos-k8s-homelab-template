#!/bin/bash
# Script to generate application secrets from configurations.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/configurations.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if configurations.yaml exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: configurations.yaml not found!${NC}"
    echo "Please copy configurations.yaml.example to configurations.yaml and fill in your values"
    exit 1
fi

echo -e "${GREEN}Generating application secrets from configurations.yaml...${NC}"

# Function to extract value from YAML
get_config() {
    local key=$1
    local default=${2:-}
    yq eval ".$key // \"$default\"" "$CONFIG_FILE" 2>/dev/null || echo "$default"
}

# Function to check required values
check_required() {
    local key=$1
    local value=$2
    if [ -z "$value" ] || [ "$value" = "null" ] || [[ "$value" == *"REQUIRED"* ]] || [[ "$value" == "your-"* ]]; then
        echo -e "${RED}Error: Required configuration missing: $key${NC}"
        echo "Please update configurations.yaml with your actual values"
        exit 1
    fi
}

# 1. Generate Cloudflare DNS secret
echo -e "${YELLOW}Generating Cloudflare DNS secret...${NC}"
CLOUDFLARE_EMAIL=$(get_config "cloudflare.email")
CLOUDFLARE_TOKEN=$(get_config "cloudflare.api_token")
check_required "cloudflare.api_token" "$CLOUDFLARE_TOKEN"

cat > "$PROJECT_ROOT/kubernetes/core/cert-manager/cloudflare-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: "$CLOUDFLARE_TOKEN"
EOF

# 2. Generate Gluetun VPN secret
echo -e "${YELLOW}Generating Gluetun VPN secret...${NC}"
VPN_PROVIDER=$(get_config "vpn.provider")
VPN_TYPE=$(get_config "vpn.type" "openvpn")

# Handle different VPN types
if [ "$VPN_TYPE" = "wireguard" ]; then
    VPN_USERNAME=""
    VPN_PASSWORD=""
    WIREGUARD_PRIVATE_KEY=$(get_config "vpn.wireguard_private_key")
    WIREGUARD_PUBLIC_KEY=$(get_config "vpn.wireguard_public_key")
    WIREGUARD_PRESHARED_KEY=$(get_config "vpn.wireguard_preshared_key")
    WIREGUARD_ADDRESSES=$(get_config "vpn.wireguard_addresses")
    check_required "vpn.wireguard_private_key" "$WIREGUARD_PRIVATE_KEY"
else
    VPN_USERNAME=$(get_config "vpn.username")
    VPN_PASSWORD=$(get_config "vpn.password")
    check_required "vpn.username" "$VPN_USERNAME"
    check_required "vpn.password" "$VPN_PASSWORD"
fi
VPN_REGIONS=$(get_config "vpn.server_regions" "Netherlands")

if [ "$VPN_TYPE" = "wireguard" ]; then
    WIREGUARD_ENDPOINT=$(get_config 'vpn.wireguard_endpoint' '')
    if [ -n "$WIREGUARD_ENDPOINT" ]; then
        # Use custom provider with specific endpoint configuration to bypass CNI egress filtering
        echo "Using custom provider with specific endpoint: $WIREGUARD_ENDPOINT"
        cat > "$PROJECT_ROOT/kubernetes/apps/gluetun/vpn-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gluetun-vpn-secret
  namespace: gluetun
type: Opaque
stringData:
  VPN_SERVICE_PROVIDER: "custom"
  VPN_TYPE: "wireguard"
  WIREGUARD_PRIVATE_KEY: "$WIREGUARD_PRIVATE_KEY"
  WIREGUARD_PUBLIC_KEY: "$WIREGUARD_PUBLIC_KEY"
  WIREGUARD_PRESHARED_KEY: "$WIREGUARD_PRESHARED_KEY"
  WIREGUARD_ADDRESSES: "$WIREGUARD_ADDRESSES"
  WIREGUARD_ENDPOINT_IP: "$(echo "$WIREGUARD_ENDPOINT" | cut -d: -f1)"
  WIREGUARD_ENDPOINT_PORT: "$(echo "$WIREGUARD_ENDPOINT" | cut -d: -f2)"
  WIREGUARD_MTU: "$(get_config 'vpn.wireguard_mtu' '1320')"
EOF
    else
        # Use server selection mode
        cat > "$PROJECT_ROOT/kubernetes/apps/gluetun/vpn-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gluetun-vpn-secret
  namespace: gluetun
type: Opaque
stringData:
  VPN_SERVICE_PROVIDER: "$VPN_PROVIDER"
  VPN_TYPE: "wireguard"
  WIREGUARD_PRIVATE_KEY: "$WIREGUARD_PRIVATE_KEY"
  WIREGUARD_PUBLIC_KEY: "$WIREGUARD_PUBLIC_KEY"
  WIREGUARD_PRESHARED_KEY: "$WIREGUARD_PRESHARED_KEY"
  WIREGUARD_ADDRESSES: "$WIREGUARD_ADDRESSES"
  WIREGUARD_MTU: "$(get_config 'vpn.wireguard_mtu' '1320')"
  SERVER_COUNTRIES: "$(get_config 'vpn.server_countries' '')"
  SERVER_CITIES: "$(get_config 'vpn.server_cities' '')"
  FIREWALL_VPN_INPUT_PORTS: "$(get_config 'vpn.firewall_vpn_input_ports' '')"
EOF
    fi
else
    cat > "$PROJECT_ROOT/kubernetes/apps/gluetun/vpn-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gluetun-vpn-secret
  namespace: gluetun
type: Opaque
stringData:
  VPN_SERVICE_PROVIDER: "$VPN_PROVIDER"
  VPN_TYPE: "openvpn"
  OPENVPN_USER: "$VPN_USERNAME"
  OPENVPN_PASSWORD: "$VPN_PASSWORD"
  SERVER_REGIONS: "$VPN_REGIONS"
EOF
fi

# 3. Generate Paperless-ngx secrets
echo -e "${YELLOW}Generating Paperless-ngx secrets...${NC}"
PAPERLESS_ADMIN_PASSWORD=$(get_config "paperless.admin_password" "changeme123!")
PAPERLESS_SECRET_KEY=$(get_config "paperless.secret_key" "$(openssl rand -base64 32)")
PAPERLESS_POSTGRES_PASSWORD=$(get_config "paperless.postgres_password" "paperless-db-password")

cat > "$PROJECT_ROOT/kubernetes/apps/paperless-ngx/paperless-secrets.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: paperless-secrets
  namespace: paperless
type: Opaque
stringData:
  POSTGRES_DB: "paperless"
  POSTGRES_USER: "paperless"
  POSTGRES_PASSWORD: "$PAPERLESS_POSTGRES_PASSWORD"
  PAPERLESS_SECRET_KEY: "$PAPERLESS_SECRET_KEY"
  PAPERLESS_ADMIN_USER: "admin"
  PAPERLESS_ADMIN_PASSWORD: "$PAPERLESS_ADMIN_PASSWORD"
  PAPERLESS_ADMIN_MAIL: "$(get_config "domain.email" "admin@example.com")"
EOF

# 4. Generate Notifiarr secret
echo -e "${YELLOW}Generating Notifiarr secret...${NC}"
NOTIFIARR_API_KEY=$(get_config "notifications.notifiarr.api_key")
DISCORD_WEBHOOK=$(get_config "notifications.discord.webhook_url")

if [ -n "$NOTIFIARR_API_KEY" ] && [ "$NOTIFIARR_API_KEY" != "null" ]; then
    cat > "$PROJECT_ROOT/kubernetes/apps/notifiarr/notifiarr-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: notifiarr-secrets
  namespace: notifications
type: Opaque
stringData:
  DN_API_KEY: "$NOTIFIARR_API_KEY"
  DN_DISCORD_WEBHOOK: "$DISCORD_WEBHOOK"
EOF
fi

# 5. Generate download client secrets
echo -e "${YELLOW}Generating download client secrets...${NC}"
QBITTORRENT_PASSWORD=$(get_config "downloads.qbittorrent.admin_password" "changeme123!")
NZBGET_PASSWORD=$(get_config "downloads.nzbget.admin_password" "changeme123!")

cat > "$PROJECT_ROOT/kubernetes/apps/download-clients/qbittorrent-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: qbittorrent-secrets
  namespace: downloads
type: Opaque
stringData:
  ADMIN_PASSWORD: "$QBITTORRENT_PASSWORD"
EOF

cat > "$PROJECT_ROOT/kubernetes/apps/download-clients/nzbget-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: nzbget-secrets
  namespace: downloads
type: Opaque
stringData:
  ADMIN_PASSWORD: "$NZBGET_PASSWORD"
EOF

# 6. Generate Grafana secret
echo -e "${YELLOW}Generating Grafana secret...${NC}"
GRAFANA_PASSWORD=$(get_config "monitoring.grafana.admin_password" "changeme123!")

cat > "$PROJECT_ROOT/kubernetes/apps/monitoring/grafana-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: grafana-secrets
  namespace: monitoring
type: Opaque
stringData:
  admin-password: "$GRAFANA_PASSWORD"
EOF

# 7. Generate ArgoCD admin password secret
echo -e "${YELLOW}Generating ArgoCD password secret...${NC}"
ARGOCD_PASSWORD=$(get_config "argocd.admin_password" "changeme123!")

cat > "$PROJECT_ROOT/kubernetes/gitops/argocd/argocd-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: argocd-admin-password
  namespace: argocd
type: Opaque
stringData:
  password: "$ARGOCD_PASSWORD"
EOF

# Update .gitignore to exclude generated secrets
echo -e "${YELLOW}Updating .gitignore...${NC}"
cat >> "$PROJECT_ROOT/.gitignore" <<EOF

# Generated application secrets
kubernetes/core/cert-manager/cloudflare-secret.yaml
kubernetes/apps/gluetun/vpn-secret.yaml
kubernetes/apps/paperless-ngx/paperless-secrets.yaml
kubernetes/apps/notifiarr/notifiarr-secret.yaml
kubernetes/apps/download-clients/qbittorrent-secret.yaml
kubernetes/apps/download-clients/nzbget-secret.yaml
kubernetes/apps/monitoring/grafana-secret.yaml
kubernetes/gitops/argocd/argocd-secret.yaml
EOF

echo -e "${GREEN}Secret generation complete!${NC}"
echo -e "${YELLOW}Generated secrets have been added to .gitignore${NC}"
echo -e "${YELLOW}Apply secrets with: kubectl apply -f <secret-file>${NC}"