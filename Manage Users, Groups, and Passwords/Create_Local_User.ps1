<#
.SYNOPSIS
    This script creates a localadmin account on the device. Use .\ to login into system.
    Author: Josh Block
.NOTES
    Version: 1.0.0
    Date: 07.25.22
    Type: Public
.LINK
    https://github.com/j0shbl0ck
#>

## Run this script in PowerShell ISE as admin to properly edit the script.

# Ask user for username
$ExpectedLocalUser = Read-Host "Enter a username for the user account: "

# Ask user for password
$Password = Read-Host "Enter a password for the user account: "
$convertedpassword = ConvertTo-SecureString $Password -AsPlainText -Force

# Ask user for description of account
$Description = Read-Host "Enter a description for the user account: "

Function Create_LocalAdmin
{

    New-LocalUser $ExpectedLocalUser -Password $convertedpassword -FullName "<First Last>" -Description $Description
    Add-LocalGroupMember -Group "Administrators" -Member $ExpectedLocalUser
    Set-LocalUser -Name $ExpectedLocalUser -PasswordNeverExpires:$true
}

Try

{

    ## Catch if not found
    $LocaAdminUser = Get-LocalUser -Name $ExpectedLocalUser -ErrorAction Stop 

    ## If an account is found update the password
    Set-LocalUser -Name $ExpectedLocalUser -Password $convertedpassword -PasswordNeverExpires:$true

}

Catch

{

    Create_LocalAdmin

}


