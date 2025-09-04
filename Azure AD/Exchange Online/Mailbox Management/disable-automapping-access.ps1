<#
.SYNOPSIS
    This script disables automapping for a mailbox by removing and re-adding Full Access permissions with AutoMapping set to false.
.NOTES
    Author: Josh Block
    Date: 09.04.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
#>

# Connect to Exchange Online
Connect-ExchangeOnline -ShowBanner:$false

# Prompt for user input
$delegate = Read-Host "Enter the delegate's email (who has Full Access)"
$sharedMailbox = Read-Host "Enter the shared mailbox email"

# Remove Full Access permission
Remove-MailboxPermission -Identity $sharedMailbox -User $delegate -AccessRights FullAccess -Confirm:$false

# Re-add Full Access permission with automapping disabled
Add-MailboxPermission -Identity $sharedMailbox -User $delegate -AccessRights FullAccess -AutoMapping:$false

Write-Host "Automapping has been disabled for $delegate on $sharedMailbox"