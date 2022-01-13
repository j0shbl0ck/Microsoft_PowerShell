<#
.SYNOPSIS
    This script allows you to view, add or remove mailbox calendar permissions on O365
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.9
    Date: 01.06.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    Username can vary on whether authenticating against domain or Azure AD. flast or firstlast@domain.com
.LINK
    Source: https://theitbros.com/add-calendar-permissions-in-office-365-via-powershell/
    Source: https://community.spiceworks.com/topic/2319204-o365-calendar-sharing-with-powershell 
.EXAMPLE
    Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Owner

#>

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to view calendar permissions of'
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin 

# Change username to which email you are changing.
Write-Host '======= Calendar Rights Other Users Have to Main User  =======' -ForegroundColor Yellow
Get-EXOMailboxPermission -Identity ${mainuser}:\calendar

# To view access rights of a user's other calendars. For example, user has a calendar named "time off". Uncomment below.
#Get-MailboxFolderPermission -Identity "username:\calendar\time off"

# View calender's shared with user. 
Write-Host '======= Calendars Main User Has Rights To =======' -ForegroundColor Yellow
(Get-Mailbox) | ForEach-Object {
    $Identity = $_.Identity
    Get-EXOMailboxPermission (($_.PrimarySmtpAddress)+":\calendar") `
        -User $mainuser -ErrorAction SilentlyContinue
    } | Select-Object @{n='Identity';e={$Identity}}, User, Accessrights

# View calenders created by user. Uncomment below.
Write-Host '======= Calendars Created By Main User =======' -ForegroundColor Yellow
Get-MailboxFolderStatistics -Identity $mainuser | Where-Object { ($_.Identity -like "*calendar*") -and ($_.FolderType -ne 'CalendarLogging') } | Format-Table Name,Identity,FolderPath,FolderType

<#
**Outlook Calendar Permission Levels and Access Roles**
=======================================================
Owner — gives full control of the mailbox folder: read, create, modify, and delete all items and folders. Also, this role allows to manage item’s permissions;
PublishingEditor — read, create, modify, and delete items/subfolders (all permissions, except the right to change permissions);
Editor — read, create, modify, and delete items (can’t create subfolders);
PublishingAuthor — create, read all items/subfolders. You can modify and delete only items you create;
Author — create and read items. Edit and delete own items;
NonEditingAuthor — full read access, and create items. You can delete only your own items;
Reviewer — read folder items only;
Contributor — create items and folders (can’t read items);
AvailabilityOnly — read Free/Busy info from the calendar;
LimitedDetails — view availability data with calendar item subject and location;
None — no permissions to access folder and files.
#>

# The first email address is the one you're needing access. The second email is who you're giving access rights to. 
#Add-MailboxFolderPermission -Identity ${mainuser}:\calendar -user $seconduser -AccessRights Editor

# Comment out line below, if you need to also view events marked as private.
#Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Editor -SharingPermissionFlags Delegate,CanViewPrivateItems

Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false

Pause