<#
    .NOTES
    =============================================================================
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 01.04.22
    Type: Public
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
    Description: Export distrubtion group with members in CSV. 
    =============================================================================
    .ADDITIONAL NOTES
        You will need to have AzureAD PowerShell module
#>

# Change UPN to your global admin account.
Connect-ExchangeOnline -UserPrincipalName contoso@domain.com 

# Change Distrubtion group name to whichever one needing exportation. 
Get-DistributionGroupMember -Identity 'NameOfGroup' | Select-Object Name, PrimarySmtpAddress | Export-csv C:\O365\ExchDist.csv -NoTypeInformation