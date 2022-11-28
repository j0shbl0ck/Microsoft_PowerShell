<#
.SYNOPSIS
    This script allows custom scripting to a SharePoint site
.NOTES
    Author: Josh Block
    Date: 11.28.22
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/sharepoint/allow-or-prevent-custom-script?ad=in-text-link#to-allow-custom-script-on-other-sharepoint-sites
#>

Clear-Host

# ask user for admin sharepoint url
$adminSiteUrl = Read-Host "Enter the tenant admin SharePoint site URL (https://contoso-admin.sharepoint.com/) "

# Connect to SharePoint Online
Connect-SPOService -Url $adminSiteUrl

# ask user for site url
$siteUrl = Read-Host "Enter the site URL (https://contoso.sharepoint.com/sites/MySite) "

# set the site to allow custom scripting
Set-SPOSite $siteUrl -DenyAddAndCustomizePages 0

# Let user know script is done
Write-Host "`nDeny Add and Customize Pages set to FALSE" -ForegroundColor Green

# disconnect from SharePoint Online
Disconnect-SPOService 
