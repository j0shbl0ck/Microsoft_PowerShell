<#
.SYNOPSIS
    This provides the opprotunity in adding Send As permissions to a Distribution List.
.NOTES
    Author: Josh Block
    Date: 07.10.23
    Type: Public
    Version: 1.0.3
.LINK
    https://github.com/j0shbl0ck
    https://forums.powershell.org/t/the-operation-couldnt-be-performed-because-user-matches-multiple-entries/16194
    https://woshub.com/sendas-send-onbehalf-permissions-exchange/
#>

# Connect to Exchange Online via Azure AD
Connect-ExchangeOnline | Clear-Host

# Start a loop
Do {

    # Get the Distribution List Object Id
    $DL = Read-Host -Prompt "Enter the Distribution List Email Address"
    $GUID = Get-DistributionGroup -Identity $DL | Select-Object GUID

    # Get the User Email Address
    $User = Read-Host -Prompt "Enter the User Email Address to add Send As permissions to the Distribution List"

    # Add the Send As permissions to the Distribution List
    Try {
        Add-RecipientPermission -Identity $GUID -Trustee $User -AccessRights SendAs
        Write-Host "Send As permissions successfully added to the Distribution List."
    } Catch {
        Write-Host "An error occurred while adding Send As permissions to the Distribution List."
        Write-Host $Error[0].Exception.Message
    }

    # Ask the user if they want to add another user
    $Continue = Read-Host -Prompt "Would you like to add another user? (Y/N)"

    # Check for invalid input
    If ($Continue -ne "Y") {
        Write-Host "Exiting script."
        Exit
    }

} While ($Continue -eq "Y")


