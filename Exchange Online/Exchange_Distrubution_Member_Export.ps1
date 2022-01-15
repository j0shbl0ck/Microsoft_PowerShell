<#
.SYNOPSIS
    Export distrubtion group with members in CSV. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.04.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
.LINK
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
#>

# Change UPN to your Global/Exchange admin account.
Connect-ExchangeOnline -UserPrincipalName admin@domain.com 

# Change Distrubtion group name to whichever one needing exportation. 
Get-DistributionGroupMember -Identity 'NameOfGroup' | Select-Object Name, PrimarySmtpAddress | Export-csv C:\O365\ExchDist.csv -NoTypeInformation
