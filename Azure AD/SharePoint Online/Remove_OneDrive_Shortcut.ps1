<#
.SYNOPSIS
    This script removes the "Add shortcuts to My Files" in SharePoint site
.NOTES
    Author: Josh Block
    Date: 09.015.22
    Type: Public
    Version: 1.0.2
.LINK
    https://github.com/j0shbl0ck
    https://www.sharepointdiary.com/2021/05/how-to-remove-add-shortcut-to-onedrive-in-sharepoint-online.html
#>

Clear-Host

# Connect to SharePoint Online
Connect-SPOService -Url $siteUrl

# ask user for sharepoint url
$siteUrl = Read-Host "Enter the tenant admin SharePoint site URL (https://contoso-admin.sharepoint.com/) "

# Get current state of "DisableAddShortCutsToOneDrive
Get-SPOTenant -DisableAddShortCutsToOneDrive

# provide warning for removal
Write-Warning "The Add shortcut to OneDrive option will be removed from all SharePoint Online document libraries. However, existing shortcuts remain in place on OneDrive." -WarningAction Inquire

# set DisableAddShortCutsToOneDrive to true
Set-SPOTenant -DisableAddShortCutsToOneDrive $True

# Get current state of "DisableAddShortCutsToOneDrive
Get-SPOTenant

# disconnect from SharePoint Online
Disconnect-SPOService -Confirm:$false
