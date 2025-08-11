<#
.SYNOPSIS
    Interactive loop granting mailbox and OneDrive permissions.
.NOTES
    Author: Josh Block
    Date: 08.01.25
    Type: Public
    Version: 1.0.0
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/Office365/comments/1k5xu5b/office_365_global_admin_hacked_with_mfa_enabled
#>

Clear-Host

# region Connect to Exchange Online
try {
    Write-Host -ForegroundColor Yellow 'Connecting to Exchange Online...'
    Connect-ExchangeOnline -ShowBanner:$false
    Write-Host -ForegroundColor Green 'Connected to Exchange Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to Exchange Online. Ending script." -ForegroundColor Red
    exit
}

# region Connect to SharePoint Online
try {
    Write-Host -ForegroundColor Yellow 'Connecting to SharePoint Online...'
    Connect-SPOService -Url "https://commercebank-admin.sharepoint.com"
    Write-Host -ForegroundColor Green 'Connected to SharePoint Online.'
    Write-Host ""
}
catch {
    Write-Host "Failed to connect to SharePoint Online. Ending script." -ForegroundColor Red
    exit
}

function Grant-MailboxPermissions {
    param (
        [string]$Mailbox,
        [string]$Delegate
    )
    Write-Host -ForegroundColor Yellow "`n[+] Granting Send As and Full Access permissions to $Delegate on $Mailbox..."
    Add-RecipientPermission -Identity $Mailbox -Trustee $Delegate -AccessRights SendAs -Confirm:$false -ErrorAction Stop
    Add-MailboxPermission -Identity $Mailbox -User $Delegate -AccessRights FullAccess -InheritanceType All -Confirm:$false -ErrorAction Stop
}

function Grant-OneDriveAdmin {
    param (
        [string]$UserPrincipalName,
        [string]$AdminUPN
    )
    Write-Host -ForegroundColor Yellow "`n[+] Assigning Site Collection Admin to $AdminUPN for $UserPrincipalName's OneDrive..."
    $formattedUPN = $UserPrincipalName.Replace('@', '_').Replace('.', '_')
    $onedriveUrl = "https://commercebank-my.sharepoint.com/personal/$formattedUPN"
    Set-SPOUser -Site $onedriveUrl -LoginName $AdminUPN -IsSiteCollectionAdmin $true | Out-Null
    return $onedriveUrl
}

function Show-Menu {
    Write-Host -ForegroundColor Yellow "`n==============================="
    Write-Host -ForegroundColor Yellow "   Offboarding Options Menu"
    Write-Host -ForegroundColor Yellow "==============================="
    Write-Host -ForegroundColor Yellow "1. Grant mailbox permissions"
    Write-Host -ForegroundColor Yellow "2. Grant OneDrive admin access"
    Write-Host -ForegroundColor Yellow "3. Do both"
    Write-Host -ForegroundColor Yellow "4. Exit"
    Write-Host -ForegroundColor Yellow "==============================="
    $choice = Read-Host "Enter your choice (1-4)"
    return $choice
}

# ===== Main Loop =====
while ($true) {
    $choice = Show-Menu

    if ($choice -eq "4") {
        Write-Host "`nExiting script..." -ForegroundColor Cyan
        break
    }

    $mailbox = Read-Host "`nEnter the UPN of the mailbox owner (person whose data will be accessed)"
    $delegate = Read-Host "Enter the UPN of the delegate (person who will be granted access)"

    $actions = @()

    switch ($choice) {
        "1" {
            Grant-MailboxPermissions -Mailbox $mailbox -Delegate $delegate | Out-Null
            $actions += "Mailbox permissions granted: Send As and Full Access for $delegate on $mailbox"
        }
        "2" {
            $onedriveUrl = Grant-OneDriveAdmin -UserPrincipalName $mailbox -AdminUPN $delegate
            $actions += "OneDrive admin access granted: $delegate is now Site Collection Admin for $mailbox's OneDrive"
            Write-Host "OneDrive URL: $onedriveUrl"
        }
        "3" {
            Grant-MailboxPermissions -Mailbox $mailbox -Delegate $delegate | Out-Null
            $onedriveUrl = Grant-OneDriveAdmin -UserPrincipalName $mailbox -AdminUPN $delegate
            $actions += "Mailbox permissions granted: Send As and Full Access for $delegate on $mailbox"
            $actions += "OneDrive admin access granted: $delegate is now Site Collection Admin for $mailbox's OneDrive"
            Write-Host "OneDrive URL: $onedriveUrl"
        }
        default {
            Write-Host "`n[!] Invalid choice."
            continue
        }
    }

    # Action Summary
    Write-Host -ForegroundColor Cyan "`n========== Action Summary =========="
    foreach ($action in $actions) {
        Write-Host -ForegroundColor Green "[✓] $action"
    }
    Write-Host -ForegroundColor Cyan "====================================="

    # Ask if they want to continue
    $continue = Read-Host "`nPress Enter to return to menu or type 'exit' to quit"
    if ($continue -eq "exit") {
        break
    }
}