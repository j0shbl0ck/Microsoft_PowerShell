<#
.SYNOPSIS
    This script changes the CN of the ADObject
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.1
    Date: 01.19.22
    Type: Public
.NOTES
    You will need to have Active Directory PowerShell module [ Import-Module ActiveDirectory ]
.LINK
    Source: https://www.reddit.com/r/PowerShell/comments/5588qa/changing_display_name_in_aduc/
#>

# Asks for username (SamAccountName attribute) of ADObject
$username = Read-Host -Prompt "Enter username (SamAccountName attribute) of ADObject"

# Pulls ADUser information primarily objectGUID and displayName
$information = Get-ADUser $username -Properties *
Write-Host -ForegroundColor Cyan "Pulling ADUser information from objectGUID and displayName..."

# Changes ADOBject CN to current displayName Attribute
Rename-ADObject -Identity $information.objectGUID -NewName $information.displayName
Write-Host -ForegroundColor Cyan "Changing ADObject CN to current displayName atttribute..."

# Retrives new CN attribute
$changedname = Get-ADUser -Identity $information.objectGUID
Write-Host ""

Write-Host -ForegroundColor Yellow "distinguishedName:" $changedname
Write-Host -ForegroundColor Yellow "Old Name:" $information.Name
Write-Host -ForegroundColor Yellow "New Name:" $changedname.Name

# Wait for end-user to close session
Write-Host -ForegroundColor Green "Change Complete! You may close this session."
Start-Sleep -Seconds 15 
