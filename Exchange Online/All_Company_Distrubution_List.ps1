<#
.SYNOPSIS
    This script gets every user excluding unlicensed and external then adds them to an all company list.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 04.14.22
    Type: Public
.EXAMPLE
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    Username can vary on whether authenticating against domain or Azure AD. flast or firstlast@domain.com
.LINK
    https://social.technet.microsoft.com/Forums/ie/en-US/a48b455e-0114-424f-8b0f-a8c0b88dfb0f/exchange-powershell-loop-through-all-usersmailboxes-and-run-an-exchange-command-on-the-mailbox?forum=winserverpowershell
    https://medium.com/@writeabednego/bulk-create-and-add-members-to-distribution-lists-and-shared-mailboxes-using-powershell-89f5ef6e1362
#>


# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Connect to Microsoft Online
Connect-MsolService

# Create all company distrubition list.
New-DistributionList -Name "AllCompany" -Type "Distribution" 

# Get all users excluding unlicensed and external
Get-MsolUser -All | 
    Where-Object {($_.UserPrincipalName -notlike "*EXT*") -and ($_.isLicensed -eq $true)} |
    Select-Object DisplayName,UserPrincipalName |
    Sort-Object DisplayName


# For each user add to all company list.
$user | ForEach-Object {
    Add-DistributionListMember -DistributionList "AllCompany" -Member $_.UserPrincipalName
}