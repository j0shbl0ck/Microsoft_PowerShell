<#
.SYNOPSIS
    This script turns off the retention hold for a mailbox in Exchange Online.
.NOTES
    Author: Josh Block
    Date: 05.08.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/exchangeserver/comments/125pc5s/exchange_online_managed_folder_assistant_error_log/
    https://community.spiceworks.com/t/custom-mrm-policy-not-working/936280/5
#>

Clear-Host

# Connect to Exchange Online via Entra Id
Function Connect_Exo{
    try {
        Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
        
        # Connect to Exchange Online
        Connect-ExchangeOnline | Clear-Host
        
        Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
        Write-Host ""
    }
    catch {
        Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
        exit
    }   
}

# Create a menu that allows the user to do it all mailboxes or a specific mailbox
Function Menu {
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host "1. Disable retention hold for all mailboxes" -ForegroundColor Green
    Write-Host "2. Disable retention hold for a specific mailbox" -ForegroundColor Green
    Write-Host "3. Exit" -ForegroundColor Red

    $choice = Read-Host "Enter your choice (1, 2, or 3)"

    switch ($choice) {
        1 { Disable-RetentionHoldAll }
        2 { Disable-RetentionHoldSpecific }
        3 { exit }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red; Menu }
    }
}

# Function to disable retention hold for all mailboxes
Function Disable-RetentionHoldAll {
    Write-Host "Disabling retention hold for all mailboxes..." -ForegroundColor Yellow

    # Get all mailboxes with retention hold enabled
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.RetentionHoldEnabled -eq $true }

    if ($mailboxes.Count -eq 0) {
        Write-Host "No mailboxes found with retention hold enabled." -ForegroundColor Green
        return
    }

    foreach ($mailbox in $mailboxes) {
        try {
            Set-Mailbox -Identity $mailbox.Identity -RetentionHoldEnabled $false
            Write-Host "Disabled retention hold for mailbox: $($mailbox.DisplayName)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to disable retention hold for mailbox: $($mailbox.DisplayName)" -ForegroundColor Red
        }
    }
}

# Function to disable retention hold for a specific mailbox
Function Disable-RetentionHoldSpecific {
    Write-Host "Disabling retention hold for a specific mailbox..." -ForegroundColor Yellow

    $mailbox = Read-Host "Enter the email address of the mailbox"

    try {
        Set-Mailbox -Identity $mailbox -RetentionHoldEnabled $false
        Write-Host "Disabled retention hold for mailbox: $mailbox" -ForegroundColor Green
    } catch {
        Write-Host "Failed to disable retention hold for mailbox: $mailbox" -ForegroundColor Red
    }
}

# Main script execution
Connect_Exo
Menu
