<#
.SYNOPSIS
    This script updates the specific members and groups who are already to send to a mail-enabled security group.
.NOTES
    Author: Josh Block
    Date: 06.12.24
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/exchangeserver/comments/16uhow2/user_cannot_send_as_mailenabled_security_group/

#>


Clear-Host

Write-Host -ForegroundColor Magenta "You will be modifying the mail-enabled sec group, to allow 'Send To' permissions for the sender mailbox"

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

# Get receipient mailbox

Function Updte_MESG {
    # Input Receipient mailbox
    $rcptmb = Read-Host "Enter emailAddress of Receipient Mailbox"
    $sndrsg = Read-Host "Enter emailAddress of Sender DL"

    # Update Receipient Mailbox to allow Sender to 
    Set-DistributionGroup -Identity $sndrsg -AcceptMessagesOnlyFrom @{Add=$rcptmb}
    Get-DistributionGroup -Identity $sndrsg -IncludeAcceptMessagesOnlyFromWithDisplayNames
}

Connect_Exo
Updte_MESG