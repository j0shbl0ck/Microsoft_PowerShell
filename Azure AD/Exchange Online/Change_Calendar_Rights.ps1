<#
.SYNOPSIS
    This script allows you to change calendar permissions through Exchange Online PowerShell
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.2.0
    Date: 01.17.22
    Type: Public
.EXAMPLE
    Set-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Owner
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    Username can vary on whether authenticating against domain or Azure AD. flast or firstlast@domain.com
#>

# ======= EXCHANGE CONNECTION ======= #

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
Clear-Host

# ======= USER VARIABLES ======= #
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to change calendar permissions of'
$seconduser = Read-Host -Prompt 'Input user email (seconduser@domain.com) of who you are giving access rights to'

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
    try {
        Write-Host -ForegroundColor Cyan "Allowing $seconduser the role of $role to $mainuser calendar..."
        Set-MailboxFolderPermission -Identity ${mainuser}:\calendar -user $seconduser -AccessRights $role -ErrorAction Stop
        
        ## Use this if it is a specified calendar created by main user
        #Remove-MailboxFolderPermission -Identity ${mainuser}:\calendar\HXBS -user $seconduser -Confirm:$false

        
        ## Use this if you need to also view events marked as private and accept calendar invites on their behalf.
        #Add-MailboxFolderPermission -Identity ${mainuser}:\calendar -user $seconduser -AccessRights role -SharingPermissionFlags Delegate,CanViewPrivateItems -ErrorAction Stop

        Pause
       }
    catch [System.Exception] {
        Write-Warning -Message "${seconduser} has no previous roles to mailbox. Adding ${seconduser} to mailbox with specified role."
        Add-MailboxFolderPermission -Identity ${mainuser}:\calendar -user $seconduser -AccessRights $role -ErrorAction Stop

        Pause
    }
    catch {
        Write-Output "Unable to add role to ${mainuser}: $($PSItem.ToString())"

        Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Red
        Disconnect-ExchangeOnline -Confirm:$false

        Pause
    }
    Write-Host -ForegroundColor Green "Complete!`n"

    # Shows other user rights to $mainuser
    Write-Host -ForegroundColor Yellow "======= Calendar Rights Other Users Have to $mainuser =======" 
    Get-EXOMailboxFolderPermission -Identity ${mainuser}:\calendar

    Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Green
    Disconnect-ExchangeOnline -Confirm:$false