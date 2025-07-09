#!/bin/bash
# Script to generate VPN configuration secrets for download clients

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/configurations.yaml"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to get config value
get_config() {
    local key="$1"
    local default="${2:-}"
    
    # Use yq if available, otherwise use default
    if command -v yq >/dev/null 2>&1; then
        yq eval ".${key} // \"${default}\"" "$CONFIG_FILE" || echo "$default"
    elif [ -f "$HOME/yq" ]; then
        "$HOME/yq" eval ".${key} // \"${default}\"" "$CONFIG_FILE" || echo "$default"
    else
        echo "$default"
    fi
}

echo -e "${GREEN}Generating VPN configurations for download clients...${NC}"

# Get VPN credentials from configurations.yaml
WIREGUARD_PRIVATE_KEY=$(get_config 'vpn.wireguard_private_key')
WIREGUARD_PUBLIC_KEY=$(get_config 'vpn.wireguard_public_key')
WIREGUARD_PRESHARED_KEY=$(get_config 'vpn.wireguard_preshared_key')
WIREGUARD_ADDRESSES=$(get_config 'vpn.wireguard_addresses')
WIREGUARD_ENDPOINT=$(get_config 'vpn.wireguard_endpoint' '198.44.133.70:1637')

# Generate WireGuard config for qBittorrent
echo -e "${YELLOW}Generating qBittorrent VPN configuration...${NC}"
cat > "$PROJECT_ROOT/kubernetes/apps/downloads/qbittorrent-vpn-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: qbittorrent-vpn-config
  namespace: downloads
type: Opaque
stringData:
  wg0.conf: |
    [Interface]
    PrivateKey = ${WIREGUARD_PRIVATE_KEY}
    Address = ${WIREGUARD_ADDRESSES}
    DNS = 1.1.1.1
    
    [Peer]
    PublicKey = ${WIREGUARD_PUBLIC_KEY}
    PresharedKey = ${WIREGUARD_PRESHARED_KEY}
    Endpoint = ${WIREGUARD_ENDPOINT}
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
EOF

# For NZBget (which doesn't need VPN but we'll create a deployment anyway)
echo -e "${YELLOW}Generating NZBget configuration...${NC}"
NZBGET_PASSWORD=$(get_config 'downloads.nzbget.admin_password' 'changeme123!')
USENET_HOST=$(get_config 'downloads.usenet.host' 'news.provider.com')
USENET_PORT=$(get_config 'downloads.usenet.port' '563')
USENET_USERNAME=$(get_config 'downloads.usenet.username' '')
USENET_PASSWORD=$(get_config 'downloads.usenet.password' '')
USENET_CONNECTIONS=$(get_config 'downloads.usenet.connections' '20')

cat > "$PROJECT_ROOT/kubernetes/apps/downloads/nzbget-secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: nzbget-secret
  namespace: downloads
type: Opaque
stringData:
  NZBGET_ADMIN_PASSWORD: "${NZBGET_PASSWORD}"
  USENET_HOST: "${USENET_HOST}"
  USENET_PORT: "${USENET_PORT}"
  USENET_USERNAME: "${USENET_USERNAME}"
  USENET_PASSWORD: "${USENET_PASSWORD}"
  USENET_CONNECTIONS: "${USENET_CONNECTIONS}"
EOF

# Update .gitignore
if ! grep -q "qbittorrent-vpn-secret.yaml" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    echo "kubernetes/apps/downloads/qbittorrent-vpn-secret.yaml" >> "$PROJECT_ROOT/.gitignore"
fi
if ! grep -q "nzbget-secret.yaml" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    echo "kubernetes/apps/downloads/nzbget-secret.yaml" >> "$PROJECT_ROOT/.gitignore"
fi

echo -e "${GREEN}VPN configuration generation complete!${NC}"
echo -e "${YELLOW}Apply with:${NC}"
echo "  kubectl apply -f kubernetes/apps/downloads/qbittorrent-vpn-secret.yaml"
echo "  kubectl apply -f kubernetes/apps/downloads/qbittorrent-vpn-deployment.yaml"