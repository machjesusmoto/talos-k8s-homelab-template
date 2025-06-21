#!/bin/bash
# Apply Talos configurations to nodes

set -e

echo "=== Applying Talos Configurations ==="

# Control plane nodes
CP_NODES=(
    "192.168.1.241"
    "192.168.1.242"
    "192.168.1.243"
)

# Worker nodes
WORKER_NODES=(
    "192.168.1.244"
    "192.168.1.245"
)

# Function to wait for node
wait_for_node() {
    local node=$1
    echo "Waiting for $node to be reachable..."
    while ! talosctl --nodes $node --endpoints $node version --insecure &>/dev/null; do
        echo -n "."
        sleep 5
    done
    echo " Ready!"
}

# Apply configuration to each control plane node
echo "=== Configuring Control Plane Nodes ==="
for i in "${!CP_NODES[@]}"; do
    node="${CP_NODES[$i]}"
    node_num=$((i + 1))
    
    echo ""
    echo "Configuring control plane node $node_num ($node)..."
    
    # Create patched config for this specific node
    talosctl machineconfig patch talos/controlplane-base.yaml \
        --patch @talos/patches/common.yaml \
        --patch @talos/patches/controlplane.yaml \
        --patch @talos/patches/cp-0${node_num}.yaml \
        --output talos/controlplane-${node_num}.yaml
    
    # Apply configuration
    echo "Applying configuration to $node..."
    talosctl apply-config --insecure \
        --nodes $node \
        --file talos/controlplane-${node_num}.yaml
    
    # Wait for node to come up
    wait_for_node $node
done

# Apply configuration to each worker node
echo ""
echo "=== Configuring Worker Nodes ==="
for i in "${!WORKER_NODES[@]}"; do
    node="${WORKER_NODES[$i]}"
    node_num=$((i + 1))
    
    echo ""
    echo "Configuring worker node $node_num ($node)..."
    
    # Create patched config for this specific node
    talosctl machineconfig patch talos/worker-base.yaml \
        --patch @talos/patches/common.yaml \
        --patch @talos/patches/worker.yaml \
        --patch @talos/patches/worker-0${node_num}.yaml \
        --output talos/worker-${node_num}.yaml
    
    # Apply configuration
    echo "Applying configuration to $node..."
    talosctl apply-config --insecure \
        --nodes $node \
        --file talos/worker-${node_num}.yaml
    
    # Wait for node to come up
    wait_for_node $node
done

echo ""
echo "All configurations applied!"
echo ""
echo "Next step: Bootstrap the cluster"
echo "Run: talosctl bootstrap --nodes ${CP_NODES[0]} --endpoints ${CP_NODES[0]}"
