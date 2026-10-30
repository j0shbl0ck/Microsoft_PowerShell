<#
.SYNOPSIS
    Toggles the Outlook "Team: {Manager Name}" (reporting line group) calendar on or off.

.DESCRIPTION
    Checks for running Outlook processes (classic outlook.exe and new Outlook olk.exe),
    prompts the user before force-closing them, then sets or removes the per-user
    DisableReportingLineGroupCalendar value under:

        HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\WunderBar

    Hide   -> DisableReportingLineGroupCalendar = 1 (DWORD)
    Show   -> value removed
    Toggle -> flips whichever state is current (default)

.PARAMETER TeamCalendar
    Show, Hide, or Toggle. Default: Toggle.

.PARAMETER Force
    Skip the close-Outlook prompt (use for silent / Intune user-context runs).

.PARAMETER Restart
    Relaunch whichever Outlook client(s) were running before the change.

.NOTES
    Author:  Josh Block
    GitHub:  https://github.com/j0shbl0ck
    Version: 1.0.0
    Context: Run as the signed-in user (HKCU). Not as SYSTEM.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [ValidateSet('Show', 'Hide', 'Toggle')]
    [string]$TeamCalendar = 'Toggle',

    [switch]$Force,

    [switch]$Restart
)

#region Variables
$RegPath   = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Options\WunderBar'
$ValueName = 'DisableReportingLineGroupCalendar'

# Process names only - the olk.exe WindowsApps path changes with every update
$OutlookProcesses = @(
    @{ Name = 'OUTLOOK'; Label = 'Outlook (classic)' }
    @{ Name = 'olk';     Label = 'Outlook (new)' }
)

# AUMID for relaunching new Outlook without hardcoding the versioned path
$NewOutlookAumid = 'shell:AppsFolder\Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows'
#endregion

#region Functions
function Get-CurrentState {
    try {
        $val = Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction Stop |
               Select-Object -ExpandProperty $ValueName
        if ($val -eq 1) { return 'Hidden' }
    }
    catch { }
    return 'Shown'
}

function Close-Outlook {
    param ([array]$Running)

    foreach ($p in $Running) {
        Write-Host "  Closing $($p.Label)..." -ForegroundColor Yellow

        # Try graceful close first so Outlook can flush OST/PST writes
        Get-Process -Name $p.Name -ErrorAction SilentlyContinue | ForEach-Object {
            [void]$_.CloseMainWindow()
        }

        $timeout = 15
        while ((Get-Process -Name $p.Name -ErrorAction SilentlyContinue) -and $timeout -gt 0) {
            Start-Sleep -Seconds 1
            $timeout--
        }

        # Force anything still hanging on
        if (Get-Process -Name $p.Name -ErrorAction SilentlyContinue) {
            Write-Host "  $($p.Label) did not exit gracefully - forcing close." -ForegroundColor DarkYellow
            Stop-Process -Name $p.Name -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
        }

        Write-Host "  $($p.Label) closed." -ForegroundColor Green
    }
}
#endregion

#region Main
Write-Host ''
Write-Host '=== Outlook Team Calendar Toggle ===' -ForegroundColor Cyan

$current = Get-CurrentState
Write-Host "Current state : Team calendar is $current" -ForegroundColor Gray

# Resolve target state
switch ($TeamCalendar) {
    'Show'   { $target = 'Shown' }
    'Hide'   { $target = 'Hidden' }
    'Toggle' { $target = if ($current -eq 'Hidden') { 'Shown' } else { 'Hidden' } }
}
Write-Host "Target state  : Team calendar will be $target" -ForegroundColor Gray
Write-Host ''

if ($current -eq $target) {
    Write-Host 'Already in the requested state. Nothing to do.' -ForegroundColor Green
    return
}

# --- Check for running Outlook ---
$running = $OutlookProcesses | Where-Object { Get-Process -Name $_.Name -ErrorAction SilentlyContinue }

if ($running) {
    Write-Host 'Outlook is currently running:' -ForegroundColor Yellow
    $running | ForEach-Object { Write-Host "  - $($_.Label)" -ForegroundColor Yellow }

    if (-not $Force -and -not $WhatIfPreference) {
        $answer = Read-Host 'Outlook must be closed to apply this change. Close it now? (Y/N)'
        if ($answer -notmatch '^(y|yes)$') {
            Write-Host 'Cancelled. No changes made.' -ForegroundColor Red
            return
        }
    }

    if ($PSCmdlet.ShouldProcess(($running.Label -join ', '), 'Close')) {
        try {
            Close-Outlook -Running $running
        }
        catch {
            Write-Host "Failed to close Outlook: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }
}
else {
    Write-Host 'Outlook is not running.' -ForegroundColor Green
}

# --- Apply registry change ---
try {
    if ($target -eq 'Hidden') {
        if ($PSCmdlet.ShouldProcess("$RegPath\$ValueName", 'Set DWORD = 1')) {
            if (-not (Test-Path $RegPath)) {
                New-Item -Path $RegPath -Force | Out-Null
            }
            New-ItemProperty -Path $RegPath -Name $ValueName -PropertyType DWord -Value 1 -Force | Out-Null
            Write-Host 'Team calendar HIDDEN (DisableReportingLineGroupCalendar = 1).' -ForegroundColor Green
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess("$RegPath\$ValueName", 'Remove value')) {
            Remove-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction SilentlyContinue
            Write-Host 'Team calendar SHOWN (DisableReportingLineGroupCalendar removed).' -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Registry update failed: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# --- Optional relaunch ---
if ($Restart -and $running -and -not $WhatIfPreference) {
    Write-Host ''
    foreach ($p in $running) {
        Write-Host "Relaunching $($p.Label)..." -ForegroundColor Cyan
        try {
            if ($p.Name -eq 'olk') { Start-Process $NewOutlookAumid }
            else                   { Start-Process 'outlook.exe' }
        }
        catch {
            Write-Host "  Could not relaunch $($p.Label): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
}
elseif ($running) {
    Write-Host 'Reopen Outlook to see the change.' -ForegroundColor Gray
}

Write-Host ''
#endregion