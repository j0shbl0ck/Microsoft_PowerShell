<#
.SYNOPSIS
    This script retrieves the top 10 largest folders in primary mailbox, recoverable items, and archive mailbox. 
.NOTES
    Author: Josh Block
    Date: 07.18.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck

#>

Clear-Host

# Connect to Exchange Online via Azure AD with Global/Exchange Admin Center credentials
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'

    # Connect to Exchange Online
    Connect-ExchangeOnline -ShowBanner:$false

    Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
    exit
}


# Prompt for mailbox input
$UserMailbox = Read-Host "Enter the mailbox username (e.g. user@domain.com)"

# Helper function to convert FolderSize to KB
function Get-FolderSizeKB {
    param ($FolderSize)
    try {
        $bytes = ($FolderSize -split '[()]')[1] -replace '[^\d]', ''
        return [math]::Round([double]$bytes / 1KB, 2)
    } catch {
        return 0
    }
}

# ========== Mailbox Folders ==========
Write-Host "`n===============================" -ForegroundColor Cyan
Write-Host "📁 Top 10 Largest Mailbox Folders for $UserMailbox" -ForegroundColor Yellow
Write-Host "===============================`n" -ForegroundColor Cyan

$topStandard = Get-MailboxFolderStatistics -Identity $UserMailbox |
    Where-Object { $_.FolderSize -ne $null } |
    Select-Object Name, ItemsInFolder,
        @{Name = 'FolderSizeKB'; Expression = { Get-FolderSizeKB $_.FolderSize }},
        @{Name = 'FolderSizeOriginal'; Expression = { $_.FolderSize }} |
    Sort-Object FolderSizeKB -Descending |
    Select-Object -First 10 |
    Select-Object Name, ItemsInFolder, FolderSizeOriginal  # Final displayed fields only

$topStandard | Format-Table -AutoSize

# ========== Recoverable Items ==========
Write-Host "`n===============================" -ForegroundColor Cyan
Write-Host "🗑️  Top 10 Largest Recoverable Items Folders for $UserMailbox" -ForegroundColor Green
Write-Host "===============================`n" -ForegroundColor Cyan

$topRecoverable = Get-MailboxFolderStatistics -Identity $UserMailbox |
    Where-Object { $_.FolderType -like "RecoverableItems*" -and $_.FolderSize -ne $null } |
    Select-Object Name, ItemsInFolder,
        @{Name = 'FolderSizeKB'; Expression = { Get-FolderSizeKB $_.FolderSize }},
        @{Name = 'FolderSizeOriginal'; Expression = { $_.FolderSize }} |
    Sort-Object FolderSizeKB -Descending |
    Select-Object -First 10 |
    Select-Object Name, ItemsInFolder, FolderSizeOriginal  # Final displayed fields only

$topRecoverable | Format-Table -AutoSize

# ========== Archive Mailbox Folders ==========
Write-Host "`n===============================" -ForegroundColor Cyan
Write-Host "💾 Top 10 Largest Archive Folders for $UserMailbox" -ForegroundColor Gray
Write-Host "===============================`n" -ForegroundColor Cyan

try {
    $topArchive = Get-MailboxFolderStatistics -Identity $UserMailbox -Archive |
        Where-Object { $_.FolderSize -ne $null } |
        Select-Object Name, ItemsInFolder,
            @{Name = 'FolderSizeKB'; Expression = { Get-FolderSizeKB $_.FolderSize }},
            @{Name = 'FolderSizeOriginal'; Expression = { $_.FolderSize }} |
        Sort-Object FolderSizeKB -Descending |
        Select-Object -First 10 |
        Select-Object Name, ItemsInFolder, FolderSizeOriginal  # Final displayed fields only

    if ($topArchive.Count -gt 0) {
        $topArchive | Format-Table -AutoSize
    } else {
        Write-Host "No folders found in the archive mailbox." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "⚠️  Archive mailbox is not enabled or could not be queried." -ForegroundColor Red
}

Write-Host "`n✅ Done! All results above." -ForegroundColor Cyan