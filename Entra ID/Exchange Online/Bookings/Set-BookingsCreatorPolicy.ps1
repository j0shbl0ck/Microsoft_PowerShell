<#
.SYNOPSIS
    Clones the default OWA mailbox policy into a Bookings-creator policy, assigns it to M365 Administration Team members, and turns off shared booking page creation on the default policy.

.NOTES
    Author: Josh Block
    Date: 11.17.2026
    Type: Public
    Version: 1.1.0

.LINK
    https://github.com/j0shbl0ck
    https://learn.microsoft.com/en-us/microsoft-365/bookings/bookings-mailbox-policy
    https://learn.microsoft.com/en-us/powershell/module/exchange/new-owamailboxpolicy
    https://learn.microsoft.com/en-us/powershell/module/exchange/set-owamailboxpolicy
#>

# Requires ExchangeOnlineManagement. Run as Exchange Admin or Global Admin.
# Order matters: team members are moved to the new policy BEFORE the default is locked down,
# so nobody on the team loses creation rights in between.

Clear-Host

#region Config
$DefaultPolicyName = "Default+EnableSharedBookingPages"

# Set-OwaMailboxPolicy parameters that must not be copied from the default
$ExcludeParams = @(
    "Identity", "Name", "IsDefault", "DomainController", "Force",
    "Confirm", "WhatIf", "Verbose", "Debug", "ErrorAction", "WarningAction", "InformationAction",
    "ErrorVariable", "WarningVariable", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable", "ProgressAction"
)
#endregion

#region Functions
function Write-Step    { param([string]$m) Write-Host "`n>> $m" -ForegroundColor Cyan }
function Write-Ok      { param([string]$m) Write-Host "   [OK]   $m" -ForegroundColor Green }
function Write-Warn    { param([string]$m) Write-Host "   [WARN] $m" -ForegroundColor Yellow }
function Write-Fail    { param([string]$m) Write-Host "   [FAIL] $m" -ForegroundColor Red }

function Convert-PolicyValue {
    param($Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) { return [string[]]@($Value | ForEach-Object { "$_" }) }
    if ($Value -is [bool] -or $Value -is [int] -or $Value -is [long]) { return $Value }
    return "$Value"
}
#endregion

#region Module check / connect
Write-Step "Checking ExchangeOnlineManagement"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Fail "ExchangeOnlineManagement is not installed. Run your module installer first."
    return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-Ok "Module loaded"

Write-Step "Connecting to Exchange Online"
try {
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue | Where-Object State -eq "Connected")) {
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    }
    Write-Ok "Connected"
}
catch {
    Write-Fail "Exchange Online connection failed: $($_.Exception.Message)"
    return
}
#endregion

#region Prompts
Write-Host "`n=== Bookings Creator Policy Setup ===" -ForegroundColor White

$PolicyName = Read-Host "New policy name [$DefaultPolicyName]"
if ([string]::IsNullOrWhiteSpace($PolicyName)) { $PolicyName = $DefaultPolicyName }

Write-Host "`nEnter M365 Administration Team members who should be able to create shared booking pages." -ForegroundColor Gray
$Members = [System.Collections.Generic.List[object]]::new()
while ($true) {
    if ($Members.Count -ge 1 -and (Read-Host "Add another member? (Y/N) [N]") -notmatch '^[Yy]') { break }
    $upn = (Read-Host "Member UPN").Trim()
    if ([string]::IsNullOrWhiteSpace($upn)) { continue }
    try {
        $cas = Get-CASMailbox -Identity $upn -ErrorAction Stop
        if ($Members.Identity -contains $cas.Identity) { Write-Warn "$upn is already in the list."; continue }
        $Members.Add($cas)
        Write-Ok "$($cas.DisplayName) (current policy: $(if ($cas.OwaMailboxPolicy) { $cas.OwaMailboxPolicy } else { 'Default' }))"
    }
    catch { Write-Warn "No mailbox found for '$upn'. Try again." }
}

$DisableDefault = (Read-Host "`nTurn OFF shared booking creation on the default policy after assigning? (Y/N) [Y]") -notmatch '^[Nn]'
#endregion

#region Read default policy
Write-Step "Reading the default OWA mailbox policy"
$Default = Get-OwaMailboxPolicy | Where-Object IsDefault | Select-Object -First 1
if (-not $Default) { Write-Fail "No default OWA mailbox policy found. Aborting."; return }
Write-Ok "Default policy: $($Default.Name) (BookingsMailboxCreationEnabled = $($Default.BookingsMailboxCreationEnabled))"

