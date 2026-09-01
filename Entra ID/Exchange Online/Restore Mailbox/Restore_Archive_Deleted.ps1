
https://stackoverflow.com/questions/68106483/recover-items-in-a-users-online-archive-from-there-recoverable-items


Get-Mailbox -Identity user@domain.com -RecipientTypeDetails UserMailbox | Select-Object UserPrincipalName,ExchangeGuid

$ArchiveGuid = (Get-Mailbox -Identity user@domain.com -RecipientTypeDetails UserMailbox).ArchiveGuid

Write-Host $ArchiveGuid


Restore-RecoverableItems -Identity "$GuidSource" -ResultSize "unlimited" -SourceFolder RecoverableItems


Get-RecoverableItems -identity "$GuideSource" | Restore-RecoverableItems


Set-MailboxPermission -Identity "user@domain.com" -User username -AccessRights FullAccess -InheritanceType All -Automapping $true