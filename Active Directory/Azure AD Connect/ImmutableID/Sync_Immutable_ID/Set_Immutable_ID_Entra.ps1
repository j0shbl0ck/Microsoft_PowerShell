<#
.SYNOPSIS
    Sets an Entra ID user's ImmutableID using Microsoft Graph.
.NOTES
    Requires Microsoft.Graph PowerShell module.
#>

Clear-Host
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "User.ReadWrite.All" | Out-Null

$UserUPN = Read-Host "Enter the UPN of the Entra ID user"
$ImmutableID = Read-Host "Paste the ImmutableID to assign"

# View current value
$current = Get-MgUser -UserId $UserUPN -Property OnPremisesImmutableId
Write-Host "`nCurrent ImmutableID: $($current.OnPremisesImmutableId)" -ForegroundColor Yellow

# Confirm and update
$confirm = Read-Host "Do you want to update this user's ImmutableID to the new value? (Y/N)"
if ($confirm -eq 'Y') {
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$UserUPN" -Body @{OnPremisesImmutableId = $ImmutableID}
    Write-Host "✅ ImmutableID updated successfully." -ForegroundColor Green
} else {
    Write-Host "❌ Operation cancelled." -ForegroundColor DarkYellow
}

Disconnect-MgGraph