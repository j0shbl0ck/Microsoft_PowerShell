<#
.SYNOPSIS
    This creates imports contacts via CSV.
.NOTES
    Author: Josh Block
    Date: 08.18.22
    Type: Public
    Version: 1.0.1
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

Import-CSV $filePath | ForEach-Object {      
    $Name=$_Name  
    $ExternalEmailAddress=$_.ExternalEmailAddress    
    Write-Progress -Activity "Creating contact $ExternalEmailAddress in Office 365..."     
    New-MailContact -Name $Name -ExternalEmailAddress $ExternalEmailAddress | Out-Null 
    If($?)      
    {      
     Write-Host $ExternalEmailAddress Successfully created -ForegroundColor Green     
    }      
    Else      
    {      
     Write-Host $ExternalEmailAddress - Error occurred -ForegroundColor Red     
    }      
}