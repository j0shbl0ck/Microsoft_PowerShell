<#
.SYNOPSIS
    This script pulls information how many user mailboxes are active and how many groups (M365,shared,Distri,Room) are active. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.1.6
    Date: 09.28.22
    Type: Public
.NOTES
    You will need to have Azure AD and Exchange Online module installed.
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
Write-Host -ForegroundColor Green "Folder created: $folder`n"

## Get number of licensed users
Write-Host -ForegroundColor Yellow "Finding user mailboxes mailboxes..."
$userMailCount = (Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited).Count
Write-Host -ForegroundColor Green "Found $userMailCount user mailboxes.`n"
Write-Output "Found $userMailCount user mailboxes.`n" >> "$folder\userMailExport.txt"
function getUserMail { 
    Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName | Format-Table -AutoSize
} getUserMail

## Get number of M365 groups
Write-Host -ForegroundColor Yellow "Finding M365 groups..."
$m365GroupCount = (Get-UnifiedGroup).Count
Write-Host -ForegroundColor Green "Found $m365GroupCount M365 groups.`n"
Write-Output "Found $m365GroupCount M365 groups.`n" >> "$folder\m365GroupExport.txt"
function getM365Groups {
    Get-UnifiedGroup | Format-List DisplayName,EmailAddresses
} getM365Groups

## Get number of distribution lists
Write-Host -ForegroundColor Yellow "Finding distribution lists..."
$distriListCount = (Get-DistributionGroup).Count
Write-Host -ForegroundColor Green "Found $distriListCount distribution lists.`n"
Write-Output "Found $distriListCount distribution lists.`n" >> "$folder\distriListExport.txt"
function getDistriLists {
    Get-DistributionGroup | Format-List DisplayName,EmailAddresses
} getDistriLists

## Get number of shared mailboxes
Write-Host -ForegroundColor Yellow "Finding shared mailboxes..."
$sharedMailCount = (Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited).Count
Write-Host -ForegroundColor Green "Found $sharedMailCount shared mailboxes.`n"
Write-Output "Found $sharedMailCount shared mailboxes.`n" >> "$folder\sharedMailExport.txt"
function getSharedMail { 
    Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName | Format-Table -AutoSize
} getSharedMail

## Get number of room mailboxes
Write-Host -ForegroundColor Yellow "Finding room mailboxes..."
$roomMailCount = (Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited).Count
Write-Host -ForegroundColor Green "Found $roomMailCount room mailboxes.`n"
Write-Output "Found $roomMailCount room mailboxes.`n" >> "$folder\roomMailExport.txt" 
function getRoomMail {
    Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited | Select-Object PrimarySmtpAddress,DisplayName | Format-Table -AutoSize
} getRoomMail

## Export results to TXT file in created folder
Write-Host -ForegroundColor Yellow "Exporting results to file..."
getUserMail | Out-File "$folder\userMailExport.txt" -Append
getM365Groups | Out-File "$folder\m365GroupExport.txt" -Append
getDistriLists | Out-File "$folder\distriListExport.txt" -Append
getSharedMail | Out-File "$folder\sharedMailExport.txt" -Append
getRoomMail | Out-File "$folder\roomMailExport.txt" -Append
Write-Host -ForegroundColor Green "Report is in $folder"

Pause

## Disconnect from Microsoft Services
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-AzureAD -Confirm:$false
