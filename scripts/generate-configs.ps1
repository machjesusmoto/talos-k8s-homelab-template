# Generate Talos configuration files - Windows version
param(
    [string]$ClusterName = "homelab",
    [string]$ClusterEndpoint = "192.168.1.240"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Talos Configuration Generator ===" -ForegroundColor Green

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

Write-Host "`nGenerating configurations for:" -ForegroundColor Yellow
Write-Host "  Cluster Name: $ClusterName"
Write-Host "  Cluster Endpoint: https://${ClusterEndpoint}:6443"

# Generate base configs
Write-Host "`nGenerating base configurations..." -ForegroundColor Yellow

# Control plane config
talosctl gen config $ClusterName "https://${ClusterEndpoint}:6443" `
    --with-secrets $secretsFile `
    --output-types controlplane `
    --output talos\controlplane-base.yaml

# Worker config
talosctl gen config $ClusterName "https://${ClusterEndpoint}:6443" `
    --with-secrets $secretsFile `
    --output-types worker `
    --output talos\worker-base.yaml

# Talosconfig for kubectl
talosctl gen config $ClusterName "https://${ClusterEndpoint}:6443" `
    --with-secrets $secretsFile `
    --output-types talosconfig `
    --output talos\talosconfig

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