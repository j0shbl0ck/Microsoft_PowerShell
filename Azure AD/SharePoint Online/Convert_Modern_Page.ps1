<#
.SYNOPSIS
    This script converts the classic homepage of SharePoint to a modernized view.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 12.29.22
    Type: Public
.NOTES
    Required PS Module: Install-Module -Name SharePointPnPPowerShellOnline -Force -AllowClobber -Confirm:$False

.LINK
    Source: https://www.c-sharpcorner.com/article/transform-classic-sharepoint-pages-to-modern-look-and-feel/
    Source: https://learn.microsoft.com/en-us/sharepoint/dev/transform/modernize-userinterface-site-pages-powershell
#>

Clear-Host

# Connect to SharePoint Online via Azure AD
Connect-PnPOnline -Url https://company.sharepoint.com/sitename -UseWebLogin
 
# Modernize Home.aspx and add the page keep/discard banner on the page  
ConvertTo-PnPClientSidePage -Identity Home.aspx -AddPageAcceptBanner  