<#
.SYNOPSIS
    This adds members to a distrubtion list via CSV.
.NOTES
    Author: Josh Block
    Date: 07.21.22
    Type: Public
    Version: 1.2.1
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
Write-Host -ForegroundColor Cyan 'Please enter the path (no quotes around path) to the .CSV file:'
# Check if file exists if not ask user to try again
do {
    $filePath = Read-Host
    $validatefile = Test-Path -Path $filePath
    if ($validation -eq $False){
        Write-Host -ForegroundColor Red 'File does not exist. Please try again.'
    }
} until ($validatefile -eq $True)

# Import .CSV file
$members = Import-CSV $filePath
Write-Host -ForegroundColor Yellow 'Importing .CSV file...'
Write-Host -ForegroundColor Green 'Import complete.'
Write-host ""

# Ask user for Distribution List email address
Write-Host -ForegroundColor Cyan 'Please enter the email address (no quotes around email) of the Distribution List:'
$distList = Read-Host
Write-Host -ForegroundColor Green 'Distribution List email address entered.'
Write-host ""

# Perform the add members to distrubution list operation
ForEach ($member in $members){
    Write-Host ""
    Write-Host -ForegroundColor Yellow 'Importing member: ' $member.Name
    Add-DistributionGroupMember -Identity $distList -Member $member.ExternalEmailAddress -Confirm:$false
    Write-Host -ForegroundColor Green 'Member added:' $member.ExternalEmailAddress
    Write-Host ""
}

# Get the distribution list members
Write-Host -ForegroundColor Green 'Successfully added distribution list members:'
Get-DistributionGroupMember -Identity $distList | Select-Object DisplayName,PrimarySMTPAddress | Format-Table -AutoSize

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
Disconnect-ExchangeOnline -Confirm:$false
Write-Host -ForegroundColor Green 'Done.'
Write-host ""
