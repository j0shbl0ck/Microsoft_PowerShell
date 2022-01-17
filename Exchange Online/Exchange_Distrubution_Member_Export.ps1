<#
.SYNOPSIS
    Export distrubtion group with members in CSV. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 01.04.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    
.LINK
    Source: https://www.datarepairtools.com/blog/export-office-365-distribution-group-members-list-to-csv/
#>

# Change UPN to your Global/Exchange admin account.
Connect-ExchangeOnline

# Get Distrubution Group Email
$groupname = Read-Host -Prompt "Enter the email of the distrubution group"

# Exportation section of the script
Write-Host -ForegroundColor Yellow "Creating ${groupname} CSV file..."
Get-DistributionGroupMember -Identity $groupname | Select-Object Name, PrimarySmtpAddress | Export-CSV "$($env:USERPROFILE)\Desktop\$groupname.csv"  -NoTypeInformation -ErrorAction Stop
Write-Host -ForegroundColor Green "Complete! Document found at Desktop\${groupname}.csv"

# Terminates Exchange Online PS Session
Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Cyan
Write-Host ""
Disconnect-ExchangeOnline -Confirm:$false

Pause
