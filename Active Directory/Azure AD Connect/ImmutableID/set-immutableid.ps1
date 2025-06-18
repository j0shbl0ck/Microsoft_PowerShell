<#
.SYNOPSIS
    Sets an Entra ID user's ImmutableID using Microsoft Graph with scoped error handling.
.NOTES
    Requires Microsoft.Graph PowerShell module.
#>

Clear-Host
Disconnect-MgGraph -ErrorAction SilentlyContinue

try {
    Connect-MgGraph -Scopes "User.ReadWrite.All" | Out-Null
} catch {
    Write-Error "❌ Could not connect to Microsoft Graph. Ensure required modules and permissions are available."
    exit
}

$UserUPN = Read-Host "Enter the UPN of the Entra ID user"
$ImmutableID = Read-Host "Paste the ImmutableID to assign"

try {
    $current = Get-MgUser -UserId $UserUPN -Property OnPremisesImmutableId
    Write-Host "`nCurrent ImmutableID for '$UserUPN': $($current.OnPremisesImmutableId)" -ForegroundColor Yellow
} catch {
    Write-Error "❌ Failed to retrieve the user. Error: $($_.Exception.Message)"
    Disconnect-MgGraph
    exit
}

$confirm = Read-Host "Do you want to update this user's ImmutableID to the new value? (Y/N)"
if ($confirm -ne 'Y') {
    Write-Host "❌ Operation cancelled." -ForegroundColor DarkYellow
    Disconnect-MgGraph
    exit
}

try {
    # Send as JSON object, not hashtable
    $jsonBody = @{ onPremisesImmutableId = $ImmutableID } | ConvertTo-Json -Depth 3
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$UserUPN" -Body $jsonBody -ContentType "application/json"
    Write-Host "✅ ImmutableID updated successfully for '$UserUPN'." -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to update ImmutableID."
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
}

Disconnect-MgGraph | Out-Null
