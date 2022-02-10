<#
.SYNOPSIS
    This script performs a delta sync on Azure AD Connect. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 02.10.22
    Type: Public
.NOTES

.LINK

#>

# Imports ADSync Module
Import-Module ADSync

# Shows current schedule settings for ADSync
Get-ADSyncScheduler

# Runs a delta sync on AAD Connect
Start-ADSyncSyncCycle -PolicyType Delta