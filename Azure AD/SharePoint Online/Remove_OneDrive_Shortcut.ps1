<#
.SYNOPSIS
    This script removes the "Add shortcuts to My Files" in SharePoint site
.NOTES
    Author: Josh Block
    Date: 09.15.22
    Type: Public
    Version: 1.0.3
.LINK
    https://github.com/j0shbl0ck
    https://www.sharepointdiary.com/2021/05/how-to-remove-add-shortcut-to-onedrive-in-sharepoint-online.html
#>

Clear-Host

# ask user for sharepoint url
$siteUrl = Read-Host "Enter the tenant admin SharePoint site URL (https://contoso-admin.sharepoint.com/) "

# Connect to SharePoint Online
Connect-SPOService -Url $siteUrl

# set DisableAddShortCutsToOneDrive to true
Set-SPOTenant -DisableAddShortCutsToOneDrive $True

# Let user know script is done
Write-Host "`nDisabling of adding shortcuts to OneDrive is set to TRUE" -ForegroundColor Green

# disconnect from SharePoint Online
Disconnect-SPOService 
