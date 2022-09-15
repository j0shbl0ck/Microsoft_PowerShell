<#
.SYNOPSIS
    This script removes the "Add shortcuts to My Files" in SharePoint site
.NOTES
    Author: Josh Block
    Date: 09.015.22
    Type: Public
    Version: 1.0.1
.LINK
    https://github.com/j0shbl0ck
    https://www.sharepointdiary.com/2021/05/how-to-remove-add-shortcut-to-onedrive-in-sharepoint-online.html
#>

Clear-Host

# ask user for sharepoint url
$siteUrl = Read-Host "Enter the main SharePoint site URL"

# provide warning for removal
Write-Warning "The Add shortcut to OneDrive option will be removed from SharePoint Online document libraries. However, existing shortcuts remain in place on OneDrive." -WarningAction Inquire

# Connect to SharePoint Online
Connect-SPOService -Url $siteUrl
 
Set-SPOTenant -DisableAddShortCutsToOneDrive $True

# disconnect from SharePoint Online
Disconnect-SPOService -Confirm:$false
