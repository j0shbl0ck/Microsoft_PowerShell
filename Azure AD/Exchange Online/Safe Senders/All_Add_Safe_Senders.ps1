
<#
.SYNOPSIS
    This adds a specified domain or email address to a user's safe sender list. 
.NOTES
    Author: Josh Block
    Date: 02.13.2025
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailboxjunkemailconfiguration?view=exchange-ps
    https://o365info.com/manage-safe-senders-block-sender-lists-using-powershell-office-365/
#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange Admin Center credentials
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

# Get all user mailboxes
$users = Get-EXOMailbox -ResultSize unlimited

# Get all sender email addresses from the specified domains
$senders = "auditmessages.com","bankfraudalerts.com","buildingmgmt.info",
"corporate-realty.co","court-notices.com","e-billinvoices.com","e-documentsign.com",
"e-faxsent.com","e-receipts.co","epromodeals.com","fakebookalerts.live",
"global-hr-staff.com","gmailmsg.com","helpdesk-tech.com","hr-benefits.site",
"it-supportdesk.com","linkedn.co","mail-sender.online","myhr-portal.site","online-statements.site",
"outlook-mailer.com","secure-bank-alerts.com","shipping-updates.com","tax-official.com",
"toll-citations.com","trackshipping.online","voicemailbox.online","awstrack.me",
"sophos-phish-threat.go-vip.co","go-vip.co","staysafe.sophos.com"

# Add the senders to the user's safe sender list
foreach($user in $users){
$out = 'Adding Trusted Senders to {0}' -f $user.UserPrincipalName
Write-Output $out
Set-MailboxJunkEmailConfiguration $user.UserPrincipalName -TrustedSendersAndDomains @{Add=$senders}
}
Write-Output "Finished!"

