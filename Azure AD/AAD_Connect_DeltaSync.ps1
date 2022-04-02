<#
.SYNOPSIS
    This script performs a delta sync on Azure AD Connect. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.5
    Date: 02.10.22
    Type: Public
.NOTES

.LINK

#>

==== Remote PowerShell Connection ====

## Imports ADSync Module
#Import-Module ADSync

## Remote PowerShell Connection to Azure AD Connect Server (Uncomment below to use)
#Enter-PSSession [ADConnect Server]

## Shows current schedule settings for ADSync
#Get-ADSyncSchedule

## Runs a delta sync on AAD Connect
#Start-ADSyncSyncCycle -PolicyType Delta

## Remote PowerShell Connection to Azure AD Connect Server (Uncomment below to use)
#Exit-PSSession

==== Remote Powershell Connection ====

==== AAD Connect Server Connection ====

Start-ADSyncSyncCycle -PolicyType Delta

==== AAD Connect Server Connection ====
