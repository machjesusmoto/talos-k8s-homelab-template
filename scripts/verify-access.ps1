# Verify Talos cluster access and health - Windows version
$ErrorActionPreference = "Stop"

Write-Host "=== Verifying Talos Cluster Access and Health ===" -ForegroundColor Green

# Talos cluster nodes
$ControlPlanes = @("192.168.1.241", "192.168.1.242", "192.168.1.243")
$Workers = @("192.168.1.244", "192.168.1.245")
$AllNodes = $ControlPlanes + $Workers
$VIP = "192.168.1.240"

function Test-TalosNodeHealth {
    param([string]$NodeIP, [string]$NodeType)
    
    Write-Host "`n=== Testing $NodeType Node: $NodeIP ===" -ForegroundColor Cyan
    
    # Test network connectivity
    Write-Host "Network Connectivity: " -NoNewline
    try {
        $ping = Test-NetConnection -ComputerName $NodeIP -Port 50000 -WarningAction SilentlyContinue
        if ($ping.TcpTestSucceeded) {
            Write-Host "✓ Success" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed (Port 50000 not accessible)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ Failed (Network error)" -ForegroundColor Red
        return $false
    }
    
    # Test Talos API
    Write-Host "Talos API Access: " -NoNewline
    try {
        $result = talosctl version --nodes $NodeIP 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Success" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ Failed" -ForegroundColor Red
        return $false
    }
    
    # Get node info
    try {
        Write-Host "Node Information:" -ForegroundColor Yellow
        $machineConfig = talosctl get machineconfig -o json --nodes $NodeIP 2>$null | ConvertFrom-Json
        $hostname = talosctl get hostname --nodes $NodeIP -o jsonpath='{.spec.hostname}' 2>$null
        
        Write-Host "  Hostname: $hostname"
        Write-Host "  IP: $NodeIP"
        
        # Get resource usage if possible
        try {
            $memInfo = talosctl read /proc/meminfo --nodes $NodeIP 2>$null | Select-String "MemTotal"
            if ($memInfo) {
                $memTotal = ($memInfo -split '\s+')[1]
                $memGB = [math]::Round([int]$memTotal / 1024 / 1024, 1)
                Write-Host "  Memory: $memGB GB"
            }
            
            $cpuInfo = talosctl read /proc/cpuinfo --nodes $NodeIP 2>$null | Select-String "processor" | Measure-Object
            Write-Host "  CPU Cores: $($cpuInfo.Count)"
        } catch {
            Write-Host "  Resources: Unable to query" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "Unable to retrieve detailed node information" -ForegroundColor Gray
    }
    
    return $true
}

# Check talosctl configuration
Write-Host "`nChecking talosctl configuration..." -ForegroundColor Yellow
try {
    $configInfo = talosctl config info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ talosctl is configured" -ForegroundColor Green
        $configInfo | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } else {
        Write-Host "✗ talosctl not configured properly" -ForegroundColor Red
        Write-Host "Run: talosctl config merge talos\talosconfig" -ForegroundColor Yellow
        return
    }
} catch {
    Write-Host "✗ Failed to check talosctl configuration" -ForegroundColor Red
    return
}

# Test VIP accessibility
Write-Host "`nTesting Kubernetes API VIP ($VIP)..." -ForegroundColor Yellow
try {
    $vipTest = Test-NetConnection -ComputerName $VIP -Port 6443 -WarningAction SilentlyContinue
    if ($vipTest.TcpTestSucceeded) {
        Write-Host "✓ Kubernetes API accessible on $VIP`:6443" -ForegroundColor Green
    } else {
        Write-Host "✗ Kubernetes API not accessible on $VIP`:6443" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Failed to test VIP connectivity" -ForegroundColor Red
}

# Test all control plane nodes
$healthyNodes = 0
foreach ($node in $ControlPlanes) {
    if (Test-TalosNodeHealth -NodeIP $node -NodeType "Control Plane") {
        $healthyNodes++
    }
}

# Test all worker nodes
foreach ($node in $Workers) {
    if (Test-TalosNodeHealth -NodeIP $node -NodeType "Worker") {
        $healthyNodes++
    }
}

# Overall cluster health
Write-Host "`n=== Overall Cluster Health ===" -ForegroundColor Green
try {
    Write-Host "Talos Cluster Health: " -NoNewline
    $healthCheck = talosctl health --wait-timeout 30s 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Healthy" -ForegroundColor Green
    } else {
        Write-Host "✗ Unhealthy" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Health check failed" -ForegroundColor Red
}

# Test kubectl if available
Write-Host "`nTesting kubectl access..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes --no-headers 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ kubectl access successful" -ForegroundColor Green
        Write-Host "Cluster Nodes:" -ForegroundColor Cyan
        kubectl get nodes -o wide
    } else {
        Write-Host "✗ kubectl access failed" -ForegroundColor Red
        Write-Host "Run setup-kubectl script to configure kubectl" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ kubectl not available or configured" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Healthy Nodes: $healthyNodes/$($AllNodes.Count)" -ForegroundColor $(if ($healthyNodes -eq $AllNodes.Count) { "Green" } else { "Yellow" })
Write-Host "Cluster VIP: $VIP" -ForegroundColor Cyan
Write-Host "Total Control Planes: $($ControlPlanes.Count)" -ForegroundColor Cyan
Write-Host "Total Workers: $($Workers.Count)" -ForegroundColor Cyan

if ($healthyNodes -eq $AllNodes.Count) {
    Write-Host "`n✓ All nodes are healthy and accessible!" -ForegroundColor Green
} else {
    Write-Host "`n⚠ Some nodes may need attention." -ForegroundColor Yellow
    Write-Host "Check the individual node results above." -ForegroundColor Gray
}
