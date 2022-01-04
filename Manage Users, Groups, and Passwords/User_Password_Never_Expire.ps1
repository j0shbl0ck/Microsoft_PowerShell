<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.04.22
    Type: Public
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
    Description: This script is made set the password of a user to never expire. 
    =============================================================================
    .ADDITIONAL NOTES
        You will need to have AzureAD PowerShell module
#>


Connect-AzureAD

# In the qoutes, type in the UPN (for example, user@contoso.onmicrosoft.com).
$User_UPN = "user@contoso.onmicrosoft.com"

# This sets the password of one user to never expire
Set-AzureADUser -ObjectId $User_UPN -PasswordPolicies DisablePasswordExpiration

#This shows a confirmation of whether the password is set to never expire
Get-AzureADUser -ObjectId $User_UPN | Select-Object UserprincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
}

Pause