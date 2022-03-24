<#
.SYNOPSIS
    This script disables Active Directory syncing with Azure. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 01.12.22
    Type: Public
.NOTES
    You will need to have AzureAD V1 PowerShell module [ Install-Module -Name MSOnline ]
.LINK
    Source: https://blogs.eyonic.com/how-to-disable-active-directory-syncing-with-azure/ 
#>

# Connect to Microsoft Online Services
Connect-MsolService

# Checks the current status of the on-prem syncing
Write-Host -ForegroundColor Yellow "====== Current Status ======"
Write-Host "Current AD Sync Status: " (Get-MsolCompanyInformation).DirectorySynchronizationEnabled
Write-Host -ForegroundColor Red "Turning AD syncing off..."
# Sets Directory Syncing to off. 
Set-MsolDirSyncEnabled -EnableDirSync $false 
Write-Host -ForegroundColor Green "AD syncing turned off!"
Write-Host ""

# Comment script line above, and uncomment script line below to turn Directory Syncing to on.
#Set-MsolDirSyncEnabled -EnableDirSync $true

Write-Host -ForegroundColor Yellow "====== New Status ======"
# Checks again on the current status of the on-prem syncing
Write-Host "Current AD Sync Status: " (Get-MsolCompanyInformation).DirectorySynchronizationEnabled





