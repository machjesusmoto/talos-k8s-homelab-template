#!/bin/bash
# Bootstrap and verify Talos cluster

set -euo pipefail

# Load configuration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config-reader.sh"

echo "=== Bootstrapping Talos Cluster ==="
echo "Using configurations from: $CONFIG_FILE"

# Load configuration values
load_common_config

# Get node lists from configuration
mapfile -t CP_NODES < <(get_control_plane_ips)
FIRST_CP="${CP_NODES[0]}"
ALL_CPS=$(IFS=' '; echo "${CP_NODES[*]}")

echo ""
echo "Cluster configuration:"
echo "  Name: $CLUSTER_NAME"
echo "  VIP: $CLUSTER_VIP"
echo "  First Control Plane: $FIRST_CP ($(get_node_hostname "$FIRST_CP"))"
echo "  All Control Planes: $ALL_CPS"
echo ""

# Bootstrap etcd on first control plane
echo "Bootstrapping etcd on $FIRST_CP..."
talosctl bootstrap --nodes $FIRST_CP --endpoints $FIRST_CP

echo "Waiting for bootstrap to complete..."
sleep 30

# Configure talosctl
echo "Configuring talosctl..."
talosctl config merge talos/talosconfig
talosctl config endpoints $ALL_CPS
talosctl config nodes $ALL_CPS

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
while ! talosctl health --wait-timeout 5m &>/dev/null; do
    echo "Cluster not ready yet, waiting..."
    sleep 10
done

echo ""
echo "Cluster is healthy!"
echo ""

# Get kubeconfig
echo "Retrieving kubeconfig..."
talosctl kubeconfig

# Test kubectl access
echo "Testing kubectl access..."
kubectl get nodes

echo ""
echo "=== Cluster Information ==="
echo "API Endpoint: https://192.168.1.240:6443"
echo "Nodes:"
kubectl get nodes -o wide

echo ""
echo "Talos cluster is ready!"
echo ""
echo "Next steps:"
echo "1. Deploy core infrastructure: kubectl apply -k kubernetes/core/"
echo "2. Set up GitOps: kubectl apply -k kubernetes/gitops/"
