<#
.SYNOPSIS
    This creates a sweep rule made to move emails within folders around to other folders.
.NOTES
    Author: Josh Block
    Date: 01.08.23
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://social.technet.microsoft.com/wiki/contents/articles/54249.365-add-members-in-distribution-list-using-powershell-and-csv-list-file.aspx
#>

Clear-Host

# Ask user for Global/Exchange Admin UPN
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 

# Ask user for of who's mailbox is to be edited
$mbx = Read-Host -Prompt 'Input mailbox to be edited (someone@domain.com)'

# Ask user for the name of the sweep rule
Write-Host ""
$rule = Read-Host -Prompt 'Input name of sweep rule'

# Ask user for the sender of the sweep rule
Write-Host ""
$senderx = Read-Host -Prompt 'Input sender of sweep rule (someone@domain.com)'

# Ask user for the source folder to be swept
Write-Host ""
Write-Warning "email variable should be formated as, user@domain.com"
$src = Read-Host -Prompt 'Input source folder to be swept (email:\Inbox or email:\Deleted Items or email:\Sent Items)'

# Ask user for the destination folder to be swept
Write-Host ""
Write-Warning "email variable should be formated as, user@domain.com"
$dst = Read-Host -Prompt 'Input destination folder to be swept (email:\Inbox\ABC or email:\Deleted Items\ABC or email:\ABC)'

# Ask user for the number of days to keep the sweep rule
Write-Host ""
$days = Read-Host -Prompt "Input number of days to keep sweep rule (1-30)"

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host

#  creates a new Sweep rule named "Deleted Khols" in Rita's mailbox that moves messages from Khols in the Deleted folder to the Khols folder.
New-SweepRule -Name $rule -Mailbox $mbx -Provider Exchange16 -Sender $senderx -SourceFolder $src -DestinationFolder $dst -KeepForDays $days

# Disconnect from Exchange Online
Write-Host -ForegroundColor Yellow "Disconnecting from Exchange Online..."
Disconnect-ExchangeOnline -Confirm:$false
Write-Host -ForegroundColor Green 'Complete.'
Write-host ""
