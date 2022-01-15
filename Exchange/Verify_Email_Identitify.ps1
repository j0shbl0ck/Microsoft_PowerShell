<#
.SYNOPSIS
    This script shows the identity of the mailbox recipent. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.13.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
.LINK
    Source: N/A
#>

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to view calendar permissions of'
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin 

# Retrives mailbox type and user connected with it. 
Get-EXORecipient -Identity $mainuser -ErrorAction Stop

# Terminates Exchange Online PS Session
Write-Host 'Terminating Exchange Online PS Session...' -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false

Pause
