<#
.SYNOPSIS
    This script pulls information on where Azure AD Connect is installed
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 03.23.22
    Type: Public
.NOTES

.LINK
    Source: https://www.easy365manager.com/how-to-identify-your-azure-ad-connect-server/
#>

# Enter global admin credentials
Connect-MsolService


# Retrives AD Connect Hostname
$hostname = (Get-MsolCompanyInformation).DirSyncClientMachineName
Write-Host -ForegroundColor Yellow $hostname
Write-Host ""

# if no hostname is found, output error message
if ($null -eq $hostname) {
    Write-Host -ForegroundColor Red "No AD Connect Hostname Found"
    Write-Host ""
}

# End MS Online session
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()

Pause 
Write-Host "Exiting..."
