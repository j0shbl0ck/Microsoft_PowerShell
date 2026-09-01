<#
.SYNOPSIS
    This outputs all Inbox rules, including hidden, and Microsoft built-in rules. 
.NOTES
    Author: Josh Block
    Date: 09.26.23
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailboxjunkemailconfiguration?view=exchange-ps
    https://o365info.com/manage-safe-senders-block-sender-lists-using-powershell-office-365/
#>



Get-InboxRule -Mailbox "b@email.com" -IncludeHidden | Select-Object Name, Enabled, Identity, Description | Format-List


# Get-InboxRule -Mailbox "b@email.com" -IncludeHidden | Remove-InboxRule 

