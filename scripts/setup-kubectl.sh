#!/bin/bash

# Setup kubectl for Talos cluster - Linux version

CONFIG_NAME=${1:-"talos-cluster"}

echo "=== Setting up kubectl for Talos cluster ==="

# Talos cluster configuration
VIP="192.168.1.240"
KUBECONFIG_PATH="$HOME/.kube/config"

echo "Setting up kubectl for Talos cluster..."

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Get kubeconfig from Talos
echo "Retrieving kubeconfig from Talos cluster..."
if ! talosctl kubeconfig --merge=false > kubeconfig-temp; then
    echo "Error: Failed to retrieve kubeconfig"
    exit 1
fi

# Backup existing config if it exists
if [[ -f "$KUBECONFIG_PATH" ]]; then
    backup="$KUBECONFIG_PATH.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing kubeconfig to $backup"
    cp "$KUBECONFIG_PATH" "$backup"
fi

# Copy to standard location
cp kubeconfig-temp "$KUBECONFIG_PATH"
rm -f kubeconfig-temp

echo "Kubeconfig saved to $KUBECONFIG_PATH"

# Set KUBECONFIG environment variable for current session
export KUBECONFIG="$KUBECONFIG_PATH"
echo "export KUBECONFIG=\"$KUBECONFIG_PATH\"" >> ~/.bashrc

# Test connection
echo ""
echo "Testing connection..."
if kubectl get nodes -o wide; then
    echo ""
    echo "kubectl configured successfully for Talos cluster!"
    echo "API Server: https://$VIP:6443"
    echo "Kubeconfig: $KUBECONFIG_PATH"
    echo ""
    echo "To use kubectl in new sessions, ensure KUBECONFIG is set:"
    echo "export KUBECONFIG=\"$KUBECONFIG_PATH\""
else
    echo "Error: Failed to connect to cluster"
    echo ""
    echo "Troubleshooting:"
    echo "1. Ensure Talos cluster is bootstrapped and healthy"
    echo "2. Check talosctl configuration: talosctl config info"
    echo "3. Verify cluster health: talosctl health"
    exit 1
fi
