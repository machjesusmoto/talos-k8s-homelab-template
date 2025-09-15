#!/bin/bash
# Build custom Talos image using Image Factory

set -e

echo "=== Talos Image Factory Builder ==="

# Configuration
FACTORY_URL="https://factory.talos.dev"
TALOS_VERSION="${TALOS_VERSION:-v1.7.5}"  # Default to latest stable
ARCH="${ARCH:-amd64}"

# Check if schematic file exists
if [ ! -f "talos/schematic.yaml" ]; then
    echo "Error: talos/schematic.yaml not found!"
    exit 1
fi

echo "Building Talos image with:"
echo "  Version: $TALOS_VERSION"
echo "  Architecture: $ARCH"
echo ""

# Upload schematic to factory
echo "Uploading schematic to Image Factory..."
SCHEMATIC_ID=$(curl -s -X POST \
    -H "Content-Type: application/yaml" \
    --data-binary @talos/schematic.yaml \
    "${FACTORY_URL}/schematics" | jq -r '.id')

if [ -z "$SCHEMATIC_ID" ]; then
    echo "Error: Failed to upload schematic"
    exit 1
fi

echo "Schematic ID: $SCHEMATIC_ID"
echo ""

# Save schematic ID for future reference
echo "$SCHEMATIC_ID" > talos/schematic.id

# Generate download URLs
ISO_URL="${FACTORY_URL}/image/${SCHEMATIC_ID}/${TALOS_VERSION}/metal-${ARCH}.iso"
INSTALLER_URL="${FACTORY_URL}/image/${SCHEMATIC_ID}/${TALOS_VERSION}/installer-${ARCH}.tar"

echo "Download URLs:"
echo "  ISO: $ISO_URL"
echo "  Installer: $INSTALLER_URL"
echo ""

echo "To download the ISO directly:"
echo "  curl -LO $ISO_URL"
echo ""

echo "Or use wget:"
echo "  wget $ISO_URL"
echo ""

echo "The ISO includes:"
echo "  - QEMU Guest Agent for Proxmox integration"
echo "  - CPU microcode updates"
echo "  - Serial console support"
echo ""

echo "Next steps:"
echo "1. Download the ISO"
echo "2. Upload to Proxmox ISO storage"
echo "3. Create VMs using this ISO"
