# Create-CommunicationEmailSenderUsername.ps1
# Works in Azure Cloud Shell (PowerShell) and local PowerShell, as long as Azure CLI (az) is installed and logged in.

# --- Check az CLI is available ---
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI (az) not found on PATH. Install it or run this in Azure Cloud Shell."
    exit 1
}

# --- Prompt for values, with defaults ---
$resourceGroup     = Read-Host "Resource Group [rg-c21community-email-prod]"
if ([string]::IsNullOrWhiteSpace($resourceGroup)) { $resourceGroup = "rg-c21community-email-prod" }

$emailServiceName  = Read-Host "Email Service Name [acsem-c21community-prod]"
if ([string]::IsNullOrWhiteSpace($emailServiceName)) { $emailServiceName = "acsem-c21community-prod" }

$domainName        = Read-Host "Domain Name [c21community.com]"
if ([string]::IsNullOrWhiteSpace($domainName)) { $domainName = "c21community.com" }

$senderUsername    = Read-Host "Sender Username (e.g. hpm447fdw)"
if ([string]::IsNullOrWhiteSpace($senderUsername)) {
    Write-Error "Sender Username is required."
    exit 1
}

$displayName       = Read-Host "Display Name (e.g. C21 HP M447FDW)"
if ([string]::IsNullOrWhiteSpace($displayName)) {
    Write-Error "Display Name is required."
    exit 1
}

# --- Confirm before running ---
Write-Host ""
Write-Host "About to run:" -ForegroundColor Cyan
Write-Host "  Resource Group   : $resourceGroup"
Write-Host "  Email Communication Service    : $emailServiceName"
Write-Host "  Domain           : $domainName"
Write-Host "  Sender Username  : $senderUsername"
Write-Host "  Display Name     : $displayName"
Write-Host ""

$confirm = Read-Host "Proceed? (Y/N)"
if ($confirm -notmatch '^[Yy]') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# --- Run the az command ---
az communication email domain sender-username create `
    --domain-name $domainName `
    --email-service-name $emailServiceName `
    -g $resourceGroup `
    --sender-username $senderUsername `
    --username $senderUsername `
    --display-name "$displayName"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sender username created successfully." -ForegroundColor Green
} else {
    Write-Error "az command failed with exit code $LASTEXITCODE."
}