#!/bin/bash
# Generate Talos configuration files

set -euo pipefail

# Load configuration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config-reader.sh"

echo "=== Talos Configuration Generator ==="
echo "Using configurations from: $CONFIG_FILE"

# Load configuration values
load_common_config

echo "Cluster configuration:"
echo "  Name: $CLUSTER_NAME"
echo "  VIP: $CLUSTER_VIP"
echo "  Domain: $BASE_DOMAIN"
echo "  Talos Version: $TALOS_VERSION"
echo ""

# Check if secrets exist
if [ ! -f "secrets.yaml" ]; then
    echo "Generating cluster secrets..."
    talosctl gen secrets -o secrets.yaml
    echo "IMPORTANT: Back up secrets.yaml securely!"
else
    echo "Using existing secrets.yaml"
fi

echo "Generating control plane configurations..."

# Create talos directory if it doesn't exist
mkdir -p talos

# Generate base configs using configuration values
CLUSTER_ENDPOINT="https://${CLUSTER_VIP}:${KUBERNETES_API_PORT}"

echo "Generating configurations for endpoint: $CLUSTER_ENDPOINT"

talosctl gen config "${CLUSTER_NAME}" "${CLUSTER_ENDPOINT}" \
    --with-secrets secrets.yaml \
    --output-types controlplane \
    --output talos/controlplane-base.yaml

talosctl gen config "${CLUSTER_NAME}" "${CLUSTER_ENDPOINT}" \
    --with-secrets secrets.yaml \
    --output-types worker \
    --output talos/worker-base.yaml

talosctl gen config "${CLUSTER_NAME}" "${CLUSTER_ENDPOINT}" \
    --with-secrets secrets.yaml \
    --output-types talosconfig \
    --output talos/talosconfig

# Display node configuration
echo ""
echo "Node configuration from configurations.yaml:"
echo "Control Plane Nodes:"
get_control_plane_ips | while read -r ip; do
    hostname=$(get_node_hostname "$ip")
    echo "  - $hostname: $ip"
done

echo "Worker Nodes:"
get_worker_ips | while read -r ip; do
    hostname=$(get_node_hostname "$ip")
    echo "  - $hostname: $ip"
done

echo ""
echo "Base configurations generated!"
echo ""
echo "Next steps:"
echo "1. Review the generated configurations"
echo "2. Run ./scripts/apply-configs.sh to apply to nodes"
echo ""
echo "Files created:"
echo "  - secrets.yaml (KEEP THIS SECURE!)"
echo "  - talos/controlplane-base.yaml"
echo "  - talos/worker-base.yaml"
echo "  - talos/talosconfig"
