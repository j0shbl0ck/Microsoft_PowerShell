<#
.SYNOPSIS
    This script allows you to view all mailbox sizes in your tenant.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 12.05.22
    Type: Public
.NOTES

.LINK
    Source: https://m365scripts.com/exchange-online/get-mailbox-details-in-microsoft-365-using-powershell/
#>

Clear-Host

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com): ' 
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host


Get-Mailbox -ResultSize Unlimited | ForEach-Object { Get-MailboxStatistics -identity $_.userprincipalName | Select-Object Displayname,TotalItemSize | Format-Table Displayname,TotalItemSize}| Format-Table Displayname,TotalItemSize