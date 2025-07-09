#!/bin/bash
# Graceful cluster shutdown script for hardware maintenance

set -euo pipefail

echo "=== Kubernetes Cluster Graceful Shutdown ==="
echo "This script will safely shutdown your cluster for hardware maintenance"
echo ""

# Function to scale down deployments
scale_down_apps() {
    echo "→ Scaling down application deployments..."
    
    # Get all non-system deployments and scale to 0
    kubectl get deployments -A -o json | jq -r '.items[] | 
        select(.metadata.namespace | test("kube-system|cert-manager|metallb-system|ingress-nginx|nfs-csi") | not) | 
        "\(.metadata.namespace) \(.metadata.name)"' | \
    while read ns name; do
        echo "  Scaling down $ns/$name"
        kubectl scale deployment "$name" -n "$ns" --replicas=0
    done
    
    # Scale down statefulsets
    echo "→ Scaling down statefulsets..."
    kubectl get statefulsets -A -o json | jq -r '.items[] | 
        select(.metadata.namespace | test("kube-system") | not) | 
        "\(.metadata.namespace) \(.metadata.name)"' | \
    while read ns name; do
        echo "  Scaling down $ns/$name"
        kubectl scale statefulset "$name" -n "$ns" --replicas=0
    done
    
    echo "→ Waiting for pods to terminate..."
    sleep 30
}

# Function to shutdown nodes
shutdown_nodes() {
    echo ""
    echo "→ Shutting down nodes..."
    
    # Shutdown workers first
    echo "  Shutting down worker nodes..."
    for node in talos-worker-01; do
        echo "    Shutting down $node"
        talosctl -n "192.168.1.244" shutdown || true
    done
    
    # Wait a bit
    sleep 10
    
    # Shutdown control plane nodes
    echo "  Shutting down control plane nodes..."
    # Shutdown cp-03 first (non-VIP holder)
    echo "    Shutting down talos-cp-03"
    talosctl -n "192.168.1.243" shutdown || true
    
    sleep 5
    
    # Shutdown cp-01 last (VIP holder)
    echo "    Shutting down talos-cp-01"
    talosctl -n "192.168.1.241" shutdown || true
}

# Main execution
echo "Choose shutdown type:"
echo "1) Full shutdown with application scaling (recommended)"
echo "2) Quick shutdown (nodes only)"
echo -n "Enter choice [1-2]: "
read choice

case $choice in
    1)
        scale_down_apps
        shutdown_nodes
        ;;
    2)
        echo "→ Proceeding with quick shutdown..."
        shutdown_nodes
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "=== Shutdown Complete ==="
echo ""
echo "To restart the cluster after hardware maintenance:"
echo "1. Power on nodes in this order: cp-01, cp-03, worker-01"
echo "2. Wait for control plane to form quorum"
echo "3. Run: kubectl get nodes"
echo "4. If doing full shutdown, run: ./scripts/cluster-startup.sh"
echo ""
echo "To rejoin cp-02 and worker-02 after restart:"
echo "1. Apply their configurations: ./scripts/apply-configs.sh"
echo "2. They will automatically join the cluster"