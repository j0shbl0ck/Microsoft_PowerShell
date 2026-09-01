<#
.SYNOPSIS
    This enables online archiving and forcefully beings the cycle of archiving email out of the primary mailbox for those using Exchange Online Archiving.
.NOTES
    Author: Josh Block
    Date: 10.25.22
    Type: Public
    Version: 1.0.3
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/microsoft-365/compliance/enable-archive-mailboxes?source=recommendations&view=o365-worldwide
    https://www.clouddirect.net/knowledge-base/KB0011641/using-office-365-online-archiving-and-retention-policies
    https://automatica.com.au/2018/03/force-exchange-online-archiving-to-start-archiving-email-on-office-365/
#>

Clear-Host

Try {
    Connect-ExchangeOnline
    $mainuser = Read-Host -Prompt 'Input user (username@domain.com) to view inbox identity of'

    $mailbox = Get-Mailbox -Identity $mainuser
    if ($null -eq $mailbox.ArchiveName) {
        Enable-Mailbox -Identity $mainuser -Archive
        Start-ManagedFolderAssistant -Identity $mainuser
        Write-Host "$mainuser has an archive mailbox enabled."
    }
    else {
        Write-Host "$mainuser already has an archive mailbox."
        Start-ManagedFolderAssistant -Identity $mainuser
    }
}
Catch {
    Write-Host "An error occurred: $_"
}