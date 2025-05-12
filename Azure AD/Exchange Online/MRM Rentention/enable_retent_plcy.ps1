<#
.SYNOPSIS
    This script turns on the retention policy for a mailbox in Exchange Online.
.NOTES
    Author: Josh Block
    Date: 05.08.25
    Type: Public
    Version: 1.0.1
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
    Write-Host "1. Enable retention policy for all mailboxes" -ForegroundColor Green
    Write-Host "2. Enable retention policy for a specific mailbox" -ForegroundColor Green
    Write-Host "3. Set a retention policy as the default for your organization" -ForegroundColor Red
    Write-Host "4. Exit" -ForegroundColor Red

    $choice = Read-Host "Enter your choice (1, 2, 3, or 4)"

    switch ($choice) {
        1 { Enable-RetentionPolicy_AllMailboxes }
        2 { Enable-RetentionPolicy_SpecificMailbox }
        3 { Set-DefaultRetentionPolicy }
        4 { exit }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
    }
}

# Get all retention policies and display them in a menu to select from
Function Get-RetentionPolicies {
    $retentionPolicies = Get-RetentionPolicy | Select-Object -Property Name, Identity, RetentionPolicyTagLinks
    $retentionPolicies | Format-Table -AutoSize | Out-Null

    if ($retentionPolicies.Count -eq 0) {
        Write-Host "No retention policies found." -ForegroundColor Red
        return $null
    }

    # Show the menu only once
    Write-Host "Select a retention policy:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $retentionPolicies.Count; $i++) {
        $policy = $retentionPolicies[$i]
        Write-Host "$($i + 1). $($policy.Name) : $($policy.RetentionPolicyTagLinks)" -ForegroundColor Green
    }

    # Prompt repeatedly until valid input is given
    do {
        $selectedpolicy = Read-Host "Enter your choice (1-$($retentionPolicies.Count))"
        if ($selectedpolicy -match '^\d+$' -and [int]$selectedpolicy -ge 1 -and [int]$selectedpolicy -le $retentionPolicies.Count) {
            return $retentionPolicies[[int]$selectedpolicy - 1].Identity
        } else {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
        }
    } while ($true)
}

# Enable retention policy for all mailboxes
Function Enable-RetentionPolicy_AllMailboxes {
    Write-Host "Enabling retention policy for all mailboxes..." -ForegroundColor Yellow
    
    # Select a retention policy from the menu
    $pchoice = Get-RetentionPolicies
    # Get all mailboxes
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -eq 'UserMailbox' }

    # Enable retention policy for each mailbox
    foreach ($mailbox in $mailboxes) {
        try {
            Set-Mailbox -Identity $mailbox.Identity -RetentionPolicy $pchoice
            Write-Host "Enabled retention policy for mailbox: $($mailbox.DisplayName)" -ForegroundColor Green
            # Start the Managed Folder Assistant for the mailbox
            Start-ManagedFolderAssistant -Identity $mailbox.Identity
            Write-Host "Started Managed Folder Assistant for mailbox: $($mailbox.DisplayName)" -ForegroundColor Cyan

        } catch {
            Write-Host "Failed to enable retention policy for mailbox: $($mailbox.DisplayName). Error: $_" -ForegroundColor Red
        }
    }
}

# Enable retention policy for a specific mailbox
Function Enable-RetentionPolicy_SpecificMailbox {
    Write-Host "Enabling retention policy for a specific mailbox..." -ForegroundColor Yellow

    # Select a retention policy from the menu
    $pchoice = Get-RetentionPolicies
    # Get the mailbox identity from the user
    $mailboxIdentity = Read-Host "Enter the mailbox identity (email address or display name)"

    try {
        # Enable selected retention policy for the specified mailbox
        Set-Mailbox -Identity $mailboxIdentity -RetentionPolicy $pchoice
        Write-Host "Enabled retention policy for mailbox: $mailboxIdentity" -ForegroundColor Green
        # Start the Managed Folder Assistant for the mailbox
        Start-ManagedFolderAssistant -Identity $mailboxIdentity
        Write-Host "Started Managed Folder Assistant for mailbox: $mailboxIdentity" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to enable retention policy for mailbox: $mailboxIdentity. Error: $_" -ForegroundColor Red
    }
}

# Set a retention policy as the default for your organization
Function Set-DefaultRetentionPolicy {
    Write-Host "Setting a retention policy as the default for your organization..." -ForegroundColor Yellow

    # Get the retention policy from the user
    $retentionPolicy = Get-RetentionPolicies

    if ($retentionPolicy) {
        try {
            # Get all mailbox plans
            $mailboxPlans = Get-MailboxPlan | Select-Object -Property Identity
            $mailboxPlans | Format-Table -AutoSize | Out-Null

            # Set the retention policy as the default for all mailbox plans
            foreach ($plan in $mailboxPlans) {
                #Set-MailboxPlan -Identity $plan.Identity -RetentionPolicy $retentionPolicy
                Write-Host "Set retention policy '$retentionPolicy' as default for mailbox plan: $($plan.Identity)" -ForegroundColor Green
            }
        } catch {
            Write-Host "Failed to set retention policy as default. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No retention policy selected. Exiting." -ForegroundColor Red
    }
    Write-Host "Retention policy set as default for all mailbox plans." -ForegroundColor Green
}

Connect_Exo
Menu