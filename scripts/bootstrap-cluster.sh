#!/bin/bash
# Bootstrap and verify Talos cluster

set -e

echo "=== Bootstrapping Talos Cluster ==="

# Configuration
FIRST_CP="192.168.1.241"
ALL_CPS="192.168.1.241 192.168.1.242 192.168.1.243"

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
