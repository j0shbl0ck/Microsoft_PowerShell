<#
.SYNOPSIS
    This script designates a user to have full access to a mailbox without a license.
.NOTES
    Author: Josh Block
    Date: 04.28.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/Office365/comments/1k5xu5b/office_365_global_admin_hacked_with_mfa_enabled
#>

Clear-Host

# Connect to Exchange Online via Entra Id
Function Connect_Exo{
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
}

Connect_Exo

Use the following command to grant the global admin access to the target mailbox:

Add-MailboxPermission -Identity user@domain.com -User gadmin@domain.com -AccessRights FullAccess -InheritanceType All

While logged into the global admin account, use this URL to open the mailbox:

https://outlook.office.com/mail/user@domain.com

When finished, use the following command to remove the access permissions:

Remove-MailboxPermission -Identity user@domain.com -User gadmin@domain.com -AccessRights FullAccess -InheritanceType All