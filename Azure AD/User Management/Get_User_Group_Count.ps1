<#
.SYNOPSIS
    This script pulls information how many users are currently licensed and how many groups (M365,shared,Distri,Mail-Enab) are active. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.7
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

<# ## Create folder on desktop to store reports
$desktop = [Environment]::GetFolderPath("Desktop")
$folder = $desktop + "\User_Group_Count"
New-Item -ItemType Directory -Path $folder #>


## Get number of licensed users
function getLicensedUsers {
    Write-Host -ForegroundColor Yellow "Finding licensed users..."
    Get-MgUser -Filter 'assignedLicenses/$count ne 0' -ConsistencyLevel eventual -CountVariable licensedUserCount -All -Select UserPrincipalName,DisplayName,AssignedLicenses | Format-Table -Property UserPrincipalName,DisplayName,AssignedLicenses
    #Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
    Write-Host -ForegroundColor Green "Found $licensedUserCount licensed users.`n" 
}

## Get number of M365 groups
function getM365Groups {
    Write-Host -ForegroundColor Yellow "Finding M365 groups..."
    $m365GroupCount = (Get-UnifiedGroup).Count
    Write-Host -ForegroundColor Green "Found $m365GroupCount M365 groups.`n" 
    Get-UnifiedGroup | Format-List DisplayName,EmailAddresses
}

## Get number of distribution lists
function getDistriLists {
    Write-Host -ForegroundColor Yellow "Finding distribution lists..."
    $distriListCount = (Get-DistributionGroup).Count
    Write-Host -ForegroundColor Green "Found $distriListCount distribution lists.`n" 
    Get-DistributionGroup | Format-List DisplayName,EmailAddresses
}

## Get number of shared mailboxes
function getSharedMail {
    Write-Host -ForegroundColor Yellow "Finding shared mailboxes..."
    $sharedMailCount = (Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited).Count
    Write-Host -ForegroundColor Green "Found $sharedMailCount shared mailboxes.`n" 
    Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName
}

## Get number of room mailboxes
function getRoomMail {
    Write-Host -ForegroundColor Yellow "Finding room mailboxes..."
    $roomMailCount = (Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited).Count
    Write-Host -ForegroundColor Green "Found $roomMailCount room mailboxes.`n" 
    Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName
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
