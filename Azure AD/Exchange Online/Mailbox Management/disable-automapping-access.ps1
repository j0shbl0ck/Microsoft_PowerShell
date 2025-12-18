<#
.SYNOPSIS
    This script disables automapping and refreshes Send As permissions
    by removing and re-adding Full Access and Send As rights on a shared mailbox.
.NOTES
    Author: Josh Block
    Date: 09.04.25
    Type: Public
    Version: 1.1.0
.LINK
    https://github.com/j0shbl0ck
#>

# Connect to Exchange Online
Connect-ExchangeOnline -ShowBanner:$false

# Prompt for user input
$delegate = Read-Host "Enter the delegate's email address"
$sharedMailbox = Read-Host "Enter the shared mailbox email address"

Write-Host "Removing existing permissions..." -ForegroundColor Yellow

# Remove Full Access
Remove-MailboxPermission `
    -Identity $sharedMailbox `
    -User $delegate `
    -AccessRights FullAccess `
    -Confirm:$false `
    -ErrorAction SilentlyContinue

# Remove Send As
Remove-RecipientPermission `
    -Identity $sharedMailbox `
    -Trustee $delegate `
    -AccessRights SendAs `
    -Confirm:$false `
    -ErrorAction SilentlyContinue

Start-Sleep -Seconds 3

Write-Host "Re-adding permissions..." -ForegroundColor Yellow

# Re-add Full Access with AutoMapping disabled
Add-MailboxPermission `
    -Identity $sharedMailbox `
    -User $delegate `
    -AccessRights FullAccess `
    -AutoMapping:$false

# Re-add Send As
Add-RecipientPermission `
    -Identity $sharedMailbox `
    -Trustee $delegate `
    -AccessRights SendAs `
    -Confirm:$false

Write-Host "Permissions refreshed successfully." -ForegroundColor Green
Write-Host "Full Access (AutoMapping disabled) and Send As have been re-applied for $delegate on $sharedMailbox."
