<#
.SYNOPSIS
    Copies the membership of an existing Microsoft 365 Group into a new (or
    existing) mail-enabled security group in Exchange Online.

.DESCRIPTION
    Many orgs need a mail-enabled security group that mirrors an M365 Group's
    membership — e.g. for mail flow rules, DLP policies, conditional access
    targeting, or other scenarios that don't support Microsoft 365 Groups
    directly. This script:

      1. Connects to Exchange Online (verifying the session is actually live,
         not just reporting as connected).
      2. Looks up the source group with Get-UnifiedGroup (M365 Groups are
         group-mailbox-backed and are NOT readable via Get-DistributionGroup).
      3. Retrieves its membership via Get-UnifiedGroupLinks.
      4. Creates a new mail-enabled security group (Get/New-DistributionGroup
         -Type Security) if it doesn't already exist.
      5. Adds each source member to the target group, skipping anyone already
         present so the script is safe to re-run.

    IMPORTANT: The target mail-enabled security group's email address MUST
    NOT match the source M365 Group's primary SMTP address (or any of its
    proxy addresses). Exchange Online enforces globally unique email
    addresses/aliases across all recipient types in the tenant — attempting
    to reuse the source group's address for the new security group will
    fail outright, and even a "close but distinct" address that collides
    with an existing proxy address on the source group will error the same
    way. This script checks for that collision before attempting creation
    and stops with a clear error if found.

.PARAMETER SourceGroup
    Identity (name, alias, or email) of the existing Microsoft 365 Group to
    copy members from.

.PARAMETER TargetGroup
    Display name / alias for the new mail-enabled security group.

.PARAMETER TargetEmailAddress
    Primary SMTP address for the new group. Must be unique in the tenant and
    MUST NOT match the source group's email address (see warning above).

.PARAMETER IncludeOwners
    If specified, also copies the source group's Owners into the target
    group as members (M365 Groups track Owners and Members separately;
    Owners are not included by default).

.PARAMETER DryRun
    Preview all actions (group creation + member adds) without making any
    changes. Prints a full summary of what would happen.

.EXAMPLE
    .\Convert-M365GroupToMailEnabledSecurityGroup.ps1 `
        -SourceGroup "C21 Columbia Agents" `
        -TargetGroup "C21 Columbia Agents X" `
        -TargetEmailAddress "c21columbiaagents.x@c21community.com" `
        -DryRun

.EXAMPLE
    .\Convert-M365GroupToMailEnabledSecurityGroup.ps1 `
        -SourceGroup "Marketing Team" `
        -TargetGroup "Marketing Team MESG" `
        -TargetEmailAddress "marketing-mesg@contoso.com" `
        -IncludeOwners

.NOTES
    Author:    Josh Block
    GitHub:    https://github.com/j0shbl0ck
    Requires:  ExchangeOnlineManagement module, connected via
               Connect-ExchangeOnline with a role that can create/modify
               distribution groups (e.g. Recipient Management).
    Version:   1.0.0
    License:   MIT
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Identity of the source Microsoft 365 Group.")]
    [ValidateNotNullOrEmpty()]
    [string]$SourceGroup,

    [Parameter(Mandatory = $true, HelpMessage = "Display name / alias for the new mail-enabled security group.")]
    [ValidateNotNullOrEmpty()]
    [string]$TargetGroup,

    [Parameter(Mandatory = $true, HelpMessage = "Primary SMTP address for the new group. Must NOT match the source group's address.")]
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$', ErrorMessage = "TargetEmailAddress does not look like a valid email address.")]
    [string]$TargetEmailAddress,

    [Parameter()]
    [switch]$IncludeOwners,

    [Parameter()]
    [switch]$DryRun
)

