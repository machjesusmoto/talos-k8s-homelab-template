# Script to fix current deployment issues
param()

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Fixing deployment issues..." -ForegroundColor Green

# 1. Fix namespace security labels for LinuxServer containers
Write-Host "1. Applying privileged security labels to namespaces..." -ForegroundColor Yellow
$namespaces = @("media", "downloads", "automation", "household", "gluetun", "notifiarr")
foreach ($ns in $namespaces) {
    try {
        kubectl get namespace $ns | Out-Null
        Write-Host "Labeling namespace: $ns"
        kubectl label namespace $ns `
            pod-security.kubernetes.io/enforce=privileged `
            pod-security.kubernetes.io/warn=privileged `
            pod-security.kubernetes.io/audit=privileged `
            --overwrite
    } catch {
        # Namespace doesn't exist, skip
    }
}

# 2. Fix DNS propagation issue by forcing cert-manager to retry
Write-Host "2. Restarting cert-manager to force DNS propagation check..." -ForegroundColor Yellow
kubectl rollout restart deployment cert-manager -n cert-manager
kubectl rollout restart deployment cert-manager-webhook -n cert-manager

# Wait for rollout
Write-Host "Waiting for cert-manager restart..."
kubectl rollout status deployment cert-manager -n cert-manager --timeout=300s
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s

# 3. Fix Paperless-ngx by switching to non-root container
Write-Host "3. Fixing Paperless-ngx deployment..." -ForegroundColor Yellow
@'
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: paperless
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          runAsGroup: 1000
          capabilities:
            drop:
            - ALL
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
'@ | Out-File -FilePath "$env:TEMP\paperless-patch.yaml" -Encoding UTF8

kubectl patch deployment paperless-ngx -n paperless --patch-file="$env:TEMP\paperless-patch.yaml"

# 4. Apply missing secrets if configurations.yaml exists
$ConfigFile = Join-Path $ProjectRoot "configurations.yaml"
if (Test-Path $ConfigFile) {
    Write-Host "4. Generating and applying secrets from configurations.yaml..." -ForegroundColor Yellow
    
    # Generate secrets
    & "$ProjectRoot\scripts\generate-app-secrets.ps1"
    
    # Apply generated secrets
    Write-Host "Applying generated secrets..."
    $secretFiles = @(
        "$ProjectRoot\kubernetes\core\cert-manager\cloudflare-secret.yaml",
        "$ProjectRoot\kubernetes\apps\gluetun\vpn-secret.yaml",
        "$ProjectRoot\kubernetes\apps\paperless-ngx\paperless-secrets.yaml"
    )
    
    foreach ($file in $secretFiles) {
        if (Test-Path $file) {
            kubectl apply -f $file
        }
    }
} else {
    Write-Host "Warning: configurations.yaml not found. Skipping secret generation." -ForegroundColor Red
    Write-Host "Please create configurations.yaml from the template and run this script again."
}

# 5. Force ArgoCD sync for OutOfSync applications
Write-Host "5. Syncing OutOfSync ArgoCD applications..." -ForegroundColor Yellow
$apps = @("code-server", "core-infrastructure", "download-clients", "media-management")
foreach ($app in $apps) {
    Write-Host "Syncing $app..."
    try {
        kubectl patch application $app -n argocd `
            -p '{"operation":{"sync":{"prune":true,"selfHeal":true}}}' `
            --type=merge
    } catch {
        Write-Host "Warning: Failed to sync $app" -ForegroundColor Yellow
    }
}

# 6. Delete stuck challenges to force recreation
Write-Host "6. Cleaning up stuck certificate challenges..." -ForegroundColor Yellow
$challenges = kubectl get challenges -A -o json | ConvertFrom-Json
$oneHourAgo = (Get-Date).AddHours(-1)

foreach ($challenge in $challenges.items) {
    $creationTime = [DateTime]::Parse($challenge.metadata.creationTimestamp)
    if ($creationTime -lt $oneHourAgo) {
        $ns = $challenge.metadata.namespace
        $name = $challenge.metadata.name
        Write-Host "Deleting old challenge: $ns/$name"
        kubectl delete challenge -n $ns $name
    }
}

# 7. Restart applications with issues
Write-Host "7. Restarting problematic deployments..." -ForegroundColor Yellow
try { kubectl rollout restart deployment gluetun -n gluetun } catch {}
try { kubectl rollout restart deployment paperless-ngx -n paperless } catch {}

Write-Host "`nFix script complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Monitor certificate challenges: kubectl get challenges -A -w"
Write-Host "2. Check application health: kubectl get pods -A | findstr /V Running"
Write-Host "3. View ArgoCD sync status: kubectl get applications -n argocd"
Write-Host ""
Write-Host "If DNS challenges still fail after 5 minutes:" -ForegroundColor Yellow
Write-Host "- Check Cloudflare DNS panel for _acme-challenge TXT records"
Write-Host "- Verify DNS propagation: nslookup -type=TXT _acme-challenge.homer.k8s.dttesting.com"
Write-Host "- Consider using HTTP-01 challenges instead of DNS-01"