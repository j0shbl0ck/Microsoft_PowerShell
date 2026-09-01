
<#
.SYNOPSIS
    This adds owner(s) to every distrubition list in the tenant. 
.NOTES
    Author: Josh Block
    Date: 08.24.22
    Type: Public
    Version: 1.0.2
.LINK
    https://github.com/j0shbl0ck
    https://o365info.com/manage-distribution-group-using-powershell-in-office-365-creating-and-managing-distribution-groups-part-2-5/
    https://docs.microsoft.com/en-us/powershell/module/exchange/set-distributiongroup?view=exchange-ps
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Cyan 'Connecting to Exchange Online...'
Connect-ExchangeOnline
Write-host ""

# Set Distribution list variable
$groups = Get-DistributionGroup


# For each distribution list in the tenant, add the specified owners.
ForEach ($group in $groups) 
{
    Write-Host -ForegroundColor Cyan 'Adding owners to distribution list: ' $group.name
    Set-DistributionGroup -Identity $group.name -ManagedBy  @{Add='user@contoso.com','usertwo@contoso.com'}
}

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
Disconnect-ExchangeOnline -Confirm:$false
Write-Host -ForegroundColor Green 'Done.'
Write-host ""
