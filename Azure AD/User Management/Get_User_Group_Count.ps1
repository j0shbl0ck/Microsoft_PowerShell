<#
.SYNOPSIS
    This script pulls information how many users are currently licensed and how many groups (M365,shared,Distri,Mail-Enab) are active. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.5
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
Connect-ExchangeOnline
Clear-Host

## Get number of licensed users
function getLicensedUsers {
    Write-Host -ForegroundColor Yellow "Finding licensed users..."
    Get-MgUser -Filter 'assignedLicenses/$count ne 0' -ConsistencyLevel eventual -CountVariable licensedUserCount -All -Select UserPrincipalName,DisplayName,AssignedLicenses | Format-Table -Property UserPrincipalName,DisplayName,AssignedLicenses
    #Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
    Write-Host -ForegroundColor Green "Found $licensedUserCount licensed users.`n" 
}

function getM365Groups {
    Write-Host -ForegroundColor Yellow "Finding M365 groups..."
    $m365GroupCount = (Get-UnifiedGroup).Count
    Get-UnifiedGroup | Format-List DisplayName,EmailAddresses
    Write-Host -ForegroundColor Green "Found $m365GroupCount M365 groups.`n" 
}

function getDistriLists {
    Write-Host -ForegroundColor Yellow "Finding distribution lists..."
    $distriListCount = (Get-DistributionGroup).Count
    Get-DistributionGroup | Format-List DisplayName,EmailAddresses
    Write-Host -ForegroundColor Green "Found $distriListCount distribution lists.`n" 
}

function getSharedMail {
    Write-Host -ForegroundColor Yellow "Finding shared mailboxes..."
    $sharedMailCount = (Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited).Count
    Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName
    Write-Host -ForegroundColor Green "Found $sharedMailCount shared mailboxes.`n" 
}


# run functions
getLicensedUsers
getM365Groups
getDistriLists
getSharedMail


<# ## Export results to TXT file
Write-Host -ForegroundColor Yellow "Exporting results to file..."
$desktop = [Environment]::GetFolderPath("Desktop")
$licensedUsersExport = $desktop + "\licensedUsers.txt"
getM365Groups | Out-File $licensedUsersExport
Write-Host "Report is in $licensedUsersExport" #>
