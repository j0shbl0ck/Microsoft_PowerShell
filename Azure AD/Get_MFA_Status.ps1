<#
.SYNOPSIS
    This script pulls information on whether a user has MFA enabled or not. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.4
    Date: 03.23.22
    Type: Public
.NOTES
    You may need to resize the console window varying on email address length.
.LINK
    Source: https://dailysysadmin.com/KB/Article/3725/use-powershell-to-get-the-mfa-enabled-or-disabled-status-of-office-365-and-azure-users-and-type-of-mfa-used/
#>

# Enter global admin credentials
Connect-MsolService

# Retrives MFA status per user
Get-MsolUser -all | select DisplayName,UserPrincipalName,@{N="MFA Status"; E={ if( $_.StrongAuthenticationMethods.IsDefault -eq $true) {($_.StrongAuthenticationMethods | Where IsDefault -eq $True).MethodType} else { "Disabled"}}} | FT -AutoSize

# End MS Online session
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()

Pause 