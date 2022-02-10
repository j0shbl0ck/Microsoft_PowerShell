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

Import-Module ADSync

Get-ADSyncScheduler

Start-ADSyncSyncCycle -PolicyType Delta