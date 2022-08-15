<#
.SYNOPSIS
    This adds members to a distrubtion list via CSV.
.NOTES
    Author: Josh Block
    Date: 07.21.22
    Type: Public
    Version: 1.0.9
.LINK
    https://github.com/j0shbl0ck
    https://social.technet.microsoft.com/wiki/contents/articles/54249.365-add-members-in-distribution-list-using-powershell-and-csv-list-file.aspx
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Cyan 'Connecting to Exchange Online...'
Connect-ExchangeOnline
Write-Host -ForegroundColor Green 'Connected to Exchange Online!'
Write-host ""

# Ask user for file path to .CSV
Write-Host -ForegroundColor Yellow 'Please enter the path (no quotes around path) to the .CSV file:'
# Check if file exists if not ask user to try again
do {
    $filePath = Read-Host
    $validatefile = Test-Path -Path $filePath
    if ($validation -eq $False){
        Write-Host -ForegroundColor Red 'File does not exist. Please try again.'
    }
} until ($validatefile -eq $True)

# Import .CSV file
Write-Host -ForegroundColor Yellow 'Importing .CSV file...'
Write-Host -ForegroundColor Green 'Import complete!'
Write-host ""

# Ask user for Distribution List email address
Write-Host -ForegroundColor Yellow 'Please enter the email address (no quotes around email) of the Distribution List:'
$distList = Read-Host
Write-Host -ForegroundColor Green 'Distribution List email address entered.'
Write-host ""

# Perform the add members operation
Write-Host -ForegroundColor Yellow 'Adding members to distribution list...'
Import-CSV $filePath | ForEach-Object {Add-DistributionGroupMember -Identity $distList -Member $_.Name}
Write-Host -ForegroundColor Green 'Members successfully added!'
Write-host ""

# Get the distribution list members
Write-Host -ForegroundColor Yellow 'Getting distribution list members...'
Get-DistributionGroupMember -Identity $distList | Format-Table -AutoSize
Write-Host -ForegroundColor Green 'Distribution list members retrieved!'

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
Disconnect-ExchangeOnline
Write-Host -ForegroundColor Green 'Done.'
Write-host ""



