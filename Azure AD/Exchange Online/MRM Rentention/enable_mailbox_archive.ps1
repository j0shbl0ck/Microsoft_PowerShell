<#
.SYNOPSIS
    This script turns on mailbox archive for specific users or the entire organization.
.NOTES
    Author: Josh Block
    Date: 05.12.25
    Type: Public
    Version: 1.0.3
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
    Write-Host "1. Enable Archive for all mailboxes" -ForegroundColor Green
    Write-Host "2. Enable Archive for a specific mailbox" -ForegroundColor Green
    Write-Host "3. Enable Auto-Archive in Organization" -ForegroundColor Green
    Write-Host "4. Get Archive Status" -ForegroundColor Green
    Write-Host "5. Exit" -ForegroundColor Red

    $choice = Read-Host "Enter your choice (1, 2, or 3)"

    switch ($choice) {
        1 { Enable-ArchiveAll }
        2 { Enable-ArchiveSpecific }
        3 { Enable-AutoArchive }
        4 { Get-ArchiveStatus }
        5 { Write-Host "Exiting script." -ForegroundColor Red; exit }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red; Menu }
    }
}

# Enable Archive for all mailboxes
Function Enable-ArchiveAll {
    Write-Host "Enabling Archive for all mailboxes..." -ForegroundColor Yellow

    # Get all mailboxes and enable archive
    $mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox -Archive -ErrorAction SilentlyContinue

    if ($mailboxes) {
        Write-Host "Archive is already enabled for the following mailboxes:" -ForegroundColor Green
        $mailboxes | Select-Object DisplayName, ArchiveState | Format-Table -AutoSize
    } else {
        Write-Host "No mailboxes with archive enabled found." -ForegroundColor Red
    }

    $mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox -Archive:$false

    if ($mailboxes) {
        foreach ($mailbox in $mailboxes) {
            Enable-Mailbox -Identity $mailbox.Identity -Archive
            Write-Host "Enabled Archive for mailbox: $($mailbox.DisplayName)" -ForegroundColor Green
        }
    } else {
        Write-Host "No mailboxes found without archive enabled." -ForegroundColor Red
    }
}

# Enable Archive for a specific mailbox
Function Enable-ArchiveSpecific {
    try {
        $mailbox = Read-Host "Enter the email address of the mailbox to enable archive"
        Write-Host "Enabling Archive for mailbox: $mailbox..." -ForegroundColor Yellow
        Enable-Mailbox -Identity $mailbox -Archive
        Write-Host "Enabled Archive for mailbox: $mailbox" -ForegroundColor Green
    } catch {
        Write-Host "Failed to enable archive for mailbox: $mailbox" -ForegroundColor Red
    }
}

# Enable Auto-Archive in Organization
Function Enable-AutoArchive {
    Write-Host "Enabling Auto-Archive in Organization..." -ForegroundColor Yellow

    # Enable Auto-Archive for all mailboxes
    Set-OrganizationConfig -AutoEnableArchiveMailbox $true

    Write-Host "Auto-Archive enabled for all mailboxes." -ForegroundColor Green
}

# Get Archive Status
Function Get-ArchiveStatus {
    Write-Host "Getting Archive Status..." -ForegroundColor Yellow

    # Get all mailboxes and their archive status
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, UserPrincipalName, ArchiveStatus
    

    if ($mailboxes) {
        Write-Host "Archive Status for all mailboxes:" -ForegroundColor Green
        $mailboxes | Format-Table -AutoSize
    } else {
        Write-Host "No mailboxes found." -ForegroundColor Red
    }
}

Connect_Exo
Menu


        