#region Helper functions
function Write-Status {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info', 'Success', 'Warn', 'Error', 'Dry')]
        [string]$Level = 'Info'
    )
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warn'    { 'Yellow' }
        'Error'   { 'Red' }
        'Dry'     { 'Magenta' }
    }
    $prefix = switch ($Level) {
        'Info'    { '[*]' }
        'Success' { '[+]' }
        'Warn'    { '[!]' }
        'Error'   { '[x]' }
        'Dry'     { '[DRYRUN]' }
    }
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-EXOConnection {
    # Get-ConnectionInformation can report a stale/leftover session even after
    # the underlying runspace has dropped (expired token, network blip, an
    # incomplete Disconnect-ExchangeOnline, etc). Trust it only if there's a
    # live, connected entry AND the cmdlets it grants are actually loaded.
    try {
        $connections = Get-ConnectionInformation -ErrorAction Stop
    }
    catch {
        return $false
    }

    if (-not $connections) {
        return $false
    }

    $liveConnection = $connections | Where-Object {
        $_.State -eq 'Connected' -and $_.TokenStatus -eq 'Active'
    }

    if (-not $liveConnection) {
        return $false
    }

    if (-not (Get-Command -Name Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        return $false
    }

    return $true
}
#endregion

#region Connect
try {
    if (-not (Test-EXOConnection)) {
        Write-Status "Not connected (or session is stale). Reconnecting..." -Level Info

        try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}

        if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
            Write-Status "ExchangeOnlineManagement module is not installed. Run: Install-Module ExchangeOnlineManagement -Scope CurrentUser" -Level Error
            return
        }

        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop

        if (-not (Test-EXOConnection)) {
            Write-Status "Connected, but Get-DistributionGroup still isn't available. Check your assigned role (needs Recipient Management or similar)." -Level Error
            return
        }
    }
    else {
        Write-Status "Already connected to Exchange Online." -Level Success
    }
}
catch {
    Write-Status "Failed to connect to Exchange Online: $($_.Exception.Message)" -Level Error
    return
}
#endregion

#region Validate source group
# Microsoft 365 Groups are group-mailbox-backed and are NOT readable via
# Get-DistributionGroup ("The current operation is not supported on
# GroupMailbox."). Get-UnifiedGroup / Get-UnifiedGroupLinks are the correct
# EXO cmdlets for M365 Groups.
try {
    Write-Status "Looking up source group '$SourceGroup'..." -Level Info
    $sourceGroupObj = Get-UnifiedGroup -Identity $SourceGroup -ErrorAction Stop
    Write-Status "Found source group: $($sourceGroupObj.DisplayName) <$($sourceGroupObj.PrimarySmtpAddress)>" -Level Success
}
catch {
    Write-Status "Could not find source group '$SourceGroup': $($_.Exception.Message)" -Level Error
    return
}
#endregion

