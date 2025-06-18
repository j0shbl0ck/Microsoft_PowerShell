<#
.SYNOPSIS
    This script finds the user in Azure AD based on the Immutable ID (Source Anchor).
.NOTES
    Author: Josh Block
    Date: 05.30.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
#>

# Check for Microsoft.Graph module
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "❌ Microsoft.Graph module is not installed. Please install it using:"
    Write-Host "`n    Install-Module Microsoft.Graph -Scope CurrentUser`n" -ForegroundColor Red
    exit 1
}

# Prompt for input
$inputId = Read-Host "Enter the Immutable ID (Source Anchor)"

# Determine if input is a GUID or base64
if ($inputId -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
    try {
        $guid = [Guid]::Parse($inputId)
        $immutableId = [Convert]::ToBase64String($guid.ToByteArray())
        Write-Host "🔄 Converted GUID to Immutable ID: $immutableId" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Invalid GUID format." -ForegroundColor Red
        exit 1
    }
} else {
    $immutableId = $inputId
}

# Connect to Microsoft Graph
Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "User.ReadWrite.All" | Out-Null

# Perform query
Write-Host "🔎 Searching for user with Immutable ID: $immutableId" -ForegroundColor Yellow
try {
    $user = Get-MgUser -Filter "onPremisesImmutableId eq '$immutableId'" -ErrorAction Stop
    if ($user) {
        Write-Host "`n✅ User found:`n" -ForegroundColor Green
        $user | Format-List DisplayName, UserPrincipalName, Id, OnPremisesImmutableId
    } else {
        Write-Host "❌ No user found with that Immutable ID." -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error querying Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}
