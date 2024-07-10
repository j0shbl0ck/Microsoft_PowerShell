<#
.SYNOPSIS
    This creates imports contacts via CSV.
.NOTES
    Author: Josh Block
    Date: 08.18.22
    Type: Public
    Version: 1.0.7
.LINK
    https://github.com/j0shbl0ck
    https://m365scripts.com/exchange-online/bulk-import-contacts-office-365-powershell/#:~:text=Multiple%20contacts%20can%20be%20added,file%20with%20the%20contact%20info.
    https://docs.microsoft.com/en-us/microsoft-365/compliance/bulk-import-external-contacts?view=o365-worldwide
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Cyan 'Connecting to Exchange Online...'
Connect-ExchangeOnline
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
$contacts = Import-CSV $filePath
Write-Host -ForegroundColor Yellow 'Importing .CSV file...'
Write-Host -ForegroundColor Green 'Import complete.'
Write-host ""

# Perform the create distrubution list operation
ForEach ($contact in $contacts){
    Write-Host ""
    Write-Host -ForegroundColor Yellow 'Importing Contact: ' $contact.Name
    New-MailContact -Name $contact.Name -DisplayName $contact.Name -ExternalEmailAddress $contact.ExternalEmailAddress -Confirm:$false
    Write-Host -ForegroundColor Green 'Contact created:' $contact.Name
}

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
Disconnect-ExchangeOnline -Confirm:$false
Write-Host -ForegroundColor Green 'Done.'
Write-host ""