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
    Source: https://theitbros.com/add-calendar-permissions-in-office-365-via-powershell/
    Source: https://community.spiceworks.com/topic/2319204-o365-calendar-sharing-with-powershell 
.EXAMPLE
    Add-MailboxFolderPermission -Identity firstuser@domain.com:\calendar -user seconduser@domain.com -AccessRights Owner
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