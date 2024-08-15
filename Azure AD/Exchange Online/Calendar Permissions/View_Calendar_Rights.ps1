<#
.SYNOPSIS
    This script allows you to view calendar permissions on O365
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.1.2
    Date: 01.06.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    Username can vary on whether authenticating against domain or Azure AD. flast or firstlast@domain.com
.LINK
    Source: https://theitbros.com/add-calendar-permissions-in-office-365-via-powershell/
    Source: https://community.spiceworks.com/topic/2319204-o365-calendar-sharing-with-powershell 
#>

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to view calendar permissions of'
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin 

# Change username to which email you are changing.
Write-Host '======= Users who have Calendar Rights ${mainuser}  =======' -ForegroundColor Yellow
Get-EXOMailboxFolderPermission -Identity ${mainuser}:\calendar

# To view access rights of a user's other calendars. For example, user has a calendar named "time off". Uncomment below.
#Get-MailboxFolderPermission -Identity "${mainuser}:\calendar\time off"

# View calender's shared with user. 
Write-Host '======= ${mainuser} has Calendars Rights to =======' -ForegroundColor Yellow
(Get-EXOMailbox) | ForEach-Object {
    $Identity = $_.Identity
    Get-EXOMailboxFolderPermission (($_.PrimarySmtpAddress)+":\calendar")  `
        -User $mainuser -ErrorAction SilentlyContinue
    } | Select-Object @{n='Identity';e={$Identity}}, User, Accessrights

# View calenders created by user. Uncomment below.
Write-Host '======= Calendars Created By Main User =======' -ForegroundColor Yellow
Get-EXOMailboxFolderStatistics -Identity $mainuser | Where-Object { ($_.Identity -like "*calendar*") -and ($_.FolderType -ne 'CalendarLogging') } | Format-Table Name,Identity,FolderPath,FolderType

# Terminate Exchange Online PS Session
Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false

Pause