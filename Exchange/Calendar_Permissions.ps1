<#
.SYNOPSIS
    This script allows you to view, add or remove mailbox calendar permissions on O365
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.06.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
.LINK
    Source: https://theitbros.com/add-calendar-permissions-in-office-365-via-powershell/
.EXAMPLE
    Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Owner

#>

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName globaladmin@domain.com 

# Change username to which email you are changing.
Get-MailboxFolderPermission -Identity username:\calendar

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
Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Editor

# Comment out line below, if you need to also view events marked as private.
#Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Editor -SharingPermissionFlags Delegate,CanViewPrivateItems
