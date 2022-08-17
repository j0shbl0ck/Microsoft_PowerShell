<#
.SYNOPSIS
    This sets all user's Exchange server attributes in a certain OU to null.
.NOTES
    Author: Josh Block
    Date: 08.16.22
    Type: Public
    Version: 1.0.1
.LINK
    https://github.com/j0shbl0ck
    https://shellgeek.com/powershell-set-aduser-to-modify-active-directory-users-attributes/#:~:text=If%20you%20want%20to%20clear%20attribute%20value%20for,and%20pass%20the%20output%20to%20the%20second%20command
    https://social.technet.microsoft.com/wiki/contents/articles/14347.remove-exchange-attributes-using-power-shell-exchange-2010.aspx
    https://www.ntweekly.com/2013/05/20/questionhow-to-remove-exchange-server-attributes-from-active-directory-user-using-powershell/
#>

Clear-Host

# Ask user for OU to search
$OU = Read-Host -Prompt "Enter the OU to search: "

Get-ADUser -filter * -SearchBase "OU=SALES,DC=SHELLPRO,DC=LOCAL" | Set-AdUser -clear department

# for each user in certain OU, remove Exchange attributes
Get-ADUser -Filter * -SearchBase $OU | ForEach-Object {
    Set-AdUser -clear 
    "msExchMailboxAuditEnable",
    "msExchAddressBookFlags",
    "msExchALObjectVersion",
    "msExchDelegateListLink",
    "msExchHomeServerName",
    "msExchMailboxGuid",
    "msExchMobileMailboxFlags",
    "msExchPoliciesIncluded",
    "msExchRBACPolicyLink",
    "msExchRecipientDisplayType",
    "msExchRecipientTypeDetails",
    "msExchSafeRecipientsHash",
    "msExchSafeSendersHash",
    "msExchTextMessagingState",
    "msExchUMDtmfMap",
    "msExchUserAccountControl",
    "msExchUserCulture",
    "msExchVersion",
    "msExchWhenMailboxCreated"
}

