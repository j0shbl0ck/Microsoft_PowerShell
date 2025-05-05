<#
.SYNOPSIS
    This script installs PSWindowsUpdate module and installs all available Windows updates.
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 05.05.25
    Type: Public
.NOTES

#>
Install-Module -Name PSWindowsUpdate -Confirm:$false
Install-WindowsUpdate -AcceptAll -IgnoreReboot