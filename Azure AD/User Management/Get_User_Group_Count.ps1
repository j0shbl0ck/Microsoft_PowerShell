<#
.SYNOPSIS
    This script pulls information how many users are currently licensed and how many groups (M365,shared,Distri,Mail-Enab) are active. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.9
    Date: 09.28.22
    Type: Public
.NOTES
    You will need to have Microsoft Graph Module installed.
.LINK
    Source: https://www.tecklyfe.com/get-a-count-of-azure-ad-active-directory-users/
    Source: https://learn.microsoft.com/en-us/microsoft-365/enterprise/view-licensed-and-unlicensed-users-with-microsoft-365-powershell?view=o365-worldwide


#>

## Connect to Microsoft Services
Connect-AzureAD
Connect-ExchangeOnline
Clear-Host


## Create folder on desktop to store reports
Write-Host -ForegroundColor Yellow "Creating folder on desktop to store reports..."
$desktop = [Environment]::GetFolderPath("Desktop")
$folder = $desktop + "\User_Group_Count"
New-Item -ItemType Directory -Path $folder 
Write-Host -ForegroundColor Green "Folder created: $folder"




## Get number of licensed users
Write-Host -ForegroundColor Yellow "Finding user mailboxes mailboxes..."
$userMailCount = (Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited).Count
Write-Host -ForegroundColor Green "Found $userMailCount shared mailboxes.`n"
function getUserMail { 
    Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName | Format-Table -AutoSize
}

## Get number of M365 groups
Write-Host -ForegroundColor Yellow "Finding M365 groups..."
$m365GroupCount = (Get-UnifiedGroup).Count
Write-Host -ForegroundColor Green "Found $m365GroupCount M365 groups.`n" 
function getM365Groups {
    Get-UnifiedGroup | Format-List DisplayName,EmailAddresses
}

## Get number of distribution lists
Write-Host -ForegroundColor Yellow "Finding distribution lists..."
$distriListCount = (Get-DistributionGroup).Count
Write-Host -ForegroundColor Green "Found $distriListCount distribution lists.`n" 
function getDistriLists {
    Get-DistributionGroup | Format-List DisplayName,EmailAddresses
}

## Get number of shared mailboxes
Write-Host -ForegroundColor Yellow "Finding shared mailboxes..."
$sharedMailCount = (Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited).Count
Write-Host -ForegroundColor Green "Found $sharedMailCount shared mailboxes.`n"
function getSharedMail { 
    Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName | Format-Table -AutoSize
}

## Get number of room mailboxes
Write-Host -ForegroundColor Yellow "Finding room mailboxes..."
$roomMailCount = (Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited).Count
Write-Host -ForegroundColor Green "Found $roomMailCount room mailboxes.`n" 
function getRoomMail {
    Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName | Format-Table -AutoSize
}


# run functions
getLicensedUsers
getM365Groups
getDistriLists
getSharedMail
getRoomMail


## Export results to TXT file in created folder
Write-Host -ForegroundColor Yellow "Exporting results to file..."
$user_group_export = $folder + "\userGroupExport.txt"
getM365Groups | Out-File $user_group_export
Write-Host "Report is in $user_group_export"
