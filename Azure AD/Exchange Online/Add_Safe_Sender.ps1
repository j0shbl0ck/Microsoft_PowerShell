
<#
.SYNOPSIS
    This adds a specified domain or email address to a user's safe sender list. 
.NOTES
    Author: Josh Block
    Date: 01.17.23
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailboxjunkemailconfiguration?view=exchange-ps
    https://o365info.com/manage-safe-senders-block-sender-lists-using-powershell-office-365/
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange Admin Center credentials
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
    
    # Connect to Exchange Online
    Connect-ExchangeOnline | Clear-Host
    
    Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
    exit
}

# Get User
$user = Read-Host -Prompt 'Enter user email to modify safe sender list (user@domain.com)'

# Get the first addition
$addition01 = Read-Host -Prompt 'Enter either domain or email address to add to SSL'

# Ask if there is another additional they'd like to add
$addMore = Read-Host -Prompt 'Do you want to add another item? (Y/N)'

# Check if user wants to add more items
while ($addMore -eq 'Y') {
    $additionalItem = Read-Host -Prompt 'Enter another domain or email address'
    "$addition01 += ",$additionalItem"
    $addMore = Read-Host -Prompt 'Do you want to add another item? (Y/N)'
}

# Format additions as hashtable for Set-MailboxJunkEmailConfiguration
$trustedSendersAndDomains = @{ Add = $addition01 }

# Add additions to trusted senders and domains
Set-MailboxJunkEmailConfiguration -Identity $user -TrustedSendersAndDomains $trustedSendersAndDomains

Write-Host "Safe sender list updated for $user with: $addition01" -ForegroundColor Green

