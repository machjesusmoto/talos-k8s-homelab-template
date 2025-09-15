# Execute commands across Talos cluster nodes - Windows version
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("cp", "controlplane", "workers", "all")]
    [string]$Target,
    
    [Parameter(Mandatory=$true, Position=1)]
    [string]$Command
)

$ErrorActionPreference = "Stop"

# Node definitions
$ControlPlanes = @("192.168.1.241", "192.168.1.242", "192.168.1.243")
$Workers = @("192.168.1.244", "192.168.1.245")

# Determine target nodes
switch ($Target.ToLower()) {
    { $_ -in "cp", "controlplane" } {
        $TargetNodes = $ControlPlanes
        $TargetName = "Control Plane"
    }
    "workers" {
        $TargetNodes = $Workers
        $TargetName = "Worker"
    }
    "all" {
        $TargetNodes = $ControlPlanes + $Workers
        $TargetName = "All"
    }
}

Write-Host "=== Executing command on $TargetName nodes ===" -ForegroundColor Green
Write-Host "Command: $Command" -ForegroundColor Cyan
Write-Host "Nodes: $($TargetNodes -join ', ')" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($node in $TargetNodes) {
    Write-Host "=== Node: $node ===" -ForegroundColor Magenta
    
    try {
        # Execute command via talosctl
        $output = talosctl exec --nodes $node -- $Command 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host $output -ForegroundColor Gray
            $successCount++
        } else {
            Write-Host "Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
            Write-Host $output -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host "Error executing command: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== Execution Summary ===" -ForegroundColor Green
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "Total nodes: $($TargetNodes.Count)" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host "`nSome commands failed. Check the output above for details." -ForegroundColor Yellow
    exit 1
}
