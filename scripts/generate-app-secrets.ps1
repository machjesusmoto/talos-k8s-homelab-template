# Script to generate application secrets from configurations.yaml
param()

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigFile = Join-Path $ProjectRoot "configurations.yaml"

# Check if configurations.yaml exists
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Error: configurations.yaml not found!" -ForegroundColor Red
    Write-Host "Please copy configurations.yaml.example to configurations.yaml and fill in your values"
    exit 1
}

Write-Host "Generating application secrets from configurations.yaml..." -ForegroundColor Green

# Install yq if not present
if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
    Write-Host "Installing yq for YAML parsing..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/mikefarah/yq/releases/latest/download/yq_windows_amd64.exe" -OutFile "$env:TEMP\yq.exe"
    $env:PATH += ";$env:TEMP"
}

# Function to extract value from YAML
function Get-ConfigValue {
    param(
        [string]$Key,
        [string]$Default = ""
    )
    
    try {
        $value = & yq eval ".$Key" $ConfigFile 2>$null
        if ([string]::IsNullOrEmpty($value) -or $value -eq "null") {
            return $Default
        }
        return $value
    } catch {
        return $Default
    }
}

# Function to check required values
function Test-RequiredValue {
    param(
        [string]$Key,
        [string]$Value
    )
    
    if ([string]::IsNullOrEmpty($Value) -or 
        $Value -eq "null" -or 
        $Value -match "REQUIRED" -or 
        $Value -match "^your-") {
        Write-Host "Error: Required configuration missing: $Key" -ForegroundColor Red
        Write-Host "Please update configurations.yaml with your actual values"
        exit 1
    }
}

# 1. Generate Cloudflare DNS secret
Write-Host "Generating Cloudflare DNS secret..." -ForegroundColor Yellow
$CloudflareEmail = Get-ConfigValue "cloudflare.email"
$CloudflareToken = Get-ConfigValue "cloudflare.api_token"
Test-RequiredValue "cloudflare.api_token" $CloudflareToken

@"
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: "$CloudflareToken"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\core\cert-manager\cloudflare-secret.yaml" -Encoding UTF8

# 2. Generate Gluetun VPN secret
Write-Host "Generating Gluetun VPN secret..." -ForegroundColor Yellow
$VpnProvider = Get-ConfigValue "vpn.provider"
$VpnUsername = Get-ConfigValue "vpn.username"
$VpnPassword = Get-ConfigValue "vpn.password"
$VpnRegions = Get-ConfigValue "vpn.server_regions" "Netherlands"
Test-RequiredValue "vpn.username" $VpnUsername
Test-RequiredValue "vpn.password" $VpnPassword

@"
apiVersion: v1
kind: Secret
metadata:
  name: gluetun-vpn-secret
  namespace: gluetun
type: Opaque
stringData:
  VPN_SERVICE_PROVIDER: "$VpnProvider"
  VPN_TYPE: "openvpn"
  OPENVPN_USER: "$VpnUsername"
  OPENVPN_PASSWORD: "$VpnPassword"
  SERVER_REGIONS: "$VpnRegions"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\apps\gluetun\vpn-secret.yaml" -Encoding UTF8

# 3. Generate Paperless-ngx secrets
Write-Host "Generating Paperless-ngx secrets..." -ForegroundColor Yellow
$PaperlessAdminPassword = Get-ConfigValue "paperless.admin_password" "changeme123!"
$PaperlessSecretKey = Get-ConfigValue "paperless.secret_key"
if ([string]::IsNullOrEmpty($PaperlessSecretKey) -or $PaperlessSecretKey -match "change-this") {
    # Generate random secret key
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
    $PaperlessSecretKey = [Convert]::ToBase64String($bytes)
}
$PaperlessPostgresPassword = Get-ConfigValue "paperless.postgres_password" "paperless-db-password"
$DomainEmail = Get-ConfigValue "domain.email" "admin@example.com"

@"
apiVersion: v1
kind: Secret
metadata:
  name: paperless-secrets
  namespace: paperless
