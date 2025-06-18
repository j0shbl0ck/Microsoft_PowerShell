<#
.SYNOPSIS
    This script shows the identity of the mailbox recipent. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 01.13.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
.LINK
    Source: N/A
#>

# ======= VARIABLES ======= #
Connect-ExchangeOnline
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to view inbox identity of'
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Retrives mailbox type and user connected with it. 
Get-EXORecipient -Identity $mainuser -ErrorAction Stop

# Terminates Exchange Online PS Session
Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false

Pause
