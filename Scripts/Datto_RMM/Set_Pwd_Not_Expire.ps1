<#
.SYNOPSIS
    This script sets the password for a local user account to not expire.
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

Set-LocalUser -Name "username" -PasswordNeverExpires:$true