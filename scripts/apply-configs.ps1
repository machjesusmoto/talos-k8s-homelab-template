# Apply Talos configurations to nodes - Windows version
$ErrorActionPreference = "Stop"

# Load configuration library
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\lib\Config-Reader.ps1"

Write-Host "=== Applying Talos Configurations ===" -ForegroundColor Green
Write-Host "Using configurations from: $script:ConfigFile" -ForegroundColor Cyan

# Get node lists from configuration
$CPNodes = Get-ControlPlaneIPs
$WorkerNodes = Get-WorkerIPs

Write-Host "`nTarget nodes from configuration:" -ForegroundColor Yellow
Write-Host "Control Plane Nodes:" -ForegroundColor Cyan
foreach ($ip in $CPNodes) {
    $hostname = Get-NodeHostname -IP $ip
    Write-Host "  - ${hostname}: $ip"
}

Write-Host "Worker Nodes:" -ForegroundColor Cyan
foreach ($ip in $WorkerNodes) {
    $hostname = Get-NodeHostname -IP $ip
    Write-Host "  - ${hostname}: $ip"
}

# Build Proxmox VM configuration if enabled
$ProxmoxVMs = @{}
if (Test-ConfigValue -Path 'proxmox.enabled') {
    $proxmoxEnabled = Get-ConfigValue -Path 'proxmox.enabled'
    if ($proxmoxEnabled -eq $true) {
        $allIPs = $CPNodes + $WorkerNodes
        foreach ($ip in $allIPs) {
            $vmid = Get-ProxmoxVMID -IP $ip
            $node = Get-ConfigValue -Path 'proxmox.node' -Default 'proxmox-node1'
            if ($vmid) {
                $ProxmoxVMs[$ip] = @{ vmid = $vmid; node = $node }
            }
        }
        Write-Host "`nProxmox integration enabled for VM management" -ForegroundColor Green
    }
}

# Function to eject ISO from Proxmox VM (requires pvesh/API access)
function Remove-ProxmoxISO {
    param($NodeIP)
    
    if ($ProxmoxVMs.ContainsKey($NodeIP)) {
        $vm = $ProxmoxVMs[$NodeIP]
        Write-Host "  Attempting to eject ISO from VM $($vm.vmid)..." -ForegroundColor Gray
        
        try {
            # Method 1: Using pvesh if available
            $ejectResult = pvesh set "/nodes/$($vm.node)/qemu/$($vm.vmid)/config" -ide2 "none,media=cdrom" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ ISO ejected successfully via pvesh" -ForegroundColor Green
                return $true
            }
        } catch {
            # pvesh not available, continue
        }
        
        # Method 2: Try with qm if available  
        try {
            $qmResult = qm set $($vm.vmid) -ide2 "none,media=cdrom" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ ISO ejected successfully via qm" -ForegroundColor Green
                return $true
            }
        } catch {
            # qm not available
        }
        
        Write-Host "  ⚠ Could not eject ISO automatically (pvesh/qm not available)" -ForegroundColor Yellow
        Write-Host "  📝 MANUAL ACTION REQUIRED: Eject ISO from VM $($vm.vmid) in Proxmox UI" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "  ⚠ VM info not configured for $NodeIP" -ForegroundColor Yellow
    Write-Host "  📝 MANUAL ACTION: Eject ISO from this VM in Proxmox UI" -ForegroundColor Yellow
    return $false
}

# Function to wait for node
function Wait-ForNode {
    param($NodeIP)
    
    Write-Host "Waiting for $NodeIP to be reachable..." -NoNewline
    $timeout = 300  # 5 minutes
    $elapsed = 0
    
    while ($elapsed -lt $timeout) {
        try {
            $null = talosctl --nodes $NodeIP --endpoints $NodeIP version --insecure 2>$null
            Write-Host " Ready!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 5
            $elapsed += 5
        }
    }
    
    Write-Host " Timeout!" -ForegroundColor Red
    return $false
}

