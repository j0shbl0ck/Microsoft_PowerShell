<#
.SYNOPSIS
    This gets all integrated apps in Exchange Online.
.NOTES
    Author: Josh Block
    Date: 04.21.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/microsoft-365/enterprise/use-the-centralized-deployment-powershell-cmdlets-to-manage-add-ins?view=o365-worldwide#get-details-of-an-add-in
    https://learn.microsoft.com/en-us/powershell/module/exchange/get-app?view=exchange-ps
    https://community.spiceworks.com/t/cant-remove-office-365-integrated-app-add-in/929425
#>


Clear-Host

# Connect to Exchange Online via Entra Id
Function Connect_Exo{
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
}

Connect_Exo

# Get all integrated apps in Exchange Online
Get-App -OrganizationApp | Format-List DisplayName,AppID

# Ask to remove integrated apps
$remove = Read-Host "Do you want to remove any integrated apps? (Y/N)"
if ($remove -eq "Y") {
    $appId = Read-Host "Enter the App ID of the integrated app you want to remove"
    try {
        Remove-App -AppId $appId -Confirm:$false
        Write-Host "Integrated app with App ID $appId removed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to remove integrated app with App ID $appId." -ForegroundColor Red
    }
} else {
    Write-Host "No integrated apps were removed." -ForegroundColor Yellow
}

Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Disconnected from Exchange Online." -ForegroundColor Green

