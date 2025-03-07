<#
.SYNOPSIS
    This script need a PowerShell script that gets the Windows system up-time and if it's over six days, force restart the device.
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 03.02.25
    Type: Public
.NOTES
    This script it built for the Datto RMM platform.
    Make sure you have all files uploaded to the component before deploying the script.
.LINK
    https://github.com/j0shbl0ck
#>


# Get system uptime in days
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeDays = (New-TimeSpan -Start $uptime -End (Get-Date)).Days

# Define threshold (6 days)
$threshold = 6

# Check if uptime exceeds threshold
if ($uptimeDays -gt $threshold) {
    Write-Host "System uptime is $uptimeDays days. Restarting..."
    Restart-Computer -Force
} else {
    Write-Host "System uptime is $uptimeDays days. No restart needed."
}