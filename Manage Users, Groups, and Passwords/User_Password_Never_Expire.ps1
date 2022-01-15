<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.6
    Date: 01.04.22
    Type: Public
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
    Description: This script is made set the password of an AzureAD user to never expire. 
    =============================================================================
    .ADDITIONAL NOTES
        You will need to have AzureAD PowerShell module
#>

# ======= VARIABLES ======= #
# Enter Global Admin UPN and password
Connect-AzureAD 
$User_UPN = Read-Host -Prompt 'Input User (enduser@domain.com) to disable password expiration'
# ======= VARIABLES ======= #

Start-Sleep -s 5

# This sets the password of one user to never expire
Write-Host 'Disabling password experiation...' -ForegroundColor Yellow
Set-AzureADUser -ObjectId $User_UPN -PasswordPolicies DisablePasswordExpiration

#This shows a confirmation of whether the password is set to never expire
Write-Host '======= User Password Policy  =======' -ForegroundColor Yellow
Get-AzureADUser -ObjectId $User_UPN | Select-Object UserprincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
}
Write-Host 'Complete!' -ForegroundColor Yellow

Start-Sleep -s 10
