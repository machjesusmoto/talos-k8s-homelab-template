# Diagnose and fix Talos configuration issues - Windows version
$ErrorActionPreference = "Stop"

Write-Host "=== Talos Configuration Diagnosis ===" -ForegroundColor Green

$FirstCP = "192.168.1.241"

# Step 1: Check current talosctl configuration
Write-Host "`nStep 1: Checking talosctl configuration..." -ForegroundColor Yellow
try {
    $configInfo = talosctl config info 2>&1
    Write-Host "Current talosctl config:" -ForegroundColor Cyan
    Write-Host $configInfo
} catch {
    Write-Host "No talosctl configuration found" -ForegroundColor Red
}

# Step 2: Reset and reconfigure talosctl
Write-Host "`nStep 2: Resetting talosctl configuration..." -ForegroundColor Yellow

# Clear existing config
$talosDir = "$env:USERPROFILE\.talos"
if (Test-Path $talosDir) {
    Write-Host "Removing existing talosctl config..." -ForegroundColor Cyan
    Remove-Item -Path $talosDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Check if talosconfig exists
$talosconfigPath = "talos\talosconfig"
if (-not (Test-Path $talosconfigPath)) {
    Write-Error "Talos configuration not found at $talosconfigPath"
    Write-Host "Please run .\scripts\generate-configs.ps1 first" -ForegroundColor Red
    exit 1
}

# Merge configuration fresh
Write-Host "Merging talos configuration..." -ForegroundColor Cyan
try {
    talosctl config merge $talosconfigPath
    Write-Host "✓ Configuration merged successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to merge configuration: $($_.Exception.Message)"
    exit 1
}

# Configure for single node initially
Write-Host "Configuring for single node bootstrap..." -ForegroundColor Cyan
talosctl config endpoints $FirstCP
talosctl config nodes $FirstCP

# Step 3: Test connection
Write-Host "`nStep 3: Testing connection..." -ForegroundColor Yellow
try {
    $version = talosctl version --timeout 10s 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Connection successful!" -ForegroundColor Green
        Write-Host $version
    } else {
        Write-Host "Connection failed:" -ForegroundColor Red
        Write-Host $version
        
        # Try direct node connection
        Write-Host "`nTrying direct node connection..." -ForegroundColor Yellow
        $directVersion = talosctl version --nodes $FirstCP --endpoints $FirstCP --timeout 10s 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Direct connection successful!" -ForegroundColor Green
            Write-Host $directVersion
        } else {
            Write-Host "Direct connection also failed:" -ForegroundColor Red
            Write-Host $directVersion
            
            Write-Host "`nPossible issues:" -ForegroundColor Yellow
            Write-Host "1. Node configuration wasn't applied correctly" -ForegroundColor Cyan
            Write-Host "2. Certificate mismatch between generated config and applied config" -ForegroundColor Cyan
            Write-Host "3. Node needs more time to apply configuration" -ForegroundColor Cyan
            
            Write-Host "`nRecommended actions:" -ForegroundColor Yellow
            Write-Host "1. Wait 2-3 minutes and try again" -ForegroundColor Cyan
            Write-Host "2. Check if node configuration was applied: .\scripts\apply-configs.ps1" -ForegroundColor Cyan
            Write-Host "3. Regenerate configurations if needed: .\scripts\generate-configs.ps1" -ForegroundColor Cyan
            exit 1
        }
    }
} catch {
    Write-Error "Connection test failed: $($_.Exception.Message)"
    exit 1
}

# Step 4: Try bootstrap
Write-Host "`nStep 4: Attempting bootstrap..." -ForegroundColor Yellow
try {
    Write-Host "Bootstrapping etcd on $FirstCP..." -ForegroundColor Cyan
    $bootstrapResult = talosctl bootstrap --timeout 30s 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Bootstrap successful!" -ForegroundColor Green
        Write-Host $bootstrapResult
    } else {
        Write-Host "Bootstrap failed:" -ForegroundColor Red
        Write-Host $bootstrapResult
        
        # Check if it's already bootstrapped
        if ($bootstrapResult -like "*already*" -or $bootstrapResult -like "*initialized*") {
            Write-Host "✓ Cluster appears to already be bootstrapped" -ForegroundColor Green
        } else {
            throw "Bootstrap failed with unexpected error"
        }
    }
} catch {
    Write-Host "Bootstrap error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nThis might be normal if the cluster is already bootstrapped" -ForegroundColor Yellow
}

# Step 5: Check cluster health
Write-Host "`nStep 5: Checking cluster health..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    $health = talosctl health --wait-timeout 30s 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Cluster is healthy!" -ForegroundColor Green
        Write-Host $health
    } else {
        Write-Host "Health check results:" -ForegroundColor Yellow
        Write-Host $health
    }
} catch {
    Write-Host "Health check error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 6: Try to get kubeconfig
Write-Host "`nStep 6: Retrieving kubeconfig..." -ForegroundColor Yellow
try {
    $kubeconfig = talosctl kubeconfig --timeout 30s 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Kubeconfig retrieved successfully!" -ForegroundColor Green
        
        # Test kubectl
        Write-Host "`nTesting kubectl..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        $nodes = kubectl get nodes --timeout=30s 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ kubectl working!" -ForegroundColor Green
            Write-Host $nodes
        } else {
            Write-Host "kubectl not ready yet:" -ForegroundColor Yellow
            Write-Host $nodes
            Write-Host "This is normal - Kubernetes may still be starting" -ForegroundColor Cyan
        }
    } else {
        Write-Host "Kubeconfig retrieval failed:" -ForegroundColor Red
        Write-Host $kubeconfig
    }
} catch {
    Write-Host "Kubeconfig error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Diagnosis Complete ===" -ForegroundColor Green
Write-Host "`nIf successful, your cluster should be ready!" -ForegroundColor Yellow
Write-Host "If there were errors, check the output above for specific guidance." -ForegroundColor Yellow
