<#
.SYNOPSIS
    This script is made set the password of an AzureAD user to never expire. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.9
    Date: 01.04.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module
.LINK
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
#>

Clear-Host

# Connect to Azure Active Directory and prompt for credentials
try {
    Connect-AzureAD -ErrorAction Stop
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}

# Select user to modify
try {
    $User_UPN = Read-Host -Prompt 'Input User (enduser@domain.com) to modify'
    $user = Get-AzureADUser -ObjectId $User_UPN -ErrorAction Stop
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}

# Prompt for password policy option
$policy = Read-Host -Prompt 'Set password policy (D = DisablePasswordExpiration, E = EnableExpiration)'

# Set password policy
try {
    switch ($policy) {
        'D' { Set-AzureADUser -ObjectId $User_UPN -PasswordPolicies DisablePasswordExpiration -ErrorAction Stop }
        'E' { Set-AzureADUser -ObjectId $User_UPN -PasswordPolicies None -ErrorAction Stop }
        default { throw 'Invalid option' }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}

# Show confirmation of password policy
Write-Host '======= User Password Policy  =======' -ForegroundColor Yellow
$neverExpires = $user.PasswordPolicies -contains "DisablePasswordExpiration"
Write-Host "User: $($user.UserPrincipalName)"
Write-Host "PasswordNeverExpires: $neverExpires"

Write-Host 'Complete!' -ForegroundColor Green
Write-Host 'Script will close automatically in 10 seconds' -ForegroundColor Yellow
Start-Sleep -s 10