<#
.SYNOPSIS
    This script performs a content search, then using the search will purge emails from all mailboxes
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.10.24
    Type: Public
.EXAMPLE
.NOTES
    You will need to have MSOnline PowerShell module [ Install-Module -Name MSOnline ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    You will need to sign in twice for each Azure connection.
    After distribution list is created, check online for the distribution list name and possible primary email address change.
.LINK
    https://social.technet.microsoft.com/Forums/ie/en-US/a48b455e-0114-424f-8b0f-a8c0b88dfb0f/exchange-powershell-loop-through-all-usersmailboxes-and-run-an-exchange-command-on-the-mailbox?forum=winserverpowershell
    https://medium.com/@writeabednego/bulk-create-and-add-members-to-distribution-lists-and-shared-mailboxes-using-powershell-89f5ef6e1362
#>

# Create menu that allows a user to create the content search, then also start a search action, then lastly check on a search action.

Connect-IPPSSession

$name = 'ICONS Suppport Spam 04'
$subject = "Please review for possible solutions to your support request"
$searchsubject = '(From:' + $subject + ')'
$contentmatch = $searchsubject


$search=New-ComplianceSearch -Name "ICONS Suppport Spam 05" -ExchangeLocation All -ContentMatchQuery '(Subject:ICONS)'
Start-ComplianceSearch -Identity $Search.Identity
New-ComplianceSearchAction -SearchName $name -Purge -PurgeType HardDelete -Confirm:$false -Force


Support@firstcolumn.com

Please review for possible solutions to your support request

ICONS


Get-ComplianceSearchAction -identity “ICONS Suppport Spam 02_purge”


$search=New-ComplianceSearch -Name "ICONS Suppport Spam 04" -ExchangeLocation All -ContentMatchQuery '(From:Support@firstcolumn.com)'
>> Start-ComplianceSearch -Identity $Search.Identity
PS C:\WINDOWS\system32> New-ComplianceSearchAction -SearchName "ICONS Suppport Spam 04" -Purge -PurgeType HardDelete -Confirm:$false -Force