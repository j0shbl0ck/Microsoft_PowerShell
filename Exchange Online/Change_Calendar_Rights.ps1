<#
.SYNOPSIS
    This script allows you to view calendar permissions through Exchange Online PowerShell
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.7
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

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Connect-ExchangeOnline

# Displays Outlook calendar permission levels and access roles.
function Write-Role {
Write-Host -ForegroundColor Yellow "" 
Write-Host -ForegroundColor Yellow "Outlook Calendar Permission Levels and Access Roles"
Write-Host -ForegroundColor Yellow "======================================================="
Write-Host -ForegroundColor Yellow "Owner — gives full control of the mailbox folder: read, create, modify, and delete all items and folders. Also, this role allows to manage item's permissions"
Write-Host -ForegroundColor Yellow "PublishingEditor — read, create, modify, and delete items/subfolders (all permissions, except the right to change permissions)"
Write-Host -ForegroundColor Yellow "Editor — read, create, modify, and delete items (can't create subfolders)"
Write-Host -ForegroundColor Yellow "PublishingAuthor — create, read all items/subfolders. You can modify and delete only items you create."
Write-Host -ForegroundColor Yellow "Author — create and read items. Edit and delete own items"
Write-Host -ForegroundColor Yellow "NonEditingAuthor — full read access, and create items. You can delete only your own items"
Write-Host -ForegroundColor Yellow "Reviewer — read folder items only"
Write-Host -ForegroundColor Yellow "Contributor — create items and folders (can't read items)."
Write-Host -ForegroundColor Yellow "AvailabilityOnly — read Free/Busy info from the calendar"
Write-Host -ForegroundColor Yellow "LimitedDetails — view availability data with calendar item subject and location"
Write-Host -ForegroundColor Yellow "None — no permissions to access folder and files."
Write-Host -ForegroundColor Yellow "======================================================="
Write-Host -ForegroundColor Yellow ""
}    

Write-Role;


$role = Read-Host -Prompt 'Input access role you wish to give second user to main users calendar'
Add-MailboxFolderPermission -Identity ${mainuser}:\calendar -user $seconduser -AccessRights $role

# Outputs conformation of adding calendar permissions.=
Write-Host -ForegroundColor Cyan "Allowing $seconduser the role of $role to $mainuser calendar..."
Write-Host -ForegroundColor Cyan "Complete!"
Write-Host ""

# Shows other user rights to $mainuser
Write-Host -ForegroundColor Yellow "======= Calendar Rights Other Users Have to $mainuser =======" 
Get-EXOMailboxFolderPermission -Identity ${mainuser}:\calendar

Pause