#region Guard: target address must not collide with the source group
# Exchange Online requires every email address / proxy address to be unique
# across all recipient types in the tenant. Reusing the source M365 Group's
# primary or any proxy address for the new security group will fail — check
# for it up front with a clear, specific error rather than letting
# New-DistributionGroup throw a generic "address already in use" error.
$sourceAddresses = @($sourceGroupObj.PrimarySmtpAddress) + `
    ($sourceGroupObj.EmailAddresses | ForEach-Object { ($_ -split ':')[-1] })
$sourceAddresses = $sourceAddresses | Select-Object -Unique

if ($sourceAddresses -contains $TargetEmailAddress) {
    Write-Status "TargetEmailAddress '$TargetEmailAddress' matches an address already used by the source group '$SourceGroup'. Choose a distinct address for the new mail-enabled security group and try again." -Level Error
    return
}
#endregion

#region Retrieve source membership
try {
    Write-Status "Retrieving members of '$SourceGroup'..." -Level Info
    $members = @(Get-UnifiedGroupLinks -Identity $SourceGroup -LinkType Members -ResultSize Unlimited -ErrorAction Stop)
    Write-Status "Found $($members.Count) member(s) in '$SourceGroup'." -Level Success

    if ($IncludeOwners) {
        Write-Status "Retrieving owners of '$SourceGroup' (-IncludeOwners specified)..." -Level Info
        $owners = @(Get-UnifiedGroupLinks -Identity $SourceGroup -LinkType Owners -ResultSize Unlimited -ErrorAction Stop)
        Write-Status "Found $($owners.Count) owner(s) in '$SourceGroup'." -Level Success

        $existingIdentities = $members | ForEach-Object { $_.PrimarySmtpAddress }
        $newOwners = $owners | Where-Object { $_.PrimarySmtpAddress -notin $existingIdentities }
        $members = @($members) + @($newOwners)
    }
}
catch {
    Write-Status "Failed to retrieve members of '$SourceGroup': $($_.Exception.Message)" -Level Error
    return
}

if ($members.Count -eq 0) {
    Write-Status "Source group has no members (or owners, if included). Nothing to copy — the target group will still be created." -Level Warn
}
#endregion

#region Dry run summary
if ($DryRun) {
    Write-Status "===== DRY RUN SUMMARY (no changes will be made) =====" -Level Dry
    Write-Status "Would create mail-enabled security group:" -Level Dry
    Write-Host "    Name:          $TargetGroup" -ForegroundColor Magenta
    Write-Host "    Email address: $TargetEmailAddress" -ForegroundColor Magenta
    Write-Host "    Type:          Security (mail-enabled)" -ForegroundColor Magenta
    Write-Status "Would add $($members.Count) member(s):" -Level Dry
    $members | ForEach-Object {
        Write-Host "    - $($_.DisplayName) <$($_.PrimarySmtpAddress)>" -ForegroundColor DarkGray
    }
    Write-Status "===== END DRY RUN =====" -Level Dry
    return
}
#endregion

#region Create target group
try {
    $existingTarget = Get-DistributionGroup -Identity $TargetGroup -ErrorAction SilentlyContinue
}
catch {
    $existingTarget = $null
}

if ($existingTarget) {
    Write-Status "Target group '$TargetGroup' already exists — skipping creation." -Level Warn

    if ($existingTarget.PrimarySmtpAddress -ne $TargetEmailAddress) {
        Write-Status "Note: existing '$TargetGroup' has address '$($existingTarget.PrimarySmtpAddress)', which differs from the -TargetEmailAddress you supplied ('$TargetEmailAddress'). The existing address was left unchanged." -Level Warn
    }

    $targetGroupObj = $existingTarget
}
else {
    $createParams = @{
        Name               = $TargetGroup
        DisplayName        = $TargetGroup
        Alias              = ($TargetEmailAddress.Split('@')[0])
        PrimarySmtpAddress = $TargetEmailAddress
        Type               = 'Security'
    }

    if ($PSCmdlet.ShouldProcess($TargetGroup, "Create mail-enabled security group ($TargetEmailAddress)")) {
        try {
            Write-Status "Creating mail-enabled security group '$TargetGroup'..." -Level Info
            $targetGroupObj = New-DistributionGroup @createParams -ErrorAction Stop
            Write-Status "Created '$TargetGroup' <$TargetEmailAddress>." -Level Success
        }
        catch {
            Write-Status "Failed to create target group: $($_.Exception.Message)" -Level Error
            return
        }
    }
    else {
        Write-Status "ShouldProcess declined group creation — stopping." -Level Warn
        return
    }
}
#endregion

#region Copy membership
$added   = 0
$skipped = 0
$failed  = 0

foreach ($member in $members) {
    $memberIdentity = $member.PrimarySmtpAddress

    try {
        $alreadyMember = Get-DistributionGroupMember -Identity $TargetGroup -ResultSize Unlimited -ErrorAction Stop |
            Where-Object { $_.PrimarySmtpAddress -eq $memberIdentity }

        if ($alreadyMember) {
            Write-Status "$($member.DisplayName) is already a member of '$TargetGroup' — skipping." -Level Warn
            $skipped++
            continue
        }

        if ($PSCmdlet.ShouldProcess($member.DisplayName, "Add to '$TargetGroup'")) {
            Add-DistributionGroupMember -Identity $TargetGroup -Member $memberIdentity -ErrorAction Stop
            Write-Status "Added $($member.DisplayName) <$memberIdentity>." -Level Success
            $added++
        }
    }
    catch {
        Write-Status "Failed to add $($member.DisplayName): $($_.Exception.Message)" -Level Error
        $failed++
    }
}
#endregion

#region Final summary
Write-Status "===== SUMMARY =====" -Level Info
Write-Host "    Added:   $added" -ForegroundColor Green
Write-Host "    Skipped: $skipped (already members)" -ForegroundColor Yellow
Write-Host "    Failed:  $failed" -ForegroundColor Red
Write-Status "Done." -Level Success
#endregion