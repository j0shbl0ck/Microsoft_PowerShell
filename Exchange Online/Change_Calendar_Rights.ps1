<#
.SYNOPSIS
    This script allows you to view calendar permissions through Exchange Online PowerShell
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.17.22
    Type: Public
.EXAMPLE
    Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Owner
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    Username can vary on whether authenticating against domain or Azure AD. flast or firstlast@domain.com
#>

# ======= VARIABLES ======= #
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to change calendar permissions of'
$seconduser = Read-Host -Prompt 'Input user email (seconduser@domain.com) of who you are giving access rights to'

# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline

Write-Host = "**Outlook Calendar Permission Levels and Access Roles**
=======================================================
Owner — gives full control of the mailbox folder: read, create, modify, and delete all items and folders. Also, this role allows to manage item’s permissions;
PublishingEditor — read, create, modify, and delete items/subfolders (all permissions, except the right to change permissions);
Editor — read, create, modify, and delete items (can't create subfolders);
PublishingAuthor — create, read all items/subfolders. You can modify and delete only items you create;
Author — create and read items. Edit and delete own items;
NonEditingAuthor — full read access, and create items. You can delete only your own items;
Reviewer — read folder items only;
Contributor — create items and folders (can't read items);
AvailabilityOnly — read Free/Busy info from the calendar;
LimitedDetails — view availability data with calendar item subject and location;
None — no permissions to access folder and files." -ForegroundColor Cyan

$role = Read-Host -Prompt 'Input access role you wish to give second user to main users calendar'
Add-MailboxFolderPermission -Identity ${mainuser}:\calendar -user $seconduser -AccessRights $role
Write-Host = "Allowing $seconduser the role of $role to $mainuser calendar..." -ForegroundColor Cyan
Write-Host = "Complete!"
Write-Host = ""
Write-Host '======= Calendar Rights Other Users Have to Main User  =======' -ForegroundColor Yellow
Get-EXOMailboxFolderPermission -Identity ${mainuser}:\calendar




