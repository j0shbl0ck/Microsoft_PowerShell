<#
.SYNOPSIS
    This script pulls information on what groups the user is in. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 04.13.22
    Type: Public
.NOTES
    You may need to resize the console window varying on email address length.
.LINK
    Source: https://www.sharepointdiary.com/2020/09/find-all-office-365-groups-user-is-member-of-using-powershell.html
#>

# Ask for the user's email address
$userEmail = Read-Host -Prompt "Please enter user email address: " -As secureString -RawInput

# Import Azure AD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# create try catch that retrives the groups the user is a member of
try {
    # Get the user's groups
    $userGroups = Get-AzureADGroupMember -ObjectId $userEmail

    # Get the user's groups
    $memberbships = Get-AzureADGroupMember -ObjectId $userEmail.ObjectId | Where-Object {}
    
    # Print the groups
    Write-Host "User is a member of the following groups:"
    Write-Host ""
    Write-Host $userGroups
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
}



Get-Groups



