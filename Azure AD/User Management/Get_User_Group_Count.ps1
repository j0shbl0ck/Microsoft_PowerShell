<#
.SYNOPSIS
    This script pulls information how many users are currently licensed and how many groups (M365,shared,Distri,Mail-Enab) are active. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 09.28.22
    Type: Public
.NOTES
    You will need to have Microsoft Graph Module installed.
.LINK
    Source: https://www.tecklyfe.com/get-a-count-of-azure-ad-active-directory-users/
    Source: https://learn.microsoft.com/en-us/microsoft-365/enterprise/view-licensed-and-unlicensed-users-with-microsoft-365-powershell?view=o365-worldwide


#>

## Connect to Microsoft Services
Connect-Graph -Scopes User.Read.All, Organization.Read.All
Connect-AzureAD

Get-MgUser -Filter 'assignedLicenses/$count ne 0' -ConsistencyLevel eventual -CountVariable licensedUserCount -All -Select UserPrincipalName,DisplayName,AssignedLicenses | Format-Table -Property UserPrincipalName,DisplayName,AssignedLicenses

Write-Host "Found $licensedUserCount licensed users."

Get-AzureAdUser | ForEach-Object { $licensed=$False ; For ($i=0; $i -le ($_.AssignedLicenses | Measure-Object).Count ; $i++) { If( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) { $licensed=$true } } ; If( $licensed -eq $true) { Write-Host $_.UserPrincipalName} }
