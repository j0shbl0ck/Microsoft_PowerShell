<#
.SYNOPSIS
    This script designates a user to have full access to a mailbox without a license.
.NOTES
    Author: Josh Block
    Date: 04.28.25
    Type: Public
    Version: 1.0.1
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

# Get the mailbox to connect to
$mailbox = Read-Host -Prompt "Enter the mailbox to access:"

# Get user connecting to the mailbox
$user = Read-Host -Prompt "Enter user accessing the mailbox:"

Function Connect_Mailbox{
    try {
        # Add the user to the mailbox
        Add-MailboxPermission -Identity $mailbox -User $user -AccessRights FullAccess -InheritanceType All
        Write-Host -ForegroundColor Green "Added $user to $mailbox."

        # Output mailbox URL acess
        $mailboxUrl = "https://outlook.office.com/mail/$mailbox"
        Write-Host -ForegroundColor Green "Access the mailbox at: $mailboxUrl"
    } catch {
        Write-Host "Failed to add user to mailbox. Ending script." -ForegroundColor Red
        exit
    }
}

Function Disconnect_Mailbox{
    try {
        # Ask user to type "disconnect" to remove mailbox access. allow upper and lowercase
        $disconnect = Read-Host -Prompt "Type 'disconnect' to remove mailbox access:"
        if ($disconnect -eq "disconnect" -or $disconnect -eq "Disconnect") {
            # Get the mailbox to disconnect from
            $mailbox = Read-Host -Prompt "Enter the mailbox to disconnect from:"

            # Get user to remove from the mailbox
            $user = Read-Host -Prompt "Enter user to remove from the mailbox:"

            # Remove the user from the mailbox
            Remove-MailboxPermission -Identity $mailbox -User $user -AccessRights FullAccess -InheritanceType All
            Write-Host -ForegroundColor Green "Removed $user from $mailbox."
        } else {
            Write-Host "Invalid input. Ending script." -ForegroundColor Red
            exit
        }
    } catch {
        Write-Host "Failed to remove user from mailbox. Ending script." -ForegroundColor Red
        exit
    }
}

Function Diconnect_Exo{
    try {
        Write-Host -ForegroundColor Yellow 'Disconnecting from Exchange Online...'
        
        # Disconnect from Exchange Online
        Disconnect-ExchangeOnline -Confirm:$false | Clear-Host
        
        Write-Host -ForegroundColor Green 'Disconnected from Exchange Online.'
        Write-Host ""
    }
    catch {
        Write-Host "Failed to disconnect from Exchange Online. Ending script." -ForegroundColor Red
        exit
    }   
}

Connect_Exo
Connect_Mailbox
Disconnect_Mailbox
Diconnect_Exo