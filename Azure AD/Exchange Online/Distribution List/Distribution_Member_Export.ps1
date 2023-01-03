<#
.SYNOPSIS
    Export distrubtion group with members in CSV. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.4
    Date: 01.04.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    
.LINK
    Source: https://www.datarepairtools.com/blog/export-office-365-distribution-group-members-list-to-csv/
#>


# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host

# Get Distrubution Group Email
$groupemail = Read-Host -Prompt "Enter the email of the distrubution group"

# Exportation section of the script
Write-Host -ForegroundColor Yellow "Creating $groupname CSV file..."
$groupname = Get-DistributionGroup -Identity $groupemail | Select-Object Name
Get-DistributionGroupMember -Identity $groupemail | Select-Object Name, PrimarySmtpAddress | Export-CSV "$($env:USERPROFILE)\Desktop\$groupname.csv"  -NoTypeInformation -ErrorAction Stop

Write-Host -ForegroundColor Green "Complete! Document found at Desktop\${groupname}.csv"


# Terminates Exchange Online PS Session
Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Cyan
Write-Host ""
Disconnect-ExchangeOnline -Confirm:$false

Break
