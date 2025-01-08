<#
.SYNOPSIS
    This script 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.08.25
    Type: Public
.NOTES
    You will need to have Active Directory PowerShell module [ Import-Module ActiveDirectory ]
.LINK
    
#>

# Define the OU to search in
$OU = "OU=Users,OU=TEST,DC=test,DC=local"

# Define the output file path
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$OutputFile = Join-Path -Path $DesktopPath -ChildPath "HiddenFromAddressListUsers.csv"

# Import the Active Directory module
Import-Module ActiveDirectory

# Search for users in the specified OU and its sub-OUs, excluding OUs with "INACTIVE" or "NOSYNC" in their names
$Users = Get-ADUser -Filter * -SearchBase $OU -Properties msExchHideFromAddressLists |
         Where-Object {
            ($_.DistinguishedName -notmatch "(?i)OU=INACTIVE|OU=NOSYNC") -and
            ($_.msExchHideFromAddressLists -eq $true)
         }

# Select relevant properties to export
$ExportData = $Users | Select-Object Name,UserPrincipalName

# Export the results to a CSV file
$ExportData | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "Export completed. The file is located at: $OutputFile"