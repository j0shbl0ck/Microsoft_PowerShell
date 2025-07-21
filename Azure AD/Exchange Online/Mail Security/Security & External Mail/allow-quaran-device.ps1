<#
.SYNOPSIS
    This allows all devices for a specific user to have access to ExchangeActiveSync.
.NOTES
    Author: Josh Block
    Date: 07.15.2025
    Type: Public
    Version: 1.0.5
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
function Release-QuarantinedCASDevices {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserEmail
    )

    try {
        # Get quarantined mobile devices for the user
        $quarantinedDevices = Get-MobileDevice -Mailbox $UserEmail | Where-Object {
            $_.DeviceAccessState -eq 'Quarantined'
        }

        if (-not $quarantinedDevices) {
            Write-Host "No quarantined devices found for $UserEmail."
            return
        }

        foreach ($device in $quarantinedDevices) {
            Write-Host "Releasing device: $($device.DeviceID) on $($device.DeviceType)..."

            # Approve the device using CASMailbox settings
            Set-CASMailbox -Identity $UserEmail -ActiveSyncAllowedDeviceIDs @{Add=$device.DeviceID}

            Write-Host "Device $($device.DeviceID) released from quarantine."
        }

        Write-Host "All quarantined devices have been released for $UserEmail."
    }
    catch {
        Write-Error "Error releasing devices for ${UserEmail}: $_"
    }
}

# Loop to handle multiple users
do {
    # Your user processing code here
    $userEmail = Read-Host "Enter the user's email address"
    Release-QuarantinedCASDevices -UserEmail $userEmail
    Write-Host ""
    $Continue = Read-Host -Prompt "Would you like to add another user? (Y/N)"

    if ($continue -ne '^[Yy]$' {
        Write-Host "`nExiting script." -ForegroundColor Cyan
        Exit
    }
} while ($continue -eq '^[Yy]$')
