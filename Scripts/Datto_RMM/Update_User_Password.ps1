<#
.SYNOPSIS
    This script finds a given user account and changes the password. If the second account exists, remove it from the device for consolidation.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.02.24
    Type: Public
.NOTES
    This script it built for the Datto RMM platform.
.LINK
#>

Clear-Host

# Define the account names and password
$accountName = "userone"
$accountName2 = "usertwo"
$newPassword = "M*rcur1us^%" | ConvertTo-SecureString -AsPlainText -Force

Clear-Host

# Function to create or update accountName
function CreateOrUpdateAccount($accountName, $newPassword) {
    # Check if the account exists
    $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue
    # If the account does not exist, create it
    if (!$account) {
        try {
            $account = New-LocalUser -Name $accountName -Password $newPassword -PasswordNeverExpires -AccountNeverExpires
            # Add the account to the Administrators group
            $adminGroup = Add-LocalGroupMember -Group "Administrators" -Member "$accountName"
            # Get the account and Administrator membership to verify
            $Getaccount = Get-LocalUser -Name $accountName
            # Output the results
            # If the account is found and the Administrator group contains the account, the account was created successfully
            if ($Getaccount) {
                Write-Output "Account '$accountName' created successfully."
            } else {
                Write-Error "Failed to create account '$accountName'."
            }
        } catch {
            Write-Error "Failed to create account '$accountName'."
        }
    } else {
        # Change the password
        try {
            $account | Set-LocalUser -Password $newPassword -PasswordNeverExpires $true -AccountNeverExpires
            Write-Output "Password for account '$accountName' changed successfully."
        } catch {
            Write-Error "Failed to change password for account '$accountName'."
        }
    }
}

# Function to remove accountName2
function RemoveAccount($accountName2) {
    # Check if the account exists
    $account2 = Get-LocalUser -Name $accountName2 -ErrorAction SilentlyContinue

    if ($account2) {
        # Remove the account
        try {
            $account2 | Remove-LocalUser
            Write-Output "Account '$accountName2' removed successfully."
        } catch {
            Write-Error "Failed to remove account '$accountName2'."
        }
    } else {
        Write-Output "Account '$accountName2' not found." -ErrorAction Ignore
    }
}

# Create or update accountName
CreateOrUpdateAccount $accountName $newPassword

# Remove accountName2
RemoveAccount $accountName2