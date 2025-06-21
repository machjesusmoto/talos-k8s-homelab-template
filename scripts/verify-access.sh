#!/bin/bash

echo "=== Verifying Talos Cluster Access and Health ==="

# Talos cluster nodes
CONTROL_PLANES=("192.168.1.241" "192.168.1.242" "192.168.1.243")
WORKERS=("192.168.1.244" "192.168.1.245")
ALL_NODES=("${CONTROL_PLANES[@]}" "${WORKERS[@]}")
VIP="192.168.1.240"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

test_talos_node_health() {
    local node_ip=$1
    local node_type=$2
    
    echo -e "\n=== Testing $node_type Node: $node_ip ==="
    
    # Test network connectivity (Talos API port)
    echo -n "Network Connectivity: "
    if timeout 5 bash -c "</dev/tcp/$node_ip/50000" 2>/dev/null; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed (Port 50000 not accessible)${NC}"
        return 1
    fi
    
    # Test Talos API
    echo -n "Talos API Access: "
    if talosctl version --nodes "$node_ip" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
    
    # Get node info
    echo -e "${YELLOW}Node Information:${NC}"
    local hostname
    hostname=$(talosctl get hostname --nodes "$node_ip" -o jsonpath='{.spec.hostname}' 2>/dev/null || echo "unknown")
    echo "  Hostname: $hostname"
    echo "  IP: $node_ip"
    
    # Get resource usage if possible
    local mem_info
    mem_info=$(talosctl read /proc/meminfo --nodes "$node_ip" 2>/dev/null | grep MemTotal)
    if [[ -n "$mem_info" ]]; then
        local mem_total
        mem_total=$(echo "$mem_info" | awk '{print $2}')
        local mem_gb
        mem_gb=$(echo "scale=1; $mem_total / 1024 / 1024" | bc 2>/dev/null || echo "unknown")
        echo "  Memory: ${mem_gb} GB"
    fi
    
    local cpu_count
    cpu_count=$(talosctl read /proc/cpuinfo --nodes "$node_ip" 2>/dev/null | grep -c "processor" || echo "unknown")
    echo "  CPU Cores: $cpu_count"
    
    return 0
}

# Check talosctl configuration
echo -e "\nChecking talosctl configuration..."
if talosctl config info >/dev/null 2>&1; then
    echo -e "${GREEN}✓ talosctl is configured${NC}"
    talosctl config info | sed 's/^/  /'
else
    echo -e "${RED}✗ talosctl not configured properly${NC}"
    echo -e "${YELLOW}Run: talosctl config merge talos/talosconfig${NC}"
    exit 1
fi

# Test VIP accessibility
echo -e "\nTesting Kubernetes API VIP ($VIP)..."
if timeout 5 bash -c "</dev/tcp/$VIP/6443" 2>/dev/null; then
    echo -e "${GREEN}✓ Kubernetes API accessible on $VIP:6443${NC}"
else
    echo -e "${RED}✗ Kubernetes API not accessible on $VIP:6443${NC}"
fi

# Test all control plane nodes
healthy_nodes=0
for node in "${CONTROL_PLANES[@]}"; do
    if test_talos_node_health "$node" "Control Plane"; then
        ((healthy_nodes++))
    fi
done

# Test all worker nodes
for node in "${WORKERS[@]}"; do
    if test_talos_node_health "$node" "Worker"; then
        ((healthy_nodes++))
    fi
done

# Overall cluster health
echo -e "\n=== Overall Cluster Health ==="
echo -n "Talos Cluster Health: "
if talosctl health --wait-timeout 30s >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${RED}✗ Unhealthy${NC}"
fi

# Test kubectl if available
echo -e "\nTesting kubectl access..."
if kubectl get nodes --no-headers >/dev/null 2>&1; then
    echo -e "${GREEN}✓ kubectl access successful${NC}"
    echo -e "${CYAN}Cluster Nodes:${NC}"
    kubectl get nodes -o wide
else
    echo -e "${RED}✗ kubectl access failed${NC}"
    echo -e "${YELLOW}Run setup-kubectl script to configure kubectl${NC}"
fi

# Summary
echo -e "\n=== Summary ==="
total_nodes=${#ALL_NODES[@]}
if [[ $healthy_nodes -eq $total_nodes ]]; then
    echo -e "${GREEN}Healthy Nodes: $healthy_nodes/$total_nodes${NC}"
    echo -e "${GREEN}✓ All nodes are healthy and accessible!${NC}"
else
    echo -e "${YELLOW}Healthy Nodes: $healthy_nodes/$total_nodes${NC}"
    echo -e "${YELLOW}⚠ Some nodes may need attention.${NC}"
    echo -e "${GRAY}Check the individual node results above.${NC}"
fi

echo -e "${CYAN}Cluster VIP: $VIP${NC}"
echo -e "${CYAN}Total Control Planes: ${#CONTROL_PLANES[@]}${NC}"
echo -e "${CYAN}Total Workers: ${#WORKERS[@]}${NC}"
