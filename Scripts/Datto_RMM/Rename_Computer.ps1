<#
.SYNOPSIS
    This script forcibly renames a computer and restarts it.
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.02.24
    Type: Public
.NOTES
    This script it built for the Datto RMM platform.
.LINK
    https://github.com/j0shbl0ck
#>

# Define the new computer name
$newComputerName = "NewComputerName"

# Check if the new computer name is valid
if ($newComputerName -match "^[a-zA-Z0-9\-]{1,15}$") {
    # Change the computer name
    Rename-Computer -NewName $newComputerName -Force -Restart
    Write-Output "Computer name has been changed to $newComputerName. The system will restart."
} else {
    Write-Output "Invalid computer name. It should be 1-15 characters long and can only contain letters, numbers, and hyphens."
}
