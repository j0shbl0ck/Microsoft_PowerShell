<#
.SYNOPSIS
    This script will bulk add a user to multiple shared mailboxes in Exchange Online with FullAccess and Send As permissions.
.NOTES
    Author: Josh Block
    Date: 08.14.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
#>

# Connect to Exchange Online
Connect-ExchangeOnline -ShowBanner:$false
# Prompt for the user's email address
$user = Read-Host "Enter the email address to assign permissions"

# Define the shared mailboxes
$sharedMailboxes = @(
    "CLSE",
    "CLSB",
    "CLSA",
    "CLSF",
    "CLSF",
    "CLSA",
    "CLS-Team A",
    "CLSX",
    "CLSV"
)

# Loop through each mailbox and assign permissions
foreach ($mailbox in $sharedMailboxes) {
    # Grant FullAccess with automapping
    Add-MailboxPermission -Identity $mailbox -User $user -AccessRights FullAccess -InheritanceType All -AutoMapping $true

    # Grant Send As
    Add-RecipientPermission -Identity $mailbox -Trustee $user -AccessRights SendAs -Confirm:$false

    Write-Host "Granted FullAccess (AutoMapping: True) and Send As to $user for $mailbox"
}

# Disconnect session
Disconnect-ExchangeOnline -Confirm:$false
