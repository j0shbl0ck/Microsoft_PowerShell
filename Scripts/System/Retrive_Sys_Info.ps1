<#
.SYNOPSIS
    This script allows you view system information of the device.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.5
    Date: 02.07.22
    Type: Public
.NOTES

#>

# === VARIABLES START === #
$hostname = hostname
# === VARIABLES END === #

# Informational Message
Write-Host -ForegroundColor Yellow "This entails all information for device: ${hostname}"
Write-Host ""

Write-Host -ForegroundColor Cyan "CURRENT USER INFORMATION:"
Write-Host ""
Write-Host 'Domain\Username:' ((Get-WMIObject -class Win32_ComputerSystem | Select-Object -ExpandProperty username))
Write-Host ""

Write-Host -ForegroundColor Cyan "BIOS INFORMATION:"
Get-CimInstance -ClassName win32_bios | Format-Table -AutoSize

Write-Host -ForegroundColor Cyan "COMPUTER SYSTEM:"
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name,PrimaryOwnerName,Domain,Model,Manufacturer, `
@{N='RAM(GB)'; E={[Math]::Round(($_.TotalPhysicalMemory)/1GB,2)}} | Format-Table -AutoSize

Write-Host -ForegroundColor Cyan "OS INFORMATION:"
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Build*,OSType | Format-Table -AutoSize

Write-Host -ForegroundColor Cyan "DISK INFORMATION"
Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object{$_.DriveType -eq '3'} `
| Select-Object DeviceID, VolumeName, `
@{N='FreeSpace(GB)'; E={[Math]::Round(($_.FreeSpace)/1GB,2)}}, `
@{N='TotalSize(GB)'; E={[Math]::Round(($_.Size)/1GB,2)}} | Format-Table -Autosize 

Write-Host -ForegroundColor Cyan "SYSTEM PROCESSOR:"
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property SystemType | Format-Table -AutoSize

Write-Host -ForegroundColor Cyan "NETWORK INFORMATION:"
Get-NetIPConfiguration | Select-Object -Property InterfaceAlias,InterfaceDescription,IPv4Address | Format-Table

