
<#
.SYNOPSIS
    This adds owners to every distrubition list in the tenant. 
.NOTES
    Author: Josh Block
    Date: 08.24.22
    Type: Public
    Version: 1.0.1
.LINK
    https://github.com/j0shbl0ck
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
    Set-DistributionGroup -Identity $group.name -ManagedBy  @{Add='bob','brad'}
}

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
Disconnect-ExchangeOnline -Confirm:$false
Write-Host -ForegroundColor Green 'Done.'
Write-host ""
