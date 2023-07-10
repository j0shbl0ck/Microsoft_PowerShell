<#
.SYNOPSIS
    This provides the opprotunity in adding Send As permissions to a Distribution List.
.NOTES
    Author: Josh Block
    Date: 07.10.23
    Type: Public
    Version: 1.0.1
.LINK
    https://github.com/j0shbl0ck
    https://forums.powershell.org/t/the-operation-couldnt-be-performed-because-user-matches-multiple-entries/16194
    https://woshub.com/sendas-send-onbehalf-permissions-exchange/
#>

Clear-Host

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline | Clear-Host

# Get the Distribution List Object Id
$DL = Read-Host -Prompt "Enter the Distribution List Email Address"
$GUID = Get-DistributionGroup -Identity $DL | Select-Object GUID

# Get the User Email Address
$User = Read-Host -Prompt "Enter the User Email Address to add Send As permissions to the Distribution List"

# Add the Send As permissions to the Distribution List
Add-RecipientPermission -Identity $GUID -Trustee $User -AccessRights SendAs

# Verify the Send As permissions were added to the Distribution List
Get-RecipientPermission -Identity $GUID

