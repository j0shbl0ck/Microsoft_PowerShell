<#
.SYNOPSIS
Grant Owner permissions to a user on all subfolders under a specified mailbox folder.

.DESCRIPTION
This script enumerates all folders under a specified folder in a mailbox, 
and assigns Owner permissions to a target user. It handles forward slashes in 
folder statistics and converts to backslashes for permission cmdlets.

Author: j0shbl0ck (https://github.com/j0shbl0ck)
Version: 1.0.0
Date: 01.27.26
Type: Public

.PARAMETER Mailbox
The mailbox to modify (e.g., user@contoso.com)

.PARAMETER TargetUser
The user to grant Owner permissions to (e.g., user2@contoso.com)

.PARAMETER RootFolder
The root folder path to search under (use forward slashes, no colons like user@domain.com: just, e.g., /Inbox/My Archive)
#>

# Connect to Exchange Online
Connect-ExchangeOnline

# Prompt for input if not supplied
$Mailbox    = Read-Host "Enter the mailbox to modify"
$TargetUser = Read-Host "Enter the user to grant Owner permissions"
$RootFolder = Read-Host "Enter the root folder path to search (forward slashes, e.g., /Inbox/My Archive)"

Write-Host "`nSearching for folders under $RootFolder in mailbox $Mailbox..." -ForegroundColor Cyan

# Get all folders matching the root folder path
$Folders = Get-EXOMailboxFolderStatistics -Identity $Mailbox |
    Where-Object {
        $_.FolderPath -like "$RootFolder*"
    }

if ($Folders.Count -eq 0) {
    Write-Host "No folders found matching $RootFolder" -ForegroundColor Yellow
    exit
}

Write-Host "`nFound $($Folders.Count) folders. Assigning permissions..." -ForegroundColor Cyan

foreach ($Folder in $Folders) {

    # Convert forward slashes to backslashes for permission cmdlets
    $FolderIdentity = "${Mailbox}:" + ($Folder.FolderPath -replace "/", "\")

    Write-Host "Processing folder:" $FolderIdentity

    try {
        Add-MailboxFolderPermission `
            -Identity $FolderIdentity `
            -User $TargetUser `
            -AccessRights Owner `
            -ErrorAction Stop

        Write-Host "  Permission added (Owner)" -ForegroundColor Green
    }
    catch {
        Set-MailboxFolderPermission `
            -Identity $FolderIdentity `
            -User $TargetUser `
            -AccessRights Owner

        Write-Host "  Permission updated (Owner)" -ForegroundColor Yellow
    }
}

Write-Host "`nAll folders processed." -ForegroundColor Cyan
