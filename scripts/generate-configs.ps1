# Generate Talos configuration files - Windows version
param()

$ErrorActionPreference = "Stop"

# Load configuration library
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\lib\Config-Reader.ps1"

Write-Host "=== Talos Configuration Generator ===" -ForegroundColor Green
Write-Host "Using configurations from: $script:ConfigFile" -ForegroundColor Cyan

# Display configuration values
Write-Host "`nCluster configuration:" -ForegroundColor Yellow
Write-Host "  Name: $($global:HomeLabConfig.ClusterName)"
Write-Host "  VIP: $($global:HomeLabConfig.ClusterVIP)"
Write-Host "  Domain: $($global:HomeLabConfig.BaseDomain)"
Write-Host "  Talos Version: $($global:HomeLabConfig.TalosVersion)"

# Check if talosctl is available
try {
    $null = talosctl version --client
} catch {
    Write-Error "talosctl not found. Please install talosctl and add it to PATH"
    exit 1
}

# Check if secrets exist
$secretsFile = "secrets.yaml"
if (-not (Test-Path $secretsFile)) {
    Write-Host "Generating cluster secrets..." -ForegroundColor Yellow
    talosctl gen secrets -o $secretsFile
    Write-Host "IMPORTANT: Back up secrets.yaml securely!" -ForegroundColor Red
} else {
    Write-Host "Using existing secrets.yaml" -ForegroundColor Cyan
}

# Create talos directory if it doesn't exist
if (-not (Test-Path "talos")) {
    New-Item -ItemType Directory -Path "talos" | Out-Null
}

# Build cluster endpoint from configuration
$ClusterEndpoint = "https://$($global:HomeLabConfig.ClusterVIP):$($global:HomeLabConfig.KubernetesApiPort)"

Write-Host "`nGenerating configurations for endpoint: $ClusterEndpoint" -ForegroundColor Yellow

# Generate base configs
Write-Host "`nGenerating base configurations..." -ForegroundColor Yellow

# Control plane config
talosctl gen config $global:HomeLabConfig.ClusterName $ClusterEndpoint `
    --with-secrets $secretsFile `
    --output-types controlplane `
    --output talos\controlplane-base.yaml

# Worker config
talosctl gen config $global:HomeLabConfig.ClusterName $ClusterEndpoint `
    --with-secrets $secretsFile `
    --output-types worker `
    --output talos\worker-base.yaml

# Talosconfig for kubectl
talosctl gen config $global:HomeLabConfig.ClusterName $ClusterEndpoint `
    --with-secrets $secretsFile `
    --output-types talosconfig `
    --output talos\talosconfig

# Display node configuration
Write-Host "`nNode configuration from configurations.yaml:" -ForegroundColor Cyan
Write-Host "Control Plane Nodes:" -ForegroundColor Yellow
$cpNodes = Get-ControlPlaneNodes
foreach ($node in $cpNodes) {
    Write-Host "  - $($node.hostname): $($node.ip)"
}

Write-Host "Worker Nodes:" -ForegroundColor Yellow
$workerNodes = Get-WorkerNodes
foreach ($node in $workerNodes) {
    Write-Host "  - $($node.hostname): $($node.ip)"
}

Write-Host "`nBase configurations generated!" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  - secrets.yaml (KEEP THIS SECURE!)"
Write-Host "  - talos\controlplane-base.yaml"
Write-Host "  - talos\worker-base.yaml"
Write-Host "  - talos\talosconfig"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the generated configurations"
Write-Host "2. Run .\scripts\apply-configs.ps1 to apply to nodes"