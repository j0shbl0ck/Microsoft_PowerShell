<#
Author: J Block
Type: Public
Date: 12.27.21
Source: 
Description: Export distrubtion group with members in CSV.
#>

Connect-ExchangeOnline -UserPrincipalName contoso@domain.com 

#Change Distrubtion group name to whichever one needing exportation. 
Get-DistributionGroupMember -Identity 'NameOfGroup' | Select-Object Name, PrimarySmtpAddress | Export-csv C:\Users\<Username>\ExchDist.csv -NoTypeInformation