type: Opaque
stringData:
  POSTGRES_DB: "paperless"
  POSTGRES_USER: "paperless"
  POSTGRES_PASSWORD: "$PaperlessPostgresPassword"
  PAPERLESS_SECRET_KEY: "$PaperlessSecretKey"
  PAPERLESS_ADMIN_USER: "admin"
  PAPERLESS_ADMIN_PASSWORD: "$PaperlessAdminPassword"
  PAPERLESS_ADMIN_MAIL: "$DomainEmail"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\apps\paperless-ngx\paperless-secrets.yaml" -Encoding UTF8

# 4. Generate Notifiarr secret
Write-Host "Generating Notifiarr secret..." -ForegroundColor Yellow
$NotifiarrApiKey = Get-ConfigValue "notifications.notifiarr.api_key"
$DiscordWebhook = Get-ConfigValue "notifications.discord.webhook_url"

if (-not [string]::IsNullOrEmpty($NotifiarrApiKey) -and $NotifiarrApiKey -ne "null") {
@"
apiVersion: v1
kind: Secret
metadata:
  name: notifiarr-secrets
  namespace: notifications
type: Opaque
stringData:
  DN_API_KEY: "$NotifiarrApiKey"
  DN_DISCORD_WEBHOOK: "$DiscordWebhook"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\apps\notifiarr\notifiarr-secret.yaml" -Encoding UTF8
}

# 5. Generate download client secrets
Write-Host "Generating download client secrets..." -ForegroundColor Yellow
$QbittorrentPassword = Get-ConfigValue "downloads.qbittorrent.admin_password" "changeme123!"
$NzbgetPassword = Get-ConfigValue "downloads.nzbget.admin_password" "changeme123!"

@"
apiVersion: v1
kind: Secret
metadata:
  name: qbittorrent-secrets
  namespace: downloads
type: Opaque
stringData:
  ADMIN_PASSWORD: "$QbittorrentPassword"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\apps\download-clients\qbittorrent-secret.yaml" -Encoding UTF8

@"
apiVersion: v1
kind: Secret
metadata:
  name: nzbget-secrets
  namespace: downloads
type: Opaque
stringData:
  ADMIN_PASSWORD: "$NzbgetPassword"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\apps\download-clients\nzbget-secret.yaml" -Encoding UTF8

# 6. Generate Grafana secret
Write-Host "Generating Grafana secret..." -ForegroundColor Yellow
$GrafanaPassword = Get-ConfigValue "monitoring.grafana.admin_password" "changeme123!"

@"
apiVersion: v1
kind: Secret
metadata:
  name: grafana-secrets
  namespace: monitoring
type: Opaque
stringData:
  admin-password: "$GrafanaPassword"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\apps\monitoring\grafana-secret.yaml" -Encoding UTF8

# 7. Generate ArgoCD admin password secret
Write-Host "Generating ArgoCD password secret..." -ForegroundColor Yellow
$ArgoCDPassword = Get-ConfigValue "argocd.admin_password" "changeme123!"

@"
apiVersion: v1
kind: Secret
metadata:
  name: argocd-admin-password
  namespace: argocd
type: Opaque
stringData:
  password: "$ArgoCDPassword"
"@ | Out-File -FilePath "$ProjectRoot\kubernetes\gitops\argocd\argocd-secret.yaml" -Encoding UTF8

# Update .gitignore to exclude generated secrets
Write-Host "Updating .gitignore..." -ForegroundColor Yellow
$gitignoreContent = @"

# Generated application secrets
kubernetes/core/cert-manager/cloudflare-secret.yaml
kubernetes/apps/gluetun/vpn-secret.yaml
kubernetes/apps/paperless-ngx/paperless-secrets.yaml
kubernetes/apps/notifiarr/notifiarr-secret.yaml
kubernetes/apps/download-clients/qbittorrent-secret.yaml
kubernetes/apps/download-clients/nzbget-secret.yaml
kubernetes/apps/monitoring/grafana-secret.yaml
kubernetes/gitops/argocd/argocd-secret.yaml
"@

Add-Content -Path "$ProjectRoot\.gitignore" -Value $gitignoreContent

Write-Host "Secret generation complete!" -ForegroundColor Green
Write-Host "Generated secrets have been added to .gitignore" -ForegroundColor Yellow
Write-Host "Apply secrets with: kubectl apply -f <secret-file>" -ForegroundColor Yellow