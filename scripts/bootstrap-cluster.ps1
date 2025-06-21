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
    # Configure endpoints but don't set multiple nodes for bootstrap
    talosctl config endpoints $FirstCP
    talosctl config nodes $FirstCP
    Write-Host "✓ talosctl configured for bootstrap node ($FirstCP)" -ForegroundColor Green
} catch {
    Write-Error "Failed to configure talosctl: $($_.Exception.Message)"
    exit 1
}

# Verify connectivity and configuration to first control plane
Write-Host "`nTesting connectivity and configuration..." -ForegroundColor Yellow
try {
    $testResult = talosctl version --nodes $FirstCP 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Node configuration and connectivity verified" -ForegroundColor Green
    } else {
        throw "Connection or configuration failed"
    }
} catch {
    Write-Error "Cannot connect to $FirstCP or configuration not applied. Please ensure:"
    Write-Host "1. Talos configuration has been applied with .\scripts\apply-configs.ps1" -ForegroundColor Red
    Write-Host "2. Node has restarted and applied the configuration (wait 1-2 minutes)" -ForegroundColor Red
    Write-Host "3. Check node status: talosctl --nodes $FirstCP get members" -ForegroundColor Yellow
    exit 1
}

# Bootstrap etcd on first control plane
Write-Host "`nBootstrapping etcd on $FirstCP..." -ForegroundColor Yellow
try {
    talosctl bootstrap --nodes $FirstCP --endpoints $FirstCP
    Write-Host "✓ Bootstrap command sent successfully" -ForegroundColor Green
} catch {
    Write-Error "Bootstrap failed: $($_.Exception.Message)"
    Write-Host "`nPossible solutions:" -ForegroundColor Yellow
    Write-Host "1. Ensure node configuration is applied: .\scripts\apply-configs.ps1" -ForegroundColor Cyan
    Write-Host "2. Wait for node to fully apply config (1-2 minutes)" -ForegroundColor Cyan
    Write-Host "3. Check node logs: talosctl logs --nodes $FirstCP" -ForegroundColor Cyan
    exit 1
}

Write-Host "`nWaiting for bootstrap to complete..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Wait for first control plane to be ready
Write-Host "`nWaiting for first control plane to be ready..." -ForegroundColor Yellow
$timeout = 300  # 5 minutes
$elapsed = 0
$bootstrapReady = $false

while ($elapsed -lt $timeout) {
    try {
        # Check health of just the first node with specific parameters
        $healthCheck = talosctl health --nodes $FirstCP --endpoints $FirstCP --wait-timeout 10s 2>$null
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
    Write-Host "Check cluster status with: talosctl health --nodes $FirstCP --endpoints $FirstCP" -ForegroundColor Yellow
    exit 1
}

# Now configure for all nodes
Write-Host "`nConfiguring talosctl for all control plane nodes..." -ForegroundColor Yellow
talosctl config endpoints $AllCPs
talosctl config nodes $AllCPs

# Wait for other nodes to join
Write-Host "`nWaiting for other control plane nodes to join..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Check overall cluster health with specific node targeting
Write-Host "`nChecking overall cluster health..." -ForegroundColor Yellow
try {
    # Use the init node parameter for health check
    $clusterHealth = talosctl health --init-node $FirstCP --control-plane-nodes $($AllCPs -join ",") --wait-timeout 60s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Cluster is healthy!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Some nodes may still be joining. This is normal." -ForegroundColor Yellow
        Write-Host "Check individual nodes: talosctl health --nodes <ip> --endpoints <ip>" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠ Cluster health check had issues, but this may be normal during initial startup" -ForegroundColor Yellow
}

# Get kubeconfig from the first control plane
Write-Host "`nRetrieving kubeconfig..." -ForegroundColor Yellow
try {
    # Use single node for kubeconfig retrieval
    talosctl kubeconfig --nodes $FirstCP --endpoints $FirstCP --force
    Write-Host "✓ Kubeconfig retrieved" -ForegroundColor Green
} catch {
    Write-Error "Failed to retrieve kubeconfig: $($_.Exception.Message)"
    Write-Host "You can retry with: talosctl kubeconfig --nodes $FirstCP --endpoints $FirstCP" -ForegroundColor Yellow
}

# Copy to default location
$kubeconfigPath = "$env:USERPROFILE\.kube\config"
if (-not (Test-Path $kubeconfigPath)) {
    Write-Host "Copying kubeconfig to default location..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.kube" -Force | Out-Null
}

# Look for kubeconfig file (it might be named differently)
$possibleConfigs = @(".\kubeconfig", ".\talosconfig", "kubeconfig")
$configFound = $false

foreach ($configFile in $possibleConfigs) {
    if (Test-Path $configFile) {
        Copy-Item -Path $configFile -Destination $kubeconfigPath -Force
        Write-Host "✓ Kubeconfig copied to $kubeconfigPath" -ForegroundColor Green
        $configFound = $true
        break
    }
}

if (-not $configFound) {
    Write-Host "⚠ Kubeconfig file not found locally. Trying direct retrieval..." -ForegroundColor Yellow
    try {
        talosctl kubeconfig --nodes $FirstCP --endpoints $FirstCP $kubeconfigPath
        Write-Host "✓ Kubeconfig saved directly to $kubeconfigPath" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not save kubeconfig. Try manually: talosctl kubeconfig" -ForegroundColor Yellow
    }
}

# Test kubectl access
Write-Host "`nTesting kubectl access..." -ForegroundColor Yellow
Start-Sleep -Seconds 10  # Give k8s a moment to start

try {
    $env:KUBECONFIG = $kubeconfigPath
    $nodes = kubectl get nodes --no-headers --request-timeout=30s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ kubectl access successful!" -ForegroundColor Green
        Write-Host "`n=== Cluster Information ===" -ForegroundColor Green
        Write-Host "API Endpoint: https://192.168.1.240:6443"
        Write-Host "Nodes:"
        kubectl get nodes -o wide
    } else {
        Write-Host "⚠ kubectl access not ready yet" -ForegroundColor Yellow
        Write-Host "Kubernetes may still be starting. Wait 2-3 minutes and try:" -ForegroundColor Cyan
        Write-Host "  kubectl get nodes" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠ kubectl not available or cluster not fully ready" -ForegroundColor Yellow
    Write-Host "This is normal immediately after bootstrap. Wait a few minutes." -ForegroundColor Cyan
}

Write-Host "`n✅ Bootstrap process completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for Kubernetes to fully start" -ForegroundColor Cyan
Write-Host "2. Verify cluster: .\scripts\verify-access.ps1" -ForegroundColor Cyan
Write-Host "3. Test kubectl: kubectl get nodes -o wide" -ForegroundColor Cyan
Write-Host "4. Deploy core infrastructure when ready" -ForegroundColor Cyan

Write-Host "`nIf you encounter issues:" -ForegroundColor Yellow
Write-Host "- Check individual nodes: talosctl health --nodes <ip> --endpoints <ip>" -ForegroundColor Gray
Write-Host "- View logs: talosctl logs --nodes <ip> --endpoints <ip>" -ForegroundColor Gray
Write-Host "- Verify all nodes: .\scripts\verify-access.ps1" -ForegroundColor Gray
