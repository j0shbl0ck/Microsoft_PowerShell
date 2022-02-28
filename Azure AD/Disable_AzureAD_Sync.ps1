<#
.SYNOPSIS
    This script disables Active Directory syncing with Azure. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.12.22
    Type: Public
.NOTES
    You will need to have AzureAD V1 PowerShell module [ Install-Module -Name MSOnline ]
.LINK
    Source: https://blogs.eyonic.com/how-to-disable-active-directory-syncing-with-azure/ 
#>

# Connect to O365
Connect-MsolService

# Checks the current status of the on-prem syncing
(Get-MsolCompanyInformation).DirectorySynchronizationEnabled

# Sets Directory Syncing to off. 
Set-MsolDirSyncEnabled -EnableDirSync $false 

# Comment script line above, and uncomment script line below to turn Directory Syncing to on.
#Set-MsolDirSyncEnabled -EnableDirSync $true

Write-Host = "====== New Status ======"
# Checks again on the current status of the on-prem syncing
(Get-MsolCompanyInformation).DirectorySynchronizationEnabled





