<#
.SYNOPSIS
    This script allows you view system information of the device.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.3
    Date: 02.07.22
    Type: Public
.NOTES

#>

# === VARIABLES START === #
$hostname = hostname
$userinfo = Get-ChildItem env:user*
$disk = Get-PhysicalDisk
$volume = Get-Volume
# === VARIABLES END === #

# Informational Message
Write-Host -ForegroundColor Yellow "This entails all information for device: ${hostname}"
Write-Host ""

Write-Host -ForegroundColor Cyan "CURRENT USER INFORMATION:"
Write-Output $userinfo
Write-Host ""

Write-Host -ForegroundColor Cyan "BIOS INFORMATION:"
Get-CimInstance -ClassName win32_bios

Write-Host -ForegroundColor Cyan "COMPUTER SYSTEM:"
Get-CimInstance -ClassName Win32_ComputerSystem

Write-Host -ForegroundColor Cyan "OS INFORMATION:"
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Build*,OSType

Write-Host -ForegroundColor Cyan "DISK INFORMATION"
Write-Output $disk
Write-Output "========================="
Write-Output $volume

Write-Host -ForegroundColor Cyan "SYSTEM PROCESSOR:"
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property SystemType

Write-Host -ForegroundColor Cyan "NETWORK INFORMATION:"
Get-NetIPConfiguration

Write-Host -ForegroundColor Magenta "All information produced. Close PowerShell when ready..."
[void][System.Console]::ReadKey($FALSE)
