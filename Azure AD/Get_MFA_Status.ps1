<#
.SYNOPSIS
    This script pulls information on whether a user has MFA enabled or not. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 03.23.22
    Type: Public
.NOTES
    
.LINK
    Source: https://dailysysadmin.com/KB/Article/3725/use-powershell-to-get-the-mfa-enabled-or-disabled-status-of-office-365-and-azure-users-and-type-of-mfa-used/
#>

Connect-MsolService

Get-MsolUser -all | select DisplayName,UserPrincipalName,@{N="MFA Status"; E={ if( $_.StrongAuthenticationMethods.IsDefault -eq $true) {($_.StrongAuthenticationMethods | Where IsDefault -eq $True).MethodType} else { "Disabled"}}} | FT -AutoSize

