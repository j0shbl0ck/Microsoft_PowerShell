<#
.SYNOPSIS
    This sets all user's Exchange server attributes in a certain OU to null.
.NOTES
    Author: Josh Block
    Date: 08.16.22
    Type: Public
    Version: 1.0.5
.LINK
    https://github.com/j0shbl0ck
    https://shellgeek.com/powershell-set-aduser-to-modify-active-directory-users-attributes/#:~:text=If%20you%20want%20to%20clear%20attribute%20value%20for,and%20pass%20the%20output%20to%20the%20second%20command
    https://social.technet.microsoft.com/wiki/contents/articles/14347.remove-exchange-attributes-using-power-shell-exchange-2010.aspx
    https://www.ntweekly.com/2013/05/20/questionhow-to-remove-exchange-server-attributes-from-active-directory-user-using-powershell/
#>

Clear-Host

# Import Active Directory module
Import-Module ActiveDirectory  -ErrorAction Stop

# Get all users in the OU
Write-Warning "This clears Exchange server attributes for all users in the OU." -WarningAction Inquire
# Ask user for OU to search
$OU = Read-Host -Prompt "Enter the OU (Example: OU=SALES,DC=SHELLPRO,DC=LOCAL) for Exchange attribute removal: "

# For each user in specified OU, remove Exchange attributes
Get-ADUser -Filter * -SearchBase $OU | Set-ADUser -Clear msExchMailboxAuditEnable,
    msExchAddressBookFlags,
    msExchALObjectVersion,
    msExchDelegateListLink,
    msExchHomeServerName,
    msExchMailboxGuid,
    msExchMobileMailboxFlags,
    msExchPoliciesIncluded,
    msExchRBACPolicyLink,
    msExchRecipientDisplayType,
    msExchRecipientTypeDetails,
    msExchSafeRecipientsHash,
    msExchSafeSendersHash,
    msExchTextMessagingState,
    msExchUMDtmfMap,
    msExchUserAccountControl,
    msExchUserCulture,
    msExchVersion,
    msExchWhenMailboxCreated,
    msExchMailboxMoveSourceMDBLink,
    msExchMailboxMoveTargetMDBLink,
    msExchMailboxMoveStatus,
    msExchMailboxSecurityDescriptor,
    msExchBlockedSendersHash,
    msExchMailboxMoveFlags




