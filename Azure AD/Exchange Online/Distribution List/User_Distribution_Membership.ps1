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
$UserPrincipalName = Read-Host -Prompt 'Input User (enduser@domain.com) to view calendar permissions of'
$Filter = "Members -Like ""$UserPrincipalName"""
#$seconduser = seconduser@domain.com
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Import-Module ExchangeOnlineManagement
Write-Host Connecting to Exchange Online...
Connect-ExchangeOnline -UserPrincipalName $gadmin 

# Get all Distribution Groups to search through filtering by the user
$distrigroups = Get-DistributionGroup -ResultSize Unlimited -Filter $Filter
$GroupCount=$distrigroups | Measure-Object | Select-Object count
Write-Progress -Activity "Find Distribution Lists that user is a member" -Status "Processed User Count: $Global:ProcessedUserCount" -CurrentOperation "Currently Processing in  $UserPrincipalName"

# Loop through each Distribution Group
If($GroupCount.count -ne 0)
    {    
        $DLsCount=$GroupCount.count
        $DLsName=$distrigroups.Name
        $DLsEmailAddress=$distrigroups.PrimarySmtpAddress
    }
    Else
    {
        $DLsName="-"
        $DlsEmailAddress="-"
        $DLsCount='0'
    }
$Result=New-Object PsObject -Property @{'User Principal Name'=$UserPrincipalName;'User Display Name'=$UserDisplayName;'No of DLs that user is a member'=$DLsCount;'DLs Name'=$DLsName -join ',';'DLs Email Adddress'=$DLsEmailAddress -join ',';} 
$Result|Select-Object 'User Principal Name','User Display Name','No Of DLs That User Is A Member','DLs Name','DLs Email Adddress'
$Global:ProcessedUserCount++