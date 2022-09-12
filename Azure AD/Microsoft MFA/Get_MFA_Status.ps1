<#
.SYNOPSIS
    This script pulls information on whether a user has MFA enabled or not. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.1.2
    Date: 03.23.22
    Type: Public
.NOTES
    You may need to resize the console window varying on email address length.
.LINK
    Source: https://dailysysadmin.com/KB/Article/3725/use-powershell-to-get-the-mfa-enabled-or-disabled-status-of-office-365-and-azure-users-and-type-of-mfa-used/
#>

Clear-Host

# Enter global admin credentials
Connect-MsolService

# Retrives MFA status and method per user
Write-Host -ForegroundColor Yellow "Retrieving user count from Azure AD..."

## VARIABLES ##
$UserCount = Get-MsolUser -All | ? { $_.UserType -ne "Guest" }
$mfareport = [System.Collections.Generic.List[Object]]::new()

Get-MsolUser | 
    Where-Object {$_.UserPrincipalName -notlike "*EXT*"} |
    Select-Object DisplayName,UserPrincipalName,
    @{N="MFA Status"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}},
    @{N="MFA Method"; E={ if( $_.StrongAuthenticationMethods.IsDefault -eq $true) {($_.StrongAuthenticationMethods | Where-Object IsDefault -eq $True).MethodType} else { "None"}}} | 
    Sort-Object DisplayName |
    Format-Table -AutoSize

## Remove MFA from user
#Get-MsolUser -all | Select-Object DisplayName,UserPrincipalName,@{N="MFA Status"; E={ if( $_.StrongAuthenticationMethods.IsDefault -eq $true) {($_.StrongAuthenticationMethods | Where-Object IsDefault -eq $True).MethodType} else { "Disabled"}}} | Format-Table -AutoSize | Where-Object MFAStatus -eq "Disabled" | Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationMethods @()
#Set-MsolUser -UserPrincipalName username@your_tenant.onmicrosoft.com -StrongAuthenticationMethods @()

<# # Ask if they want to export to CSV
$export = Read-Host "Do you want to export to CSV? (y/n)"
# if else statement
if ($export -eq "y") {
    # Export to CSV
    Get-MsolUser | 
        Where-Object {$_.UserPrincipalName -notlike "*EXT*"} |
        Select-Object DisplayName,UserPrincipalName,
        @{N="MFA Status"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}},
        @{N="MFA Method"; E={ if( $_.StrongAuthenticationMethods.IsDefault -eq $true) {($_.StrongAuthenticationMethods | Where-Object IsDefault -eq $True).MethodType} else { "None"}}} | 
        Sort-Object DisplayName |
        Export-Csv -Path "C:\Users\username\Desktop\mfa_status.csv" -NoTypeInformation
} elseif ($export -eq "n") {
    Disconnect-MsolService -Confirm:$false
    exit
} else {
    # Invalid input
    Write-Host "Invalid input. Please try again."
} #>

