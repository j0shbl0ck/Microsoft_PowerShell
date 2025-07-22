<#
.SYNOPSIS
    This allows all devices for a specific user to have access to ExchangeActiveSync.
.NOTES
    Author: Josh Block
    Date: 07.15.2025
    Type: Public
    Version: 1.0.9
.LINK
    https://github.com/j0shbl0ck
#>

Clear-Host

# region Connect to Exchange Online
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'

    Connect-ExchangeOnline -ShowBanner:$false

    Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
    exit
}
# endregion


# region Function: Release-QuarantinedCASDevices
function Release-QuarantinedCASDevices {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserEmail
    )

    try {
        # Get quarantined mobile devices for the user
        $quarantinedDevices = Get-MobileDevice -Mailbox $UserEmail | Where-Object { $_.DeviceAccessState -eq 'Quarantined' }

        if (-not $quarantinedDevices) {
            Write-Host "No quarantined devices found for $UserEmail." -ForegroundColor Gray
            return
        }

        foreach ($device in $quarantinedDevices) {
            Write-Host "Releasing device: $($device.DeviceID) on $($device.DeviceType)..." -ForegroundColor Yellow

            # Approve the device using CASMailbox settings
            Set-CASMailbox -Identity $UserEmail -ActiveSyncAllowedDeviceIDs @{Add=$device.DeviceID}

            Write-Host "Device $($device.DeviceID) released from quarantine." -ForegroundColor Green
        }

        Write-Host "All quarantined devices have been released for $UserEmail.`n" -ForegroundColor Green
    }
    catch {
        Write-Error "Error releasing devices for ${UserEmail}: $_"
    }
}
# endregion


# region Main Script Loop
do {
    $userEmail = Read-Host "`nEnter the user's email address"
    Release-QuarantinedCASDevices -UserEmail $userEmail

    # Input validation loop for continuation
    do {
        $continue = Read-Host "`nDo you want to process another email address? (Y/N)"
        if ($continue -notmatch '^[YyNn]$') {
            Write-Host "Invalid input. Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Red
        }
    } while ($continue -notmatch '^[YyNn]$')

} while ($continue -in 'Y', 'y')
# endregion


Write-Host "`nExiting script." -ForegroundColor Cyan
