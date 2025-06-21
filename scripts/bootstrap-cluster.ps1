# Bootstrap and verify Talos cluster - Windows version
$ErrorActionPreference = "Stop"

Write-Host "=== Bootstrapping Talos Cluster ===" -ForegroundColor Green

# Configuration
$FirstCP = "192.168.1.241"
$AllCPs = "192.168.1.241", "192.168.1.242", "192.168.1.243"

# Bootstrap etcd on first control plane
Write-Host "Bootstrapping etcd on $FirstCP..." -ForegroundColor Yellow
talosctl bootstrap --nodes $FirstCP --endpoints $FirstCP

Write-Host "Waiting for bootstrap to complete..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Configure talosctl
Write-Host "`nConfiguring talosctl..." -ForegroundColor Yellow
talosctl config merge talos\talosconfig
talosctl config endpoints $AllCPs
talosctl config nodes $AllCPs

# Wait for cluster to be ready
Write-Host "`nWaiting for cluster to be ready..." -ForegroundColor Yellow
$timeout = 300  # 5 minutes
$elapsed = 0
while ($elapsed -lt $timeout) {
    try {
        talosctl health --wait-timeout 30s | Out-Null
        Write-Host "Cluster is healthy!" -ForegroundColor Green
        break
    } catch {
        Write-Host "Cluster not ready yet, waiting..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $elapsed += 10
    }
}

if ($elapsed -ge $timeout) {
    Write-Error "Cluster health check timed out"
    exit 1
}

# Get kubeconfig
Write-Host "`nRetrieving kubeconfig..." -ForegroundColor Yellow
talosctl kubeconfig

# Copy to default location if it doesn't exist
$kubeconfigPath = "$env:USERPROFILE\.kube\config"
if (-not (Test-Path $kubeconfigPath)) {
    Write-Host "Copying kubeconfig to default location..."
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.kube" -Force | Out-Null
    Copy-Item -Path ".\kubeconfig" -Destination $kubeconfigPath
}

# Test kubectl access
Write-Host "`nTesting kubectl access..." -ForegroundColor Yellow
kubectl get nodes

Write-Host "`n=== Cluster Information ===" -ForegroundColor Green
Write-Host "API Endpoint: https://192.168.1.240:6443"
Write-Host "Nodes:"
kubectl get nodes -o wide

Write-Host "`nTalos cluster is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy core infrastructure: kubectl apply -k kubernetes\core\" -ForegroundColor Cyan
Write-Host "2. Set up GitOps: kubectl apply -k kubernetes\gitops\" -ForegroundColor Cyan
