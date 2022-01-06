<#
Author: Josh Block (jblock@trustinfinitech.com)
Version: 1.0.1
Type: Public
Date: 11.24.21
Source: https://o365info.com/export-and-display-information-about-email-addresses-using-powershell-office-365-part-6-13/
Source: https://enterinit.com/change-user-primary-email-address-in-office-365-with-powershell/
Description: View and Change primary email address
#>

Connect-ExchangeOnline -UserPrincipalName globaladmin@domain.com 

## Fill out variables 
$username = flast


# View current email address properties of a select user
Get-Mailbox $username |Select-Object DisplayName,PrimarySmtpAddress
Write-Output "-------------------------"
Write-Output "Expanded Email Properties";
Write-Output "-------------------------"
Get-Mailbox $username | Select-Object -ExpandProperty EmailAddresses

<# If you wish to add to the user's email addresses - comment out

$newemail = user@domtenant.com

Set-Mailbox $username –EmailAddresses @{add="$newmail"}
Write-Output "**New PrimarySmtpAddress Below**"
Get-Mailbox $username | Select-Object -ExpandProperty EmailAddresses

#>



<# If you wish to remove one of the user's email addresses - comment out

$oldemail = user@domtenant.onmicrosoft.com

Set-Mailbox $username –EmailAddresses @{remove="$oldemail"}
Write-Output "**New PrimarySmtpAddress Below**"
Get-Mailbox $username | Select-Object -ExpandProperty EmailAddresses

#>