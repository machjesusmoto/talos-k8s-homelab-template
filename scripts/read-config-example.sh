#!/bin/bash
# Example script showing how to read values from configurations.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/configurations.yaml"

# Check if configurations.yaml exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: configurations.yaml not found at $CONFIG_FILE"
    exit 1
fi

# Install yq if not available (YAML parser)
if ! command -v yq &> /dev/null; then
    echo "Installing yq for YAML parsing..."
    curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq
    chmod +x /tmp/yq
    sudo mv /tmp/yq /usr/local/bin/yq
fi

# Read values from configurations.yaml
echo "Reading configuration values..."

# Simple values
CLUSTER_NAME=$(yq eval '.cluster.name' "$CONFIG_FILE")
CLUSTER_VIP=$(yq eval '.network.cluster_vip' "$CONFIG_FILE")
BASE_DOMAIN=$(yq eval '.domain.base' "$CONFIG_FILE")
NFS_SERVER=$(yq eval '.storage.nfs_server' "$CONFIG_FILE")

echo "Cluster Name: $CLUSTER_NAME"
echo "Cluster VIP: $CLUSTER_VIP"
echo "Base Domain: $BASE_DOMAIN"
echo "NFS Server: $NFS_SERVER"

# Read arrays
echo ""
echo "Control Plane Nodes:"
yq eval '.cluster.control_planes[].ip' "$CONFIG_FILE" | while read -r ip; do
    echo "  - $ip"
done

echo ""
echo "Worker Nodes:"
yq eval '.cluster.workers[].ip' "$CONFIG_FILE" | while read -r ip; do
    echo "  - $ip"
done

# Get specific node info
echo ""
echo "First control plane details:"
CP1_IP=$(yq eval '.cluster.control_planes[0].ip' "$CONFIG_FILE")
CP1_HOSTNAME=$(yq eval '.cluster.control_planes[0].hostname' "$CONFIG_FILE")
echo "  IP: $CP1_IP"
echo "  Hostname: $CP1_HOSTNAME"

# Check if a value exists and has content
GITHUB_TOKEN=$(yq eval '.argocd.github_token' "$CONFIG_FILE")
if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "null" ]; then
    echo ""
    echo "GitHub token is configured"
else
    echo ""
    echo "GitHub token is not configured (using public repo)"
fi