<#
.SYNOPSIS
    This forcefully beings the cycle of archiving email out of the primary mailbox for those using Exchange Online Archiving.
.NOTES
    Author: Josh Block
    Date: 10.25.22
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/microsoft-365/compliance/enable-archive-mailboxes?source=recommendations&view=o365-worldwide
    https://www.clouddirect.net/knowledge-base/KB0011641/using-office-365-online-archiving-and-retention-policies
    https://automatica.com.au/2018/03/force-exchange-online-archiving-to-start-archiving-email-on-office-365/
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Write-Host -ForegroundColor Cyan 'Connecting to Exchange Online...'
Connect-ExchangeOnline
Write-host ""


# ======= VARIABLES ======= #
$mainuser = Read-Host -Prompt 'Input user (username@domain.com) to view inbox identity of'
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Retrives mailbox type and user connected with it. 
Start-ManagedFolderAssistant -Identity $mainuser -ErrorAction Stop