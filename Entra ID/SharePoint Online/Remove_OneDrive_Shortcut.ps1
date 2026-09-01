<#
.SYNOPSIS
    This script removes the "Add shortcuts to My Files" in SharePoint site
.NOTES
    Author: Josh Block
    Date: 09.15.22
    Type: Public
    Version: 1.0.4
.LINK
    https://github.com/j0shbl0ck
    https://www.sharepointdiary.com/2021/05/how-to-remove-add-shortcut-to-onedrive-in-sharepoint-online.html
#>

Clear-Host

# Prompt for SharePoint Online site URL and validate input
do {
    $siteUrl = Read-Host "Enter the tenant admin SharePoint site URL (https://contoso-admin.sharepoint.com/) "
} until ($siteUrl -match '^https?://[-\w.]+(:\d+)?/')

# Connect to SharePoint Online and handle errors
try {
    Connect-SPOService -Url $siteUrl -ErrorAction Stop
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}

# Prompt for password policy option and handle errors
do {
    $policy = Read-Host -Prompt 'Set shortcut policy (D = DisableAddShortCutsToOneDrive, E = EnableAddShortCutsToOneDrive)'
} until ($policy -in 'D', 'E')

try {
    switch ($policy) {
        'D' { Set-SPOTenant -DisableAddShortCutsToOneDrive $True -ErrorAction Stop }
        'E' { Set-SPOTenant -DisableAddShortCutsToOneDrive $False -ErrorAction Stop }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}

# Show confirmation of shortcut policy
Write-Host "`nDisabling of adding shortcuts to OneDrive is set to $($policy -eq 'D')" -ForegroundColor Green

# Disconnect from SharePoint Online and handle errors
try {
    Disconnect-SPOService -ErrorAction Stop
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}
