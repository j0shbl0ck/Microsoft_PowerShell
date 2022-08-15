<#
.SYNOPSIS
    This creates multiple distrubution lists via CSV.
.NOTES
    Author: Josh Block
    Date: 08.15.22
    Type: Public
    Version: 1.0.0
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
Write-Host -ForegroundColor Green 'Import complete.'
Write-host ""

---------

# Ask user for Distribution List email address
Write-Host -ForegroundColor Yellow 'Please enter the email address (no quotes around email) of the Distribution List:'
$distList = Read-Host
Write-Host -ForegroundColor Green 'Distribution List email address entered.'
Write-host ""

# Perform the create distrubution list operation
Write-Host -ForegroundColor Yellow 'Creating distribution lists...'
Import-CSV $filePath | ForEach-Object {New-DistributionGroup -Name $_.Name -Alias $_.Alias -PrimarySmtpAddress $_.Email -DisplayName $_.Name}
Write-host ""

