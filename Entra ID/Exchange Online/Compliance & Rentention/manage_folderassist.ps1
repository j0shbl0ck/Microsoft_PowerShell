<#
.SYNOPSIS
    This provides troubleshooting one-line scripts for Exchange Online Archive Mailboxes.
.NOTES
    Author: Josh Block
    Date: 05.05.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/exchangeserver/comments/125pc5s/exchange_online_managed_folder_assistant_error_log/
    https://community.spiceworks.com/t/custom-mrm-policy-not-working/936280/5
#>

# Check status
$Log = Export-MailboxDiagnosticLogs -Identity user@domain.com -ExtendedProperties
$xml = [xml]($Log.MailboxLog)
$xml.Properties.MailboxTable.Property | ? {$_.Name -like "Elc*"}

# Check RententionHold and ElcProcessingDisabled, if RHEnabled, then the mailbox is true the MRM policy will not apply.
Get-Mailbox user@domain.com | select RetentionHoldEnabled,ElcProcessingDisabled
Set-Mailbox user@domain.com -RetentionHoldEnabled $false

Start-ManagedFolderAssistant -Identity user@deomain.com
