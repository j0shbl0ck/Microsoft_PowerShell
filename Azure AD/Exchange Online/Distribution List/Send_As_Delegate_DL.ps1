<#
.SYNOPSIS
    This provides the opprotunity in adding Send As permissions to a Distribution List.
.NOTES
    Author: Josh Block
    Date: 07.10.23
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://forums.powershell.org/t/the-operation-couldnt-be-performed-because-user-matches-multiple-entries/16194
    https://woshub.com/sendas-send-onbehalf-permissions-exchange/
#>

Clear-Host

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline | Clear-Host