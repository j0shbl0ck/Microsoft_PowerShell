<#
.SYNOPSIS
    This adds members to a distrubtion list via CSV.
.NOTES
    Author: Josh Block
    Date: 07.21.22
    Type: Public
    Version: 1.0.2
.LINK
    https://github.com/j0shbl0ck
    https://social.technet.microsoft.com/wiki/contents/articles/54249.365-add-members-in-distribution-list-using-powershell-and-csv-list-file.aspx
#>


# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
Connect-ExchangeOnline
Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
Write-host ""

# Ask user for file path to .CSV
Write-Host -ForegroundColor Yellow 'Please enter the path (no quotes around path) to the .CSV file:'
$filePath = Read-Host
Write-Host -ForegroundColor Green 'File path entered.'
Write-host ""

# Import .CSV file
Write-Host -ForegroundColor Yellow 'Importing .CSV file...'
Write-Host -ForegroundColor Green 'Import complete.'
Write-host ""

# Ask user for Distribution List email address
Write-Host -ForegroundColor Yellow 'Please enter the email address (no quotes around email) of the Distribution List:'
$distList = Read-Host
Write-Host -ForegroundColor Green 'Distribution List email address entered.'
Write-host ""

# Perform the add members operation
Write-Host -ForegroundColor Yellow 'Adding members to distribution list...'
Import-CSV $filePath | ForEach-Object {Add-DistributionGroupMember -Identity $distList -Member $_.Name}
Write-Host -ForegroundColor Green 'Members added to distribution list.'
Write-host ""

# Get the distribution list members
Write-Host -ForegroundColor Yellow 'Getting distribution list members...'
Get-DistributionGroupMember -Identity $distList

# Give user a chance to see the results
Write-Host -ForegroundColor Yellow 'Press any key to exit...'
Read-Host
Write-Host -ForegroundColor Green 'Exiting...'

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
Disconnect-ExchangeOnline
Write-Host -ForegroundColor Green 'Done.'
Write-host ""