# Build the list of copyable settings from Set-OwaMailboxPolicy's own parameters
$SetCmd   = Get-Command Set-OwaMailboxPolicy
$Copyable = $SetCmd.Parameters.Values | Where-Object {
    $_.Name -notin $ExcludeParams -and
    $_.ParameterType -ne [System.Management.Automation.SwitchParameter] -and
    $Default.PSObject.Properties[$_.Name]
}

$Settings = @{}
foreach ($p in $Copyable) {
    $val = Convert-PolicyValue $Default.($p.Name)
    if ($null -ne $val) { $Settings[$p.Name] = $val }
}
$Settings["BookingsMailboxCreationEnabled"] = $true   # the one intentional difference
Write-Ok "$($Settings.Count) settings will be copied (BookingsMailboxCreationEnabled forced to True)"
#endregion

#region Create and clone policy
Write-Step "Creating policy '$PolicyName'"
$Existing = Get-OwaMailboxPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
try {
    if (-not $Existing) {
        New-OwaMailboxPolicy -Name $PolicyName -ErrorAction Stop | Out-Null
        Write-Ok "Created"
    }
    else { Write-Warn "Policy already exists - re-syncing settings from the default" }

    # Try in one shot, fall back to one setting at a time so a single bad value doesn't block the rest
    try {
        Set-OwaMailboxPolicy -Identity $PolicyName @Settings -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Ok "All settings copied"
    }
    catch {
        Write-Warn "Bulk copy failed ($($_.Exception.Message)). Copying settings individually..."
        $failed = @()
        foreach ($k in $Settings.Keys) {
            try {
                $one = @{ $k = $Settings[$k] }
                Set-OwaMailboxPolicy -Identity $PolicyName @one -ErrorAction Stop -WarningAction SilentlyContinue
            }
            catch { $failed += $k }
        }
        if ($failed) { Write-Warn "Could not copy: $($failed -join ', ')" }
        else         { Write-Ok "All settings copied individually" }
    }
}
catch {
    Write-Fail "Policy creation failed: $($_.Exception.Message)"
    return
}
#endregion

#region Verify clone
Write-Step "Comparing '$PolicyName' to '$($Default.Name)'"
$New   = Get-OwaMailboxPolicy -Identity $PolicyName
$diffs = foreach ($k in $Settings.Keys) {
    $a = (@(Convert-PolicyValue $Default.$k) -join ";")
    $b = (@(Convert-PolicyValue $New.$k)     -join ";")
    if ($a -ne $b) { [PSCustomObject]@{ Setting = $k; Default = $a; NewPolicy = $b } }
}
$diffs = $diffs | Where-Object Setting -ne "BookingsMailboxCreationEnabled"
if ($diffs) { Write-Warn "Differences found:"; $diffs | Format-Table -AutoSize }
else        { Write-Ok "Matches the default except BookingsMailboxCreationEnabled = True" }
#endregion

#region Assign members
Write-Step "Assigning '$PolicyName' to $($Members.Count) member(s)"
foreach ($m in $Members) {
    try {
        Set-CASMailbox -Identity $m.Identity -OwaMailboxPolicy $PolicyName -ErrorAction Stop
        Write-Ok "$($m.PrimarySmtpAddress)"
    }
    catch { Write-Fail "$($m.PrimarySmtpAddress): $($_.Exception.Message)" }
}
#endregion

#region Lock down default
if ($DisableDefault) {
    Write-Step "Turning OFF shared booking creation on '$($Default.Name)'"
    if ((Read-Host "Confirm: disable shared booking creation for everyone on the default policy? (Y/N) [N]") -match '^[Yy]') {
        try {
            Set-OwaMailboxPolicy -Identity $Default.Identity -BookingsMailboxCreationEnabled $false -ErrorAction Stop
            Write-Ok "Default policy locked down"
        }
        catch { Write-Fail "Could not update default policy: $($_.Exception.Message)" }
    }
    else { Write-Warn "Skipped - default policy unchanged" }
}
#endregion

#region Summary
Write-Host "`n================ SUMMARY ================" -ForegroundColor White
Write-Host "Creator policy  : $PolicyName"
Write-Host "Members         : $(($Members | ForEach-Object PrimarySmtpAddress) -join ', ')"
Write-Host "Default policy  : $($Default.Name)$(if ($DisableDefault) { ' (creation disabled)' } else { ' (unchanged)' })"
Write-Host "=========================================" -ForegroundColor White
Write-Host "Policy changes can take up to an hour or more to apply in Bookings / OWA." -ForegroundColor Gray
Write-Host "`nDone." -ForegroundColor Green
#endregion