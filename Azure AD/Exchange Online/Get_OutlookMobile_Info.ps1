
<#
.SYNOPSIS
    This gets all users utilizing email on their phone and the app they are using.
.NOTES
    Author: Josh Block
    Date: 12.31.24
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://community.spiceworks.com/t/get-mobiledevice-with-get-user/763353
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange Admin Center credentials
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
    
    # Connect to Exchange Online
    Connect-ExchangeOnline | Clear-Host
    
    Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
    exit
}

# Get all users with mobile devices
Get-Mobiledevice | Select-Object userdisplayname,devicetype,DeviceModel