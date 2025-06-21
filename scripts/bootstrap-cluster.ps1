# Bootstrap and verify Talos cluster - Windows version
$ErrorActionPreference = "Stop"

Write-Host "=== Bootstrapping Talos Cluster ===" -ForegroundColor Green

# Configuration
$FirstCP = "192.168.1.241"
$AllCPs = @("192.168.1.241", "192.168.1.242", "192.168.1.243")

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if talosconfig exists
$talosconfigPath = "talos\talosconfig"
if (-not (Test-Path $talosconfigPath)) {
    Write-Error "Talos configuration not found at $talosconfigPath"
    Write-Host "Please run .\scripts\generate-configs.ps1 first" -ForegroundColor Red
    exit 1
}

# Check if secrets.yaml exists
if (-not (Test-Path "secrets.yaml")) {
    Write-Error "secrets.yaml not found. Please run .\scripts\generate-configs.ps1 first"
    exit 1
}

Write-Host "✓ Prerequisites check passed" -ForegroundColor Green

# Configure talosctl first
Write-Host "`nConfiguring talosctl..." -ForegroundColor Yellow
try {
    talosctl config merge $talosconfigPath
    talosctl config endpoints $AllCPs
    talosctl config nodes $AllCPs
    Write-Host "✓ talosctl configured successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to configure talosctl: $($_.Exception.Message)"
    exit 1
}

# Verify connectivity to first control plane
Write-Host "`nTesting connectivity to first control plane ($FirstCP)..." -ForegroundColor Yellow
try {
    $testResult = talosctl version --nodes $FirstCP 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Connectivity test passed" -ForegroundColor Green
    } else {
        throw "Connection failed"
    }
} catch {
    Write-Error "Cannot connect to $FirstCP. Please ensure:"
    Write-Host "1. VM is running and network is accessible" -ForegroundColor Red
    Write-Host "2. Talos configuration has been applied with .\scripts\apply-configs.ps1" -ForegroundColor Red
    exit 1
}

# Bootstrap etcd on first control plane
Write-Host "`nBootstrapping etcd on $FirstCP..." -ForegroundColor Yellow
try {
    talosctl bootstrap --nodes $FirstCP --endpoints $FirstCP
    Write-Host "✓ Bootstrap command sent successfully" -ForegroundColor Green
} catch {
    Write-Error "Bootstrap failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nWaiting for bootstrap to complete..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Wait for cluster to be ready (check single node first)
Write-Host "`nWaiting for first control plane to be ready..." -ForegroundColor Yellow
$timeout = 300  # 5 minutes
$elapsed = 0
$bootstrapReady = $false

while ($elapsed -lt $timeout) {
    try {
        # Check health of just the first node
        $healthCheck = talosctl health --nodes $FirstCP --wait-timeout 10s 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ First control plane is healthy!" -ForegroundColor Green
            $bootstrapReady = $true
            break
        }
    } catch {
        # Continue waiting
    }
    
    Write-Host "." -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds 10
    $elapsed += 10
}

if (-not $bootstrapReady) {
    Write-Error "`nBootstrap health check timed out after $($timeout) seconds"
    Write-Host "Check cluster status with: talosctl health --nodes $FirstCP" -ForegroundColor Yellow
    exit 1
}

# Wait a bit more for other nodes to join
Write-Host "`nWaiting for other control plane nodes to join..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check overall cluster health
Write-Host "`nChecking overall cluster health..." -ForegroundColor Yellow
try {
    $clusterHealth = talosctl health --wait-timeout 60s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Cluster is healthy!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Some nodes may still be joining. This is normal." -ForegroundColor Yellow
        Write-Host "You can check individual node status with: talosctl health --nodes <ip>" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠ Cluster health check had issues, but this may be normal during initial startup" -ForegroundColor Yellow
}

# Get kubeconfig
Write-Host "`nRetrieving kubeconfig..." -ForegroundColor Yellow
try {
    talosctl kubeconfig --merge=$false --force
    Write-Host "✓ Kubeconfig retrieved" -ForegroundColor Green
} catch {
    Write-Error "Failed to retrieve kubeconfig: $($_.Exception.Message)"
    Write-Host "You can retry with: talosctl kubeconfig" -ForegroundColor Yellow
}

# Copy to default location if it doesn't exist
$kubeconfigPath = "$env:USERPROFILE\.kube\config"
if (-not (Test-Path $kubeconfigPath)) {
    Write-Host "Copying kubeconfig to default location..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.kube" -Force | Out-Null
    if (Test-Path ".\kubeconfig") {
        Copy-Item -Path ".\kubeconfig" -Destination $kubeconfigPath
        Write-Host "✓ Kubeconfig copied to $kubeconfigPath" -ForegroundColor Green
    }
}

# Test kubectl access
Write-Host "`nTesting kubectl access..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes --no-headers 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ kubectl access successful!" -ForegroundColor Green
        Write-Host "`n=== Cluster Information ===" -ForegroundColor Green
        Write-Host "API Endpoint: https://192.168.1.240:6443"
        Write-Host "Nodes:"
        kubectl get nodes -o wide
    } else {
        Write-Host "⚠ kubectl access not ready yet" -ForegroundColor Yellow
        Write-Host "Try: .\scripts\setup-kubectl.ps1" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠ kubectl not available or cluster not fully ready" -ForegroundColor Yellow
    Write-Host "This is normal immediately after bootstrap. Wait a few minutes and try:" -ForegroundColor Cyan
    Write-Host "  .\scripts\setup-kubectl.ps1" -ForegroundColor Gray
}

Write-Host "`n✅ Bootstrap process completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for all nodes to fully join" -ForegroundColor Cyan
Write-Host "2. Verify cluster: .\scripts\verify-access.ps1" -ForegroundColor Cyan
Write-Host "3. Deploy core infrastructure: kubectl apply -k kubernetes\core\" -ForegroundColor Cyan
Write-Host "4. Set up GitOps: kubectl apply -k kubernetes\gitops\" -ForegroundColor Cyan

Write-Host "`nIf you encounter issues:" -ForegroundColor Yellow
Write-Host "- Check node status: talosctl health --nodes <ip>" -ForegroundColor Gray
Write-Host "- View logs: talosctl logs --nodes <ip>" -ForegroundColor Gray
Write-Host "- Check all nodes: .\scripts\verify-access.ps1" -ForegroundColor Gray
