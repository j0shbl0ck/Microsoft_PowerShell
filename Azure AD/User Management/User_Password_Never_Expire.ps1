<#
.SYNOPSIS
    This script is made set the password of an AzureAD user to never expire. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.8
    Date: 01.04.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module
.LINK
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
#>

Clear-Host

# ======= VARIABLES ======= #
# Enter Global Admin UPN and password
Connect-AzureAD 
$User_UPN = Read-Host -Prompt 'Input User (enduser@domain.com) to disable password expiration'
# ======= VARIABLES ======= #

Start-Sleep -s 5

# This sets the password of one user to never expire
Write-Host 'Disabling password expiration...' -ForegroundColor Yellow
Set-AzureADUser -ObjectId $User_UPN -PasswordPolicies DisablePasswordExpiration

#This shows a confirmation of whether the password is set to never expire
Write-Host '======= User Password Policy  =======' -ForegroundColor Yellow
Get-AzureADUser -ObjectId $User_UPN | Select-Object UserprincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
}
Write-Host 'Complete!' -ForegroundColor Green
Write-Host 'Script will close automatically in 10 seconds' -ForegroundColor Yellow

Start-Sleep -s 10
