<#
.SYNOPSIS
    Looks up what distribution lists a user is a member of. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 11.01.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    
.LINK
    Source: https://o365reports.com/2022/04/19/list-all-the-distribution-groups-a-user-is-member-of-using-powershell/
    Source: https://social.technet.microsoft.com/Forums/ie/en-US/08bb68fd-5116-427c-869b-3f8686d5d904/list-of-all-distribution-lists-that-one-user-is-a-member-of-powershell
#>

Clear-Host

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 
$mainuser = Read-Host -Prompt 'Input User (enduser@domain.com) to view calendar permissions of'
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin 