#!/bin/bash
# Generate Talos configuration files

set -e

echo "=== Talos Configuration Generator ==="

# Check if secrets exist
if [ ! -f "secrets.yaml" ]; then
    echo "Generating cluster secrets..."
    talosctl gen secrets -o secrets.yaml
    echo "IMPORTANT: Back up secrets.yaml securely!"
else
    echo "Using existing secrets.yaml"
fi

# Configuration variables
CLUSTER_NAME="homelab"
CLUSTER_ENDPOINT="192.168.1.240"

echo "Generating control plane configurations..."

# Generate base configs
talosctl gen config ${CLUSTER_NAME} https://${CLUSTER_ENDPOINT}:6443 \
    --with-secrets secrets.yaml \
    --output-types controlplane \
    --output talos/controlplane-base.yaml

talosctl gen config ${CLUSTER_NAME} https://${CLUSTER_ENDPOINT}:6443 \
    --with-secrets secrets.yaml \
    --output-types worker \
    --output talos/worker-base.yaml

talosctl gen config ${CLUSTER_NAME} https://${CLUSTER_ENDPOINT}:6443 \
    --with-secrets secrets.yaml \
    --output-types talosconfig \
    --output talos/talosconfig

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
