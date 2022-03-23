<#
.SYNOPSIS
    This script pulls information on where Azure AD Connect is installed
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 03.23.22
    Type: Public
.NOTES

.LINK
    Source: https://www.easy365manager.com/how-to-identify-your-azure-ad-connect-server/
#>

# Enter global admin credentials
Connect-MsolService

# Retrives AD Connect Hostname
(Get-MsolCompanyInformation).DirSyncClientMachineName

# End MS Online session
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()

Pause 
