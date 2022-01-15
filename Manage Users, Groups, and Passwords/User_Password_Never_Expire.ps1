<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.4
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

Start-Sleep 5s

# This sets the password of one user to never expire
Write-Host 'Disabling password experiation...' -ForegroundColor Yellow
Set-AzureADUser -ObjectId $User_UPN -PasswordPolicies DisablePasswordExpiration
Write-Host 'Complete!' -ForegroundColor Yellow

#This shows a confirmation of whether the password is set to never expire
Write-Host '======= User Password Policy  =======' -ForegroundColor Yellow
Get-AzureADUser -ObjectId $User_UPN | Select-Object UserprincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
}

Start-Sleep 30s
