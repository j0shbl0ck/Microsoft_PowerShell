<#
.SYNOPSIS
    This script exports users from a specified OU and then exports all groups with their members contained in the groups to a CSV file.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 07.19.23
    Type: Public
.NOTES
    You will need to have Active Directory PowerShell module [ Import-Module ActiveDirectory ]
.LINK
    
#>

$OU = "OU=Users,OU=Company,DC=domain,DC=com"

# Import the Active Directory PowerShell module
Import-Module ActiveDirectory

# Get a list of all users in the OU
$users = Get-ADUser -Filter * -SearchBase $OU -Properties displayname, SamAccountName, Enabled, PasswordLastSet | Select-Object displayname, SamAccountName, Enabled, PasswordLastSet 

# Create a CSV file to export the data to
$csvFile = "users.csv"

# Export the data to the CSV file
$users | Select-Object -Property displayname, SamAccountName, Enabled, PasswordLastSet| Export-CSV $csvFile -NoTypeInformation

# Write a message to the console indicating that the export was successful
Write-Host "The data was exported to $csvFile"

# Create a folder on the desktop called, AD Groups
$folder = "$($env:USERPROFILE)\Documents\ADGroups"
# Create the folder
New-Item -Path $folder -ItemType Directory -Force
$groups = Get-ADGroup -Filter *

# Loop through the groups
foreach ($group in $groups) {

    # Get the name of the group
    $groupname = Get-ADGroup $group -Properties Name | Select-Object Name -ExpandProperty Name
    # Get the members of the group in Display Name form
    Get-ADGroupMember $group | Select-Object Name
    # Create a CSV file within the AD Groups folder with the group name as the title of the file
    $csvFile = "$($env:USERPROFILE)\Documents\ADGroups\$groupname.csv"
    # Export the data to the CSV file
    Get-ADGroupMember $group | Select-Object Name | Export-CSV $csvFile -NoTypeInformation
}

