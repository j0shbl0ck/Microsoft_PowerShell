<#
.SYNOPSIS
    This script gets every user excluding unlicensed, shared, and external then adds them to an all company list.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.1.9
    Date: 04.14.22
    Type: Public
.EXAMPLE
.NOTES
    You will need to have MSOnline PowerShell module [ Install-Module -Name MSOnline ]
    You will need to have Exchange Online module [ Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 ]
    You will need to sign in twice for each Azure connection.
    After distribution list is created, check online for the distribution list name and possible primary email address change.
.LINK
    https://social.technet.microsoft.com/Forums/ie/en-US/a48b455e-0114-424f-8b0f-a8c0b88dfb0f/exchange-powershell-loop-through-all-usersmailboxes-and-run-an-exchange-command-on-the-mailbox?forum=winserverpowershell
    https://medium.com/@writeabednego/bulk-create-and-add-members-to-distribution-lists-and-shared-mailboxes-using-powershell-89f5ef6e1362
#>


Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange Admin Center credentials
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
    Connect-ExchangeOnline | Clear-Host
    Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
    exit
}

# Connect to Microsoft Online
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Microsoft Online...'
    Connect-AzureAD | Clear-Host
    Write-Host -ForegroundColor Green 'Connected to Microsoft Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Microsoft Online. Ending script." -ForegroundColor Red
    exit
}

# Ask user if they want to create or update distribution list
Write-Host "Would you like to create or update the all company distribution list? Enter 'create' or 'update' to continue:"
$createUpdate = Read-Host

# if user wants to create distribution list
if ($createUpdate -eq "create")
{
    # Note: The following block creates the 'All Company' distribution list
    # and adds eligible users to the list.

    # Create all company distribution list.
    $primarydomain = ((Get-AzureADTenantDetail).verifieddomains | Where-Object { $_._default -eq $true }).name
    $PrimarySmtpAddress = "allcompany@${primarydomain}"
    Write-Host ""

    New-DistributionGroup -Name "All Company" -Alias "Allcmpny" -PrimarySmtpAddress $PrimarySmtpAddress -Type Distribution

    # Get all users licensed and not external
    Write-Host "Getting users for all company distribution list..." -ForegroundColor Yellow
    $allUsers = Get-AzureADUser -All:$true | Where-Object {
        ($_.AssignedLicenses -ne $null) -and
        ($_.UserPrincipalName -notlike "*#EXT#*") -and
        ($_.UserPrincipalName -notlike "SPO_*") -and
        ($_.UserPrincipalName -notlike "*_admin@*") -and
        ($_.UserPrincipalName -notlike "*_onmicrosoft.com")
    } | Select-Object UserPrincipalName, DisplayName


    # For each user, add to all company list.
    # Add good users to the all company list if they're not already a member
    foreach ($aUser in $allUsers) {
            Add-DistributionGroupMember -Identity "All Company" -Member $aUser.UserPrincipalName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "Added user: $($aUser.DisplayName)"
        }
    }

    # Indicate success
    Write-Host "Distribution group created successfully" -ForegroundColor Green

# if user wants to update distribution list
elseif ($createUpdate -eq "update")
{
    # Get the current members of the all company distribution list
    $currentMembers = Get-DistributionGroupMember -Identity "All Company"

    # Get all users licensed and external
    $goodUsers = Get-AzureADUser -All:$true | Where-Object {
        ($_.AssignedLicenses -ne $null) -and
        ($_.UserPrincipalName -notlike "*#EXT#*") -and
        ($_.UserPrincipalName -notlike "SPO_*") -and
        ($_.UserPrincipalName -notlike "*_admin@*") -and
        ($_.UserPrincipalName -notlike "*_onmicrosoft.com")
    } | Select-Object UserPrincipalName, DisplayName

    # Add good users to the all company list if they're not already a member
    foreach ($gUser in $goodUsers) {
        if ($currentMembers.PrimarySmtpAddress -notcontains $gUser.UserPrincipalName){
            Add-DistributionGroupMember -Identity "All Company" -Member $gUser.UserPrincipalName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "Added user: $($gUser.DisplayName)"
        }
    }
    
    # Note: The following block removes bad users from the 'All Company' distribution list.

    # Get all users licensed and external
    $badUsers = Get-AzureADUser -All:$true | Where-Object {
        ($_.AssignedLicenses -ne $null) -and
        ($_.UserPrincipalName -like "*#EXT#*") -or  # Modified to include bad users
        ($_.UserPrincipalName -like "SPO_*") -or
        ($_.UserPrincipalName -like "*_admin@*") -or
        ($_.UserPrincipalName -like "*_onmicrosoft.com")
    } | Select-Object UserPrincipalName, DisplayName

    # Remove bad users from the all company list if they're already a member
    foreach ($bUser in $badUsers) {
        if ($currentMembers.UserPrincipalName -contains $bUser.UserPrincipalName){
            Remove-DistributionGroupMember -Identity "All Company" -Member $bUser.UserPrincipalName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "Removed user: $($bUser.DisplayName)"
        }
    }

    # Indicate success
    Write-Host "Distribution group updated successfully" -ForegroundColor Green
}


# if user does not enter create or update
else
{
    Write-Host "Please enter 'create' or 'update' to continue." -ForegroundColor Red
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

# Display script end
Write-Host "`nScript ended" -ForegroundColor Magenta
$null = Read-Host