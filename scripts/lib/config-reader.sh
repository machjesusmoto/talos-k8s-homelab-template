#!/bin/bash
# Shared configuration reader library for all scripts
# Source this file to read values from configurations.yaml

# Ensure yq is available for YAML parsing
ensure_yq() {
    if ! command -v yq &> /dev/null; then
        echo "Installing yq for YAML parsing..."
        local YQ_VERSION="v4.35.1"
        local YQ_BINARY="yq_linux_amd64"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            YQ_BINARY="yq_darwin_amd64"
        fi
        
        curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -o /tmp/yq
        chmod +x /tmp/yq
        sudo mv /tmp/yq /usr/local/bin/yq
    fi
}

# Initialize configuration
init_config() {
    # Get the project root directory
    local SCRIPT_PATH="${BASH_SOURCE[1]}"  # The script that sourced this library
    local SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    
    # Handle different script locations (scripts/ or scripts/lib/)
    if [[ "$SCRIPT_DIR" == */scripts/lib ]]; then
        export PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    else
        export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    fi
    
    export CONFIG_FILE="$PROJECT_ROOT/configurations.yaml"
    
    # Check if configurations.yaml exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: configurations.yaml not found at $CONFIG_FILE"
        echo "Please create it from configurations.yaml.template"
        exit 1
    fi
    
    ensure_yq
}

# Read a simple value from config
get_config() {
    local path=$1
    local default=${2:-}
    
    local value=$(yq eval "$path" "$CONFIG_FILE" 2>/dev/null)
    
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Read an array from config
get_config_array() {
    local path=$1
    yq eval "$path" "$CONFIG_FILE" 2>/dev/null | grep -v "^null$" || true
}

# Check if a value exists and is not empty
config_exists() {
    local path=$1
    local value=$(get_config "$path")
    [ -n "$value" ] && [ "$value" != "null" ]
}

# Load common configuration values
load_common_config() {
    # Cluster configuration
    export CLUSTER_NAME=$(get_config '.cluster.name' 'homelab')
    export CLUSTER_VIP=$(get_config '.network.cluster_vip' '192.168.1.240')
    export KUBERNETES_API_PORT=$(get_config '.cluster.kubernetes_api_port' '6443')
    export TALOS_API_PORT=$(get_config '.cluster.talos_api_port' '50000')
    export TALOS_VERSION=$(get_config '.cluster.talos_version' 'v1.7.5')
    export ARCHITECTURE=$(get_config '.cluster.architecture' 'amd64')
    
    # Domain configuration
    export BASE_DOMAIN=$(get_config '.domain.base' 'k8s.example.com')
    export ADMIN_EMAIL=$(get_config '.domain.email' 'admin@example.com')
    
    # Network configuration
    export METALLB_RANGE=$(get_config '.network.metallb_ip_range' '192.168.1.200-192.168.1.239')
    
    # Storage configuration
    export NFS_SERVER=$(get_config '.storage.nfs_server' '192.168.1.10')
    export NFS_PATH=$(get_config '.storage.nfs_path' '/mnt/storage')
    
    # External services
    export TALOS_FACTORY_URL=$(get_config '.external_services.talos_factory_url' 'https://factory.talos.dev')
}

# Get all control plane IPs
get_control_plane_ips() {
    get_config_array '.cluster.control_planes[].ip'
}

# Get all worker IPs
get_worker_ips() {
    get_config_array '.cluster.workers[].ip'
}

# Get all node IPs (control planes + workers)
get_all_node_ips() {
    get_control_plane_ips
    get_worker_ips
}

# Get node info by IP
get_node_hostname() {
    local ip=$1
    # Try control planes first
    local hostname=$(yq eval ".cluster.control_planes[] | select(.ip == \"$ip\") | .hostname" "$CONFIG_FILE" 2>/dev/null)
    
    # If not found, try workers
    if [ -z "$hostname" ] || [ "$hostname" = "null" ]; then
        hostname=$(yq eval ".cluster.workers[] | select(.ip == \"$ip\") | .hostname" "$CONFIG_FILE" 2>/dev/null)
    fi
    
    echo "${hostname:-unknown}"
}

# Get Proxmox VM ID for a node IP
get_proxmox_vmid() {
    local ip=$1
    if config_exists '.proxmox.enabled' && [ "$(get_config '.proxmox.enabled')" = "true" ]; then
        get_config ".proxmox.vm_mappings.\"$ip\"" ""
    fi
}

# Initialize when sourced
init_config