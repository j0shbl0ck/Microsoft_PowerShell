<#
.SYNOPSIS
    View and add/delete SMTP email address
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.06.22
    Type: Public
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
.LINK
    Source: https://docs.microsoft.com/en-us/microsoft-365/admin/add-users/set-password-to-never-expire?view=o365-worldwide
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