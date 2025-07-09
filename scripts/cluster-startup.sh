#!/bin/bash
# Cluster startup script after hardware maintenance

set -euo pipefail

echo "=== Kubernetes Cluster Startup ==="
echo ""

# Function to wait for nodes
wait_for_nodes() {
    echo "→ Waiting for nodes to be ready..."
    
    expected_nodes=("talos-cp-01" "talos-cp-03" "talos-worker-01")
    
    for node in "${expected_nodes[@]}"; do
        echo -n "  Waiting for $node..."
        while ! kubectl get node "$node" &>/dev/null || \
              ! kubectl get node "$node" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; do
            echo -n "."
            sleep 5
        done
        echo " Ready!"
    done
}

# Function to scale up applications
scale_up_apps() {
    echo ""
    echo "→ Scaling up applications..."
    
    # Critical infrastructure first
    echo "  Starting ArgoCD..."
    kubectl scale deployment -n argocd --all --replicas=1
    
    sleep 30
    
    echo "  Starting remaining applications..."
    # Scale up other apps
    for ns in automation downloads media monitoring notifications paperless portainer; do
        echo "    Scaling up $ns namespace"
        kubectl scale deployment -n "$ns" --all --replicas=1 2>/dev/null || true
    done
    
    # Traefik needs 2 replicas
    echo "  Scaling Traefik to 2 replicas..."
    kubectl scale deployment traefik -n traefik --replicas=2
    
    # Scale up statefulsets
    echo "  Starting stateful applications..."
    kubectl scale statefulset -n argocd argocd-application-controller --replicas=1
}

# Main execution
echo "Checking cluster status..."

# Check if we can connect
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ Cannot connect to cluster. Please ensure:"
    echo "   - Control plane nodes are powered on"
    echo "   - Network connectivity is established"
    echo "   - Kubeconfig is properly configured"
    exit 1
fi

echo "✅ Connected to cluster"
echo ""

wait_for_nodes

echo ""
echo "→ Checking if applications need to be scaled up..."
deployment_count=$(kubectl get deployments -A --no-headers | grep -v "kube-system\|cert-manager\|metallb\|ingress-nginx\|nfs-csi" | grep " 0/0 " | wc -l)

if [ "$deployment_count" -gt 0 ]; then
    echo "  Found $deployment_count deployments at 0 replicas"
    echo -n "  Scale up applications? [y/N]: "
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        scale_up_apps
    fi
else
    echo "  Applications appear to be running already"
fi

echo ""
echo "=== Startup Complete ==="
echo ""
echo "Current cluster status:"
kubectl get nodes
echo ""
echo "To add cp-02 and worker-02 back to the cluster:"
echo "1. Ensure they are powered on and booted to Talos"
echo "2. Run: ./scripts/apply-configs.sh"
echo "3. They will automatically join the cluster"