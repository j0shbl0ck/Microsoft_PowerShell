<#
.SYNOPSIS
    Looks up what unified groups (Microsoft 365 Groups) a user is a member of. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
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
$unifigroups = Get-UnifiedGroup

foreach ($unifigroup in $unifigroups) {
    try {
        # get members of distribution group 
        $members = Get-UnifiedGroupLinks -Identity $unifigroup -LinkType Members -ErrorAction SilentlyContinue | Select-Object PrimarySmtpAddress
        # loop through members of distribution group
        foreach ($member in $members) {
            # if the member is the user we are looking for
            if ($member.PrimarySmtpAddress -eq $UserPrincipalName) {
                # write the distribution group email address to the screen
                $Result= @()
                $UGEmail = $unifigroup.PrimarySmtpAddress
                $UGName = $unifigroup.DisplayName
                $Result=New-Object PsObject -Property @{'M365 Group Email Name'=$UGName;'M365 Group Email Address'=$UGEmail;} 
                $Result | Select-Object 'M365 Group Email Name','M365 Group Email Address' | Format-Table -AutoSize
            }
            else {
                # continue script
            }
        }  
    }
    catch {
        Write-Error "Something went wrong." -ErrorAction SilentlyContinue   
    }
}