# Setup kubectl for Talos cluster - Windows version
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigName = "talos-cluster"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Setting up kubectl for Talos cluster ===" -ForegroundColor Green

# Talos cluster configuration
$VIP = "192.168.1.240"
$KubeconfigPath = "$env:USERPROFILE\.kube\config"

Write-Host "Setting up kubectl for Talos cluster..." -ForegroundColor Yellow

# Create .kube directory if it doesn't exist
$kubeDir = "$env:USERPROFILE\.kube"
if (-not (Test-Path $kubeDir)) {
    Write-Host "Creating .kube directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $kubeDir -Force | Out-Null
}

# Get kubeconfig from Talos
Write-Host "Retrieving kubeconfig from Talos cluster..." -ForegroundColor Cyan
try {
    talosctl kubeconfig --merge=$false | Out-File -FilePath ".\kubeconfig-temp" -Encoding ASCII
    
    # Copy to standard location
    if (Test-Path $KubeconfigPath) {
        $backup = "$KubeconfigPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "Backing up existing kubeconfig to $backup" -ForegroundColor Yellow
        Copy-Item -Path $KubeconfigPath -Destination $backup
    }
    
    Copy-Item -Path ".\kubeconfig-temp" -Destination $KubeconfigPath
    Remove-Item -Path ".\kubeconfig-temp" -Force
    
    Write-Host "Kubeconfig saved to $KubeconfigPath" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to retrieve kubeconfig: $($_.Exception.Message)"
    exit 1
}

# Set KUBECONFIG environment variable for current session
$env:KUBECONFIG = $KubeconfigPath

# Test connection
Write-Host "`nTesting connection..." -ForegroundColor Yellow
try {
    kubectl get nodes -o wide
    Write-Host "`nkubectl configured successfully for Talos cluster!" -ForegroundColor Green
    Write-Host "API Server: https://$VIP`:6443" -ForegroundColor Cyan
    Write-Host "Kubeconfig: $KubeconfigPath" -ForegroundColor Cyan
    
    Write-Host "`nTo use kubectl in new sessions, ensure KUBECONFIG is set:" -ForegroundColor Yellow
    Write-Host "`$env:KUBECONFIG = '$KubeconfigPath'" -ForegroundColor Gray
    
} catch {
    Write-Error "Failed to connect to cluster: $($_.Exception.Message)"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure Talos cluster is bootstrapped and healthy" -ForegroundColor Cyan
    Write-Host "2. Check talosctl configuration: talosctl config info" -ForegroundColor Cyan
    Write-Host "3. Verify cluster health: talosctl health" -ForegroundColor Cyan
    exit 1
}
