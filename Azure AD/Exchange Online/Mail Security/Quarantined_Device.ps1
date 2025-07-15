
<#
.SYNOPSIS
    This allows all devices for a specific user to have access to ExchangeActiveSync.
.NOTES
    Author: Josh Block
    Date: 07.15.2025
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange Admin Center credentials
    try {
        Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ShowBanner:$false
        
        Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
        Write-Host ""
    }
    catch {
        Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
        exit
    }



# Approve quarantined ActiveSync devices for a given mailbox
function Release-QuarantinedDevices {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserEmail
    )

    try {
        $devices = Get-MobileDevice -Mailbox $UserEmail -ErrorAction Stop

        if ($devices.Count -eq 0) {
            Write-Host "No mobile devices found for $UserEmail"
            return
        }

        $quarantined = $devices | Where-Object { $_.DeviceAccessState -eq "Quarantined" }

        if ($quarantined.Count -eq 0) {
            Write-Host "No quarantined devices found for $UserEmail"
            return
        }

        foreach ($device in $quarantined) {
            Write-Host "Releasing device: $($device.DeviceID) on $($device.DeviceType)..."
            Set-MobileDevice -Identity $device.Identity -DeviceAccessState Allowed -Confirm:$false
        }

        Write-Host "All quarantined devices have been released for $UserEmail."
    } catch {
        Write-Error "Error: $_"
    }
}

# Main Script
$userEmail = Read-Host "Enter the user's email address"
Release-QuarantinedDevices -UserEmail $userEmail


