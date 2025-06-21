# Apply Talos configurations to nodes - Windows version
$ErrorActionPreference = "Stop"

Write-Host "=== Applying Talos Configurations ===" -ForegroundColor Green

# Control plane nodes
$CPNodes = @(
    "192.168.1.241",
    "192.168.1.242",
    "192.168.1.243"
)

# Worker nodes
$WorkerNodes = @(
    "192.168.1.244",
    "192.168.1.245"
)

# Function to wait for node
function Wait-ForNode {
    param($NodeIP)
    
    Write-Host "Waiting for $NodeIP to be reachable..." -NoNewline
    while ($true) {
        try {
            $null = talosctl --nodes $NodeIP --endpoints $NodeIP version --insecure 2>$null
            Write-Host " Ready!" -ForegroundColor Green
            break
        } catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 5
        }
    }
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
    
    # Wait for node to come up
    Wait-ForNode -NodeIP $node
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
    
    # Wait for node to come up
    Wait-ForNode -NodeIP $node
}

Write-Host "`nAll configurations applied!" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Bootstrap the cluster" -ForegroundColor Yellow
Write-Host "Run: talosctl bootstrap --nodes $($CPNodes[0]) --endpoints $($CPNodes[0])" -ForegroundColor Cyan