<#
.SYNOPSIS
This script allows you to view all mailbox sizes in your tenant.
.DESCRIPTION
Author: j0shbl0ck https://github.com/j0shbl0ck
Version: 1.0.3
Date: 12.05.22
Type: Public
.NOTES

.LINK
Source: https://m365scripts.com/exchange-online/get-mailbox-details-in-microsoft-365-using-powershell/
#>

Clear-Host

# Connect to Exchange Online
Connect-ExchangeOnline -ShowBanner:$false

Write-Output "Fetching mailbox details... Please wait..."
$mailboxes = Get-Mailbox -ResultSize Unlimited

#Calculate mailbox size and select relevant properties
$mailboxSizes = $mailboxes | ForEach-Object {
Get-MailboxStatistics -Identity $_.UserPrincipalName |
Select-Object DisplayName, TotalItemSize
}

#Format and display results
$mailboxSizes | Format-Table -AutoSize DisplayName, TotalItemSize | Out-String | Write-Output

Write-Output "Mailbox details retrieved successfully."

# Clear the host screen
Clear-Host

# Prompt for Global/Exchange Admin UPN
$gAdmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com): '

try {
    # Connect to Exchange Online via Azure AD
    Connect-ExchangeOnline -UserPrincipalName $gAdmin -ErrorAction Stop | Out-Null

    Write-Output "Fetching mailbox details... Please wait..."

    # Fetch mailbox details
    $mailboxes = Get-Mailbox -ResultSize Unlimited

    # Fetch mailbox sizes and select relevant properties
    $mailboxSizes = $mailboxes | ForEach-Object {
        Get-MailboxStatistics -Identity $_.UserPrincipalName |
        Select-Object DisplayName, TotalItemSize
    }

    # Format and display results
    $mailboxSizes | Format-Table -AutoSize DisplayName, TotalItemSize | Out-String | Write-Output

    Write-Output "Mailbox details retrieved successfully."
} catch {
    Write-Host -ForegroundColor Red "An error occurred: $($_.Exception.Message)"
}
