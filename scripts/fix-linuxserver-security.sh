#!/bin/bash
# Fix LinuxServer containers security capabilities
# This script adds SETUID/SETGID capabilities to LinuxServer containers

set -euo pipefail

echo "=== LinuxServer Containers Security Fix ==="
echo ""

# List of LinuxServer containers that need security capabilities
declare -a CONTAINERS=(
    "automation/prowlarr"
    "media/radarr"
    "media/sonarr"
    "media/lidarr"
    "media/bazarr"
    "media/readarr"
    "downloads/nzbget"
    "downloads/qbittorrent"
    "downloads/qbittorrent-vpn"
)

# Function to set privileged pod security on namespace
set_namespace_security() {
    local namespace=$1
    echo "→ Setting privileged pod security for namespace: $namespace"
    
    kubectl label ns "$namespace" \
        pod-security.kubernetes.io/enforce=privileged \
        pod-security.kubernetes.io/audit=privileged \
        pod-security.kubernetes.io/warn=privileged \
        --overwrite 2>/dev/null || true
}

# Function to add capabilities to deployment
add_capabilities() {
    local namespace=$1
    local deployment=$2
    
    echo "→ Adding SETUID/SETGID capabilities to $namespace/$deployment"
    
    kubectl patch deployment "$deployment" -n "$namespace" -p '{
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "'$deployment'",
                        "securityContext": {
                            "capabilities": {
                                "add": ["SETGID", "SETUID"],
                                "drop": ["ALL"]
                            }
                        }
                    }]
                }
            }
        }
    }' 2>/dev/null || echo "  Warning: Could not patch $namespace/$deployment (may not exist)"
}

# Set privileged security on required namespaces
echo "Step 1: Setting privileged pod security on namespaces..."
set_namespace_security "automation"
set_namespace_security "media"
set_namespace_security "downloads"

echo ""
echo "Step 2: Adding security capabilities to LinuxServer containers..."

# Process each container
for container in "${CONTAINERS[@]}"; do
    IFS='/' read -r namespace deployment <<< "$container"
    add_capabilities "$namespace" "$deployment"
done

echo ""
echo "Step 3: Checking deployment status..."
sleep 5

# Check status of fixed deployments
echo "Deployment status:"
for container in "${CONTAINERS[@]}"; do
    IFS='/' read -r namespace deployment <<< "$container"
    status=$(kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.replicas}/{.status.readyReplicas}' 2>/dev/null || echo "not found")
    echo "  $namespace/$deployment: $status"
done

echo ""
echo "=== LinuxServer Security Fix Complete ==="
echo ""
echo "If any deployments show 'not found', they may not be deployed yet."
echo "Monitor pod status with: kubectl get pods -A | grep -E '(prowlarr|radarr|sonarr|lidarr|bazarr|readarr|nzbget|qbittorrent)'"