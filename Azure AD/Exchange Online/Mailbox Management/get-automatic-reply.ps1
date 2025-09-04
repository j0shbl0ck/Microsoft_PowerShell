<#
.SYNOPSIS
    Checks and optionally clears mailbox auto-reply configuration.
.DESCRIPTION
    This script retrieves the auto-reply configuration for a given mailbox.
    If Internal or External messages are configured, it will display them along
    with any scheduled end time. The user will then be prompted to clear them.
.NOTES
    Author: Josh B.
    Version: 1.0.0
    Date: 09/04/2025
#>

Clear-Host

# Prompt user for mailbox email
$mailbox = Read-Host "Enter the mailbox email address"

try {
    $autoReply = Get-MailboxAutoReplyConfiguration -Identity $mailbox -ErrorAction Stop
}
catch {
    Write-Host "❌ Failed to retrieve auto-reply settings for $mailbox. $_" -ForegroundColor Red
    return
}

Write-Host "📬 Mailbox: $mailbox" -ForegroundColor Cyan
Write-Host "----------------------------------------"

Write-Host "Automatic Replies are currently: $($autoReply.AutoReplyState)" -ForegroundColor Green

if ($autoReply.StartTime -and $autoReply.EndTime) {
    Write-Host "Start Time: $($autoReply.StartTime)" -ForegroundColor Gray
    Write-Host "End Time  : $($autoReply.EndTime)" -ForegroundColor Gray
}

if ($autoReply.InternalMessage) {
    Write-Host "`n📨 Internal Message:" -ForegroundColor Cyan
    Write-Host $autoReply.InternalMessage
} else {
    Write-Host "`nNo internal message configured." -ForegroundColor Yellow
}

if ($autoReply.ExternalMessage) {
    Write-Host "`n🌍 External Message:" -ForegroundColor Cyan
    Write-Host $autoReply.ExternalMessage
} else {
    Write-Host "`nNo external message configured." -ForegroundColor Yellow
}

# Only prompt to clear if something is actually set
if ($autoReply.InternalMessage -or $autoReply.ExternalMessage) {
    $clear = Read-Host "`nDo you want to clear both internal and external messages? (Y/N)"
    if ($clear -match '^[Yy]$') {
        try {
            Set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Disabled -InternalMessage $null -ExternalMessage $null
            Write-Host "✅ Auto-reply messages cleared and disabled." -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to clear auto-reply settings. $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No changes made." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNothing to clear." -ForegroundColor Gray
}
