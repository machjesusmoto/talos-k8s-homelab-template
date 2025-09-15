# Shared configuration reader library for PowerShell scripts
# Dot-source this file to read values from configurations.yaml

# Initialize configuration
function Initialize-Config {
    # Get the project root directory
    $script:ScriptPath = $MyInvocation.PSCommandPath
    $script:ScriptDir = Split-Path -Parent $script:ScriptPath
    $script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $script:ScriptDir)
    $script:ConfigFile = Join-Path $script:ProjectRoot "configurations.yaml"
    
    # Check if configurations.yaml exists
    if (-not (Test-Path $script:ConfigFile)) {
        Write-Error "configurations.yaml not found at $script:ConfigFile"
        Write-Error "Please create it from configurations.yaml.template"
        exit 1
    }
    
    # Install powershell-yaml module if not available
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Host "Installing powershell-yaml module..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }
    
    Import-Module powershell-yaml
    
    # Load the configuration
    $script:Config = Get-Content $script:ConfigFile -Raw | ConvertFrom-Yaml
}

# Read a value from config with dot notation
function Get-ConfigValue {
    param(
        [string]$Path,
        $Default = $null
    )
    
    $segments = $Path -split '\.'
    $current = $script:Config
    
    foreach ($segment in $segments) {
        # Handle array index notation like [0]
        if ($segment -match '^\[(\d+)\]$') {
            $index = [int]$matches[1]
            if ($current -is [System.Collections.IList] -and $index -lt $current.Count) {
                $current = $current[$index]
            } else {
                return $Default
            }
        }
        # Handle regular property
        elseif ($current -is [System.Collections.IDictionary] -and $current.ContainsKey($segment)) {
            $current = $current[$segment]
        }
        else {
            return $Default
        }
    }
    
    if ($null -eq $current) {
        return $Default
    }
    
    return $current
}

# Get an array from config
function Get-ConfigArray {
    param(
        [string]$Path
    )
    
    $value = Get-ConfigValue -Path $Path -Default @()
    if ($value -is [System.Collections.IList]) {
        return $value
    }
    return @()
}

# Check if a config value exists
function Test-ConfigValue {
    param(
        [string]$Path
    )
    
    $value = Get-ConfigValue -Path $Path
    return ($null -ne $value -and $value -ne "")
}

# Load common configuration values
function Get-CommonConfig {
    # Create a hashtable with all common values
    @{
        # Cluster configuration
        ClusterName = Get-ConfigValue -Path 'cluster.name' -Default 'homelab'
        ClusterVIP = Get-ConfigValue -Path 'network.cluster_vip' -Default '192.168.1.240'
        KubernetesApiPort = Get-ConfigValue -Path 'cluster.kubernetes_api_port' -Default '6443'
        TalosApiPort = Get-ConfigValue -Path 'cluster.talos_api_port' -Default '50000'
        TalosVersion = Get-ConfigValue -Path 'cluster.talos_version' -Default 'v1.7.5'
        Architecture = Get-ConfigValue -Path 'cluster.architecture' -Default 'amd64'
        
        # Domain configuration
        BaseDomain = Get-ConfigValue -Path 'domain.base' -Default 'k8s.example.com'
        AdminEmail = Get-ConfigValue -Path 'domain.email' -Default 'admin@example.com'
        
        # Network configuration
        MetalLBRange = Get-ConfigValue -Path 'network.metallb_ip_range' -Default '192.168.1.200-192.168.1.239'
        
        # Storage configuration
        NFSServer = Get-ConfigValue -Path 'storage.nfs_server' -Default '192.168.1.10'
        NFSPath = Get-ConfigValue -Path 'storage.nfs_path' -Default '/mnt/storage'
        
        # External services
        TalosFactoryUrl = Get-ConfigValue -Path 'external_services.talos_factory_url' -Default 'https://factory.talos.dev'
    }
}

# Get all control plane nodes
function Get-ControlPlaneNodes {
    $nodes = Get-ConfigArray -Path 'cluster.control_planes'
    return $nodes
}

# Get all worker nodes
function Get-WorkerNodes {
    $nodes = Get-ConfigArray -Path 'cluster.workers'
    return $nodes
}

# Get all control plane IPs
function Get-ControlPlaneIPs {
    $nodes = Get-ControlPlaneNodes
    return $nodes | ForEach-Object { $_.ip }
}

# Get all worker IPs
function Get-WorkerIPs {
    $nodes = Get-WorkerNodes
    return $nodes | ForEach-Object { $_.ip }
}

# Get all node IPs
function Get-AllNodeIPs {
    $cpIPs = Get-ControlPlaneIPs
    $workerIPs = Get-WorkerIPs
    return @($cpIPs) + @($workerIPs)
}

# Get node hostname by IP
function Get-NodeHostname {
    param(
        [string]$IP
    )
    
    # Check control planes
    $cpNodes = Get-ControlPlaneNodes
    foreach ($node in $cpNodes) {
        if ($node.ip -eq $IP) {
            return $node.hostname
        }
    }
    
    # Check workers
    $workerNodes = Get-WorkerNodes
    foreach ($node in $workerNodes) {
        if ($node.ip -eq $IP) {
            return $node.hostname
        }
    }
    
    return "unknown"
}

# Get Proxmox VM ID for a node IP
function Get-ProxmoxVMID {
    param(
        [string]$IP
    )
    
    if (Test-ConfigValue -Path 'proxmox.enabled') {
        $enabled = Get-ConfigValue -Path 'proxmox.enabled'
        if ($enabled -eq $true) {
            return Get-ConfigValue -Path "proxmox.vm_mappings.$IP"
        }
    }
    
    return $null
}

# Initialize when dot-sourced
Initialize-Config

# Export common config as global variable for easy access
$global:HomeLabConfig = Get-CommonConfig