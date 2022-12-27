<#
.SYNOPSIS
    This script enables or disables the external mail tag.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 12.27.22
    Type: Public
.NOTES

.LINK
    Source: https://o365reports.com/2021/04/27/enable-external-email-warning-tag-in-exchange-online/
#>

Clear-Host

# ======= VARIABLES ======= #
$gadmin = Read-Host -Prompt 'Input Global/Exchange Admin UPN (globaladmin@domain.com) ' 
# ======= VARIABLES ======= #

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline -UserPrincipalName $gadmin | Clear-Host

# Ask user if they want to enable or disable the external mail tag
$choice = Read-Host -Prompt 'Do you want to enable or disable the external mail tag? (enable/disable): '
# If user input is not true or false, ask again
while ($choice -ne 'enable' -and $choice -ne 'disable') {
    $choice = Read-Host -Prompt 'Do you want to enable or disable the external mail tag? (enable/disable): '
}
# Convert user input to boolean
if ($choice -eq 'enable') {
    $choice = $true
} else {
    $choice = $false
}

Set-ExternalInOutlook -Enabled $choice

# Show the current status of the external mail tag
Get-ExternalInOutlook

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false