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
    # get members of distribution group
    $members = Get-DistributionGroupMember -Identity $distrigroup -ResultSize Unlimited | Select-Object PrimarySmtpAddress
    # loop through members of distribution group
<#     foreach ($member in $members) {
        # if the member is the user we are looking for #>
        if ($members.PrimarySmtpAddress -eq $UserPrincipalName) {
            # write the distribution group email address to the screen
            $Result= @()
            $DLEmail = $distrigroup.PrimarySmtpAddress
            $DLName = $distrigroup.DisplayName
            $Result=New-Object PsObject -Property @{'DL Email Name'=$DLName;'DL Email Address'=$DLEmail;} 
            $Result | Select-Object 'DL Email Name','DL Email Address'
        }
        else {
            Write-Host "User is not a member of $distrigroup"
        }
}
