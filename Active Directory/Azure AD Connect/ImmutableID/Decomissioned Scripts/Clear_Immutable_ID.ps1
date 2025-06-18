⚠️ THIS SCRIPT IS DECOMISSIONED ⚠️ 

<#
.SYNOPSIS
    This sets an Entra ID user's ImmutableID attribute to $null
.NOTES
    Author: Josh Block
    Date: 04.19.24
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/answers/questions/1333250/how-to-set-users-onpremisesimmutableid-field-to-nu
#>

# Check for if Microsoft Graph module is downloaded

# Clear any Microsoft Graph connections then prompting for sign-in
Disconnect-MgGraph -ErrorAction SilentlyContinue

# Connect to Microsoft Graph module
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Get User's ID information
$entrauser = Read-Host -Prompt "Enter the UPN of user being set to $null"

Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/${entrauser}" -Body @{OnPremisesImmutableId = $null}

# Get User's Immutable ID property
Get-Mguser -UserId $entrauser -Property onPremisesImmutableId | select-object onpremisesimmutableid

# Disconnect from Microsoft Graph module
Disconnect-MgGraph