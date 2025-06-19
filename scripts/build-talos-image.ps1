# Build custom Talos image using Image Factory
# PowerShell version for Windows

$ErrorActionPreference = "Stop"

Write-Host "=== Talos Image Factory Builder ===" -ForegroundColor Green

# Configuration
$FACTORY_URL = "https://factory.talos.dev"
$TALOS_VERSION = if ($env:TALOS_VERSION) { $env:TALOS_VERSION } else { "v1.7.5" }
$ARCH = if ($env:ARCH) { $env:ARCH } else { "amd64" }

# Check if schematic file exists
if (-not (Test-Path "talos\schematic.yaml")) {
    Write-Error "Error: talos\schematic.yaml not found!"
    exit 1
}

Write-Host "Building Talos image with:"
Write-Host "  Version: $TALOS_VERSION"
Write-Host "  Architecture: $ARCH"
Write-Host ""

# Read schematic file
$schematicContent = Get-Content -Path "talos\schematic.yaml" -Raw

# Upload schematic to factory
Write-Host "Uploading schematic to Image Factory..." -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$FACTORY_URL/schematics" `
    -Method Post `
    -ContentType "application/yaml" `
    -Body $schematicContent

$SCHEMATIC_ID = $response.id

if (-not $SCHEMATIC_ID) {
    Write-Error "Error: Failed to upload schematic"
    exit 1
}

Write-Host "Schematic ID: $SCHEMATIC_ID" -ForegroundColor Cyan
Write-Host ""

# Save schematic ID for future reference
$SCHEMATIC_ID | Out-File -FilePath "talos\schematic.id" -NoNewline

# Generate download URLs
$ISO_URL = "$FACTORY_URL/image/$SCHEMATIC_ID/$TALOS_VERSION/metal-$ARCH.iso"
$INSTALLER_URL = "$FACTORY_URL/image/$SCHEMATIC_ID/$TALOS_VERSION/installer-$ARCH.tar"

Write-Host "Download URLs:" -ForegroundColor Green
Write-Host "  ISO: $ISO_URL"
Write-Host "  Installer: $INSTALLER_URL"
Write-Host ""

Write-Host "To download the ISO:" -ForegroundColor Yellow
Write-Host "  Invoke-WebRequest -Uri '$ISO_URL' -OutFile 'talos-custom.iso'"
Write-Host ""

Write-Host "Or use curl:"
Write-Host "  curl -LO $ISO_URL"
Write-Host ""

Write-Host "The ISO includes:" -ForegroundColor Green
Write-Host "  - QEMU Guest Agent for Proxmox integration"
Write-Host "  - CPU microcode updates"
Write-Host "  - Serial console support"
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Download the ISO"
Write-Host "2. Upload to Proxmox ISO storage"
Write-Host "3. Create VMs using this ISO"

# Optionally download the ISO
$download = Read-Host "Download ISO now? (y/n)"
if ($download -eq 'y') {
    Write-Host "Downloading ISO..." -ForegroundColor Yellow
    $outputFile = "talos-$TALOS_VERSION-proxmox.iso"
    Invoke-WebRequest -Uri $ISO_URL -OutFile $outputFile
    Write-Host "ISO downloaded to: $outputFile" -ForegroundColor Green
}
