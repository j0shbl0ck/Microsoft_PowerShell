<#
.SYNOPSIS
    This script enables or disables the external mail tag.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
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

while ($choice -ne 'y' -and $choice -ne 'n') 
{
    $choice = Read-Host -Prompt 'Do you want to enable or disable the external mail tag? (enable/disable): '
    if ($choice -eq 'enable') {
        $choice = $true
    } elseif ($choice -eq 'disable') {
        $choice = $false
    } else {
        Write-Host -ForegroundColor Red "Invalid input. Please type 'enable' or 'disable'"
    }
}

Set-ExternalInOutlook -Enabled $choice

# Show the current status of the external mail tag
Get-ExternalInOutlook

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false