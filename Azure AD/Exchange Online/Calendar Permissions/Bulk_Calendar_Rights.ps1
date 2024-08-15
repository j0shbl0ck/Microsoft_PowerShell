<#
.SYNOPSIS
    This script allows you to change calendar permissions through Exchange Online PowerShell
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 12.8.23
    Type: Public
.EXAMPLE
    This script uses a CSV file to assign PublishingAuthor rights to the shared mailbox calendar for each user.
.NOTES
    You will need to have AzureAD PowerShell module [ Install-Module -Name AzureAD ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    Username can vary on whether authenticating against domain or Azure AD. flast or firstlast@domain.com
#>

# ======= EXCHANGE CONNECTION ======= #

# Connect to Exchange Online via Azure AD with Global/Exchange admin.
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline | Clear-Host

# ======= USER VARIABLES ======= #

# Shared calendar email address
$sharedcalendar = "xxxx@domain.com"

# Define calendar permission role
$role = "PublishingAuthor"

# Import CSV file containing user data
$users = Import-Csv -Path "C:\Users\x\Downloads\x.csv" | Select-Object userPrincipalName, displayName

# Loop through each user in the CSV file
foreach ($user in $users) {
  $mainuser = $user.userPrincipalName
  Write-Host -ForegroundColor Cyan "Allowing $mainuser the role of $role to $sharedcalendar calendar..."

  try {
      Set-MailboxFolderPermission -Identity ${sharedcalendar}:\calendar -user $mainuser -AccessRights $role -ErrorAction Stop
      Write-Host -ForegroundColor Green "Successfully granted access to $mainuser."
  } catch {
      Add-MailboxFolderPermission -Identity ${sharedcalendar}:\calendar -user $mainuser -AccessRights $role -ErrorAction Stop
      Write-Host -ForegroundColor Green "User $mainuser added successfully."
  }

  Write-Host -ForegroundColor Green "-----------------------------------------------------"
}

# Show calendar permissions for all users
Write-Host -ForegroundColor Yellow "======= Calendar Rights Users Have to Shared Mailbox ======="
Get-EXOMailboxFolderPermission -Identity ${sharedcalendar}:\calendar

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Script completed!" -ForegroundColor Green