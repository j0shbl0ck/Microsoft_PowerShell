<#
.SYNOPSIS
    This script enables or disables the external mail tag.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.3
    Date: 12.27.22
    Type: Public
.NOTES

.LINK
    Source: https://o365reports.com/2021/04/27/enable-external-email-warning-tag-in-exchange-online/
#>

# Clear the host screen
Clear-Host

# Variables
$globalAdminUPN = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com)'

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $globalAdminUPN | Clear-Host

# Prompt for enabling or disabling external mail tag
$validChoices = @('enable', 'disable')
$choice = $null

while ($choice -notin $validChoices) {
    $choice = Read-Host -Prompt "Do you want to enable or disable the external mail tag? (Type 'enable' or 'disable')"
    if ($choice -notin $validChoices) {
        Write-Host -ForegroundColor Red "Invalid input. Please type 'enable' or 'disable'"
    }
}

if ($choice -eq 'enable') {
    # Set external mail tag if enabled
    Set-ExternalInOutlook -Enabled $true
} else {
    # Disable external mail tag if disabled
    Set-ExternalInOutlook -Enabled $false
}

# Show the current status of the external mail tag
Get-ExternalInOutlook

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
