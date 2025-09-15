# Graceful cluster shutdown script for hardware maintenance
param(
    [switch]$QuickShutdown
)

Write-Host "=== Kubernetes Cluster Graceful Shutdown ===" -ForegroundColor Cyan
Write-Host "This script will safely shutdown your cluster for hardware maintenance"
Write-Host ""

function Scale-DownApplications {
    Write-Host "→ Scaling down application deployments..." -ForegroundColor Yellow
    
    # Get all non-system deployments
    $deployments = kubectl get deployments -A -o json | ConvertFrom-Json
    $deployments.items | Where-Object { 
        $_.metadata.namespace -notmatch "kube-system|cert-manager|metallb-system|ingress-nginx|nfs-csi" 
    } | ForEach-Object {
        Write-Host "  Scaling down $($_.metadata.namespace)/$($_.metadata.name)"
        kubectl scale deployment $_.metadata.name -n $_.metadata.namespace --replicas=0
    }
    
    # Scale down statefulsets
    Write-Host "→ Scaling down statefulsets..." -ForegroundColor Yellow
    $statefulsets = kubectl get statefulsets -A -o json | ConvertFrom-Json
    $statefulsets.items | Where-Object { 
        $_.metadata.namespace -ne "kube-system" 
    } | ForEach-Object {
        Write-Host "  Scaling down $($_.metadata.namespace)/$($_.metadata.name)"
        kubectl scale statefulset $_.metadata.name -n $_.metadata.namespace --replicas=0
    }
    
    Write-Host "→ Waiting for pods to terminate..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

function Shutdown-Nodes {
    Write-Host ""
    Write-Host "→ Shutting down nodes..." -ForegroundColor Yellow
    
    # Shutdown workers first
    Write-Host "  Shutting down worker nodes..." -ForegroundColor Cyan
    Write-Host "    Shutting down talos-worker-01"
    talosctl -n "192.168.1.244" shutdown 2>$null
    
    Start-Sleep -Seconds 10
    
    # Shutdown control plane nodes
    Write-Host "  Shutting down control plane nodes..." -ForegroundColor Cyan
    # Shutdown cp-03 first (non-VIP holder)
    Write-Host "    Shutting down talos-cp-03"
    talosctl -n "192.168.1.243" shutdown 2>$null
    
    Start-Sleep -Seconds 5
    
    # Shutdown cp-01 last (VIP holder)
    Write-Host "    Shutting down talos-cp-01"
    talosctl -n "192.168.1.241" shutdown 2>$null
}

# Main execution
if (-not $QuickShutdown) {
    Write-Host "Choose shutdown type:" -ForegroundColor Green
    Write-Host "1) Full shutdown with application scaling (recommended)"
    Write-Host "2) Quick shutdown (nodes only)"
    $choice = Read-Host "Enter choice [1-2]"
} else {
    $choice = "2"
}

switch ($choice) {
    "1" {
        Scale-DownApplications
        Shutdown-Nodes
    }
    "2" {
        Write-Host "→ Proceeding with quick shutdown..." -ForegroundColor Yellow
        Shutdown-Nodes
    }
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Shutdown Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "To restart the cluster after hardware maintenance:" -ForegroundColor Cyan
Write-Host "1. Power on nodes in this order: cp-01, cp-03, worker-01"
Write-Host "2. Wait for control plane to form quorum"
Write-Host "3. Run: kubectl get nodes"
Write-Host "4. If doing full shutdown, run: .\scripts\cluster-startup.ps1"
Write-Host ""
Write-Host "To rejoin cp-02 and worker-02 after restart:" -ForegroundColor Cyan
Write-Host "1. Apply their configurations: .\scripts\apply-configs.ps1"
Write-Host "2. They will automatically join the cluster"