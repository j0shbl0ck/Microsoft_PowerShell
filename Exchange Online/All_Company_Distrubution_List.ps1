<#
.SYNOPSIS
    This script gets every user excluding unlicensed and external then adds them to an all company list.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.5
    Date: 04.14.22
    Type: Public
.EXAMPLE
.NOTES
    You will need to have MSOnline PowerShell module [ Install-Module -Name MSOnline ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    You will need to sign in twice for each Azure connection.
    After distribution list is created, check online for the distribution list name and possible primary email address change.
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
New-DistributionGroup -Name "AllCompany" -Type "Distribution" 
Write-Host ""
Write-Host "Primary Smtp Address can be changed online if current domain name not desired." -ForegroundColor Yellow

# Get all users excluding unlicensed and external
$user = Get-MsolUser -All | 
    Where-Object {($_.UserPrincipalName -notlike "*EXT*") -and ($_.isLicensed -eq $true)} |
    Select-Object UserPrincipalName


# For each user add to all company list.
$user | ForEach-Object {
    Add-DistributionGroupMember -Identity "AllCompany" -Member $_.UserPrincipalName
}

Write-Host "All members of company list below:" -ForegroundColor Cyan

# Show members of all company list.
Get-DistributionGroupMember -Identity "AllCompany" | 
    Select-Object DisplayName, PrimarySmtpAddress |
    Sort-Object DisplayName, PrimarySmtpAddress |
    Format-Table -AutoSize 

# In green, show success
Write-Host "Distribution group created successfully" -ForegroundColor Green

# Pause script
Pause

# In purple, show script end
Write-Host "Script ended" -ForegroundColor Magenta

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false