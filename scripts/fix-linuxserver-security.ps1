# Fix LinuxServer containers security capabilities
# This script adds SETUID/SETGID capabilities to LinuxServer containers

$ErrorActionPreference = "Stop"

Write-Host "=== LinuxServer Containers Security Fix ===" -ForegroundColor Green
Write-Host ""

# List of LinuxServer containers that need security capabilities
$containers = @(
    "automation/prowlarr",
    "media/radarr",
    "media/sonarr",
    "media/lidarr",
    "media/bazarr",
    "media/readarr",
    "downloads/nzbget",
    "downloads/qbittorrent",
    "downloads/qbittorrent-vpn"
)

# Function to set privileged pod security on namespace
function Set-NamespaceSecurity {
    param([string]$namespace)
    
    Write-Host "→ Setting privileged pod security for namespace: $namespace" -ForegroundColor Yellow
    
    try {
        kubectl label ns $namespace `
            pod-security.kubernetes.io/enforce=privileged `
            pod-security.kubernetes.io/audit=privileged `
            pod-security.kubernetes.io/warn=privileged `
            --overwrite 2>$null
    } catch {
        Write-Host "  Warning: Could not set security labels for $namespace" -ForegroundColor Yellow
    }
}

# Function to add capabilities to deployment
function Add-Capabilities {
    param([string]$namespace, [string]$deployment)
    
    Write-Host "→ Adding SETUID/SETGID capabilities to $namespace/$deployment" -ForegroundColor Yellow
    
    $patch = @"
{
    "spec": {
        "template": {
            "spec": {
                "containers": [{
                    "name": "$deployment",
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
}
"@
    
    try {
        kubectl patch deployment $deployment -n $namespace -p $patch 2>$null
    } catch {
        Write-Host "  Warning: Could not patch $namespace/$deployment (may not exist)" -ForegroundColor Yellow
    }
}

# Set privileged security on required namespaces
Write-Host "Step 1: Setting privileged pod security on namespaces..." -ForegroundColor Cyan
Set-NamespaceSecurity "automation"
Set-NamespaceSecurity "media"
Set-NamespaceSecurity "downloads"

Write-Host ""
Write-Host "Step 2: Adding security capabilities to LinuxServer containers..." -ForegroundColor Cyan

# Process each container
foreach ($container in $containers) {
    $parts = $container.Split('/')
    $namespace = $parts[0]
    $deployment = $parts[1]
    Add-Capabilities $namespace $deployment
}

Write-Host ""
Write-Host "Step 3: Checking deployment status..." -ForegroundColor Cyan
Start-Sleep 5

# Check status of fixed deployments
Write-Host "Deployment status:"
foreach ($container in $containers) {
    $parts = $container.Split('/')
    $namespace = $parts[0]
    $deployment = $parts[1]
    
    try {
        $status = kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.replicas}/{.status.readyReplicas}' 2>$null
        Write-Host "  $namespace/$deployment`: $status" -ForegroundColor Green
    } catch {
        Write-Host "  $namespace/$deployment`: not found" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== LinuxServer Security Fix Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "If any deployments show 'not found', they may not be deployed yet."
Write-Host "Monitor pod status with: kubectl get pods -A | grep -E '(prowlarr|radarr|sonarr|lidarr|bazarr|readarr|nzbget|qbittorrent)'"