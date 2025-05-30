<#
.SYNOPSIS
    Generates ImmutableID from AD user's ObjectGUID.
    Output can be used for Entra ID hard match.
.NOTES
    Run on domain-joined system with ActiveDirectory module.
#>

Clear-Host
Import-Module ActiveDirectory -ErrorAction Stop

$UserSamAccount = Read-Host "Enter AD SamAccountName"
$ADUser = Get-ADUser -Identity $UserSamAccount -Properties ObjectGUID

if (-not $ADUser.ObjectGUID) {
    Write-Error "❌ AD user does not have an ObjectGUID. Cannot continue."
    exit
}

$ImmutableID = [System.Convert]::ToBase64String(([GUID]($ADUser.ObjectGUID)).ToByteArray())
Write-Host "`n✅ ImmutableID for '$UserSamAccount': $ImmutableID" -ForegroundColor Cyan