# Pre-flight check: Ensure configurations exist
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$requiredFiles = @(
    "talos\controlplane-base.yaml",
    "talos\worker-base.yaml",
    "talos\patches\common.yaml",
    "talos\patches\controlplane.yaml"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Error "Required file not found: $file"
        Write-Host "Please run .\scripts\generate-configs.ps1 first" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✓ All required files found" -ForegroundColor Green

# Important warning about ISO ejection
Write-Host "`n⚠️  IMPORTANT REMINDER ⚠️" -ForegroundColor Yellow
Write-Host "After applying configurations, nodes will reboot automatically." -ForegroundColor Yellow
Write-Host "The script will attempt to eject ISOs automatically, but if that fails:" -ForegroundColor Yellow
Write-Host "1. Manually eject/detach the Talos ISO from each VM in Proxmox" -ForegroundColor Cyan
Write-Host "2. Ensure boot order prioritizes disk over CD-ROM" -ForegroundColor Cyan
Write-Host "3. Let nodes reboot cleanly from disk with applied configurations" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "Continue with configuration application? (y/N)"
if ($continue -notmatch "^[yY]") {
    Write-Host "Operation cancelled by user" -ForegroundColor Yellow
    exit 0
}

# Apply configuration to control plane nodes
Write-Host "`n=== Configuring Control Plane Nodes ===" -ForegroundColor Yellow

for ($i = 0; $i -lt $CPNodes.Count; $i++) {
    $node = $CPNodes[$i]
    $nodeNum = $i + 1
    
    Write-Host "`nConfiguring control plane node $nodeNum ($node)..." -ForegroundColor Cyan
    
    # Create patched config for this specific node
    Write-Host "Creating patched configuration..."
    talosctl machineconfig patch talos\controlplane-base.yaml `
        --patch "@talos\patches\common.yaml" `
        --patch "@talos\patches\controlplane.yaml" `
        --patch "@talos\patches\cp-0${nodeNum}.yaml" `
        --output "talos\controlplane-${nodeNum}.yaml"
    
    # Apply configuration
    Write-Host "Applying configuration to $node..."
    talosctl apply-config --insecure `
        --nodes $node `
        --file "talos\controlplane-${nodeNum}.yaml"
    
    Write-Host "Configuration applied. Node will restart automatically..." -ForegroundColor Yellow
    
    # Attempt to eject ISO
    Remove-ProxmoxISO -NodeIP $node
    
    # Wait for node to restart and come back up
    Write-Host "Waiting for node to restart and apply configuration..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15  # Give time for restart to begin
    
    if (Wait-ForNode -NodeIP $node) {
        Write-Host "✓ Control plane node $nodeNum configured successfully" -ForegroundColor Green
    } else {
        Write-Error "Control plane node $nodeNum failed to come back online"
        Write-Host "Check Proxmox console and ensure:" -ForegroundColor Yellow
        Write-Host "1. ISO is detached" -ForegroundColor Cyan
        Write-Host "2. VM is booting from disk" -ForegroundColor Cyan
        Write-Host "3. Network connectivity is working" -ForegroundColor Cyan
        exit 1
    }
}

# Apply configuration to worker nodes
Write-Host "`n=== Configuring Worker Nodes ===" -ForegroundColor Yellow

for ($i = 0; $i -lt $WorkerNodes.Count; $i++) {
    $node = $WorkerNodes[$i]
    $nodeNum = $i + 1
    
    Write-Host "`nConfiguring worker node $nodeNum ($node)..." -ForegroundColor Cyan
    
    # Create patched config for this specific node
    Write-Host "Creating patched configuration..."
    talosctl machineconfig patch talos\worker-base.yaml `
        --patch "@talos\patches\common.yaml" `
        --patch "@talos\patches\worker.yaml" `
        --patch "@talos\patches\worker-0${nodeNum}.yaml" `
        --output "talos\worker-${nodeNum}.yaml"
    
    # Apply configuration
    Write-Host "Applying configuration to $node..."
    talosctl apply-config --insecure `
        --nodes $node `
        --file "talos\worker-${nodeNum}.yaml"
    
    Write-Host "Configuration applied. Node will restart automatically..." -ForegroundColor Yellow
    
    # Attempt to eject ISO
    Remove-ProxmoxISO -NodeIP $node
    
    # Wait for node to restart and come back up
    Write-Host "Waiting for node to restart and apply configuration..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15  # Give time for restart to begin
    
    if (Wait-ForNode -NodeIP $node) {
        Write-Host "✓ Worker node $nodeNum configured successfully" -ForegroundColor Green
    } else {
        Write-Error "Worker node $nodeNum failed to come back online"
        Write-Host "Check Proxmox console and ensure:" -ForegroundColor Yellow
        Write-Host "1. ISO is detached" -ForegroundColor Cyan
        Write-Host "2. VM is booting from disk" -ForegroundColor Cyan
        Write-Host "3. Network connectivity is working" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host "`n✅ All configurations applied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Important: All nodes should now be booting from disk with Talos configurations applied." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify all nodes are accessible: .\scripts\verify-access.ps1" -ForegroundColor Cyan
Write-Host "2. Bootstrap the cluster: .\scripts\bootstrap-cluster.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "If any node failed to come back online:" -ForegroundColor Yellow
Write-Host "- Check Proxmox console for boot issues" -ForegroundColor Gray
Write-Host "- Ensure ISO is detached and boot order is correct" -ForegroundColor Gray
Write-Host "- Verify network connectivity" -ForegroundColor Gray
