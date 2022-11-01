<#
.SYNOPSIS
    Looks up what distribution lists a user is a member of. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 11.01.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    
.LINK
    Source: https://o365reports.com/2022/04/19/list-all-the-distribution-groups-a-user-is-member-of-using-powershell/
    Source: https://social.technet.microsoft.com/Forums/ie/en-US/08bb68fd-5116-427c-869b-3f8686d5d904/list-of-all-distribution-lists-that-one-user-is-a-member-of-powershell
    Source: https://community.spiceworks.com/topic/2304588-list-of-all-distribution-lists-that-users-is-a-member-of-in-exch-onprem-online
#>

Clear-Host

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)' 
$UserPrincipalName = Read-Host -Prompt 'Input User (enduser@domain.com) to look up what distribution lists they are a member of'
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Import-Module ExchangeOnlineManagement
Write-Host Connecting to Exchange Online...
Connect-ExchangeOnline -UserPrincipalName $gadmin 

# Get all Distribution Groups to search through filtering by the user
$distrigroups = Get-DistributionGroup -ResultSize Unlimited

foreach ($distrigroup in $distrigroups) {
    $members = Get-DistributionGroupMember
    foreach ($member in $members) {
        if ($member -eq $UserPrincipalName) {
            Write-Host $distrigroup.PrimarySmtpAddress
        }
    }
}

# show the distribution lists that the user is a member of