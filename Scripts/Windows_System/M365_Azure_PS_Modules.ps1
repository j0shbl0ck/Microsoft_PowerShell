#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs and updates the core M365 and Azure PowerShell modules.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 2.3.2
    Date: 08.20.26
    Type: Public

    Changes from v2.3.1:
      - Removed MSOnline and AzureAD from $script:ModuleTable. Both modules
        are fully retired by Microsoft (MSOnline retired Apr-May 2025,
        AzureAD/AzureADPreview retired starting mid-Oct 2025) and are no
        longer resolvable on PSGallery -- they were producing the "Could not
        resolve a version ... (empty result)" error added in v2.3.1, working
        exactly as designed against a module that no longer exists there.
        Microsoft.Graph (already tracked) is the supported replacement for
        both; see the Module table region below for the full note.

    Changes from v2.3.0 (bugfix release):
      - FIXED: [PowerShell]::EndInvoke() returns a PSDataCollection<PSObject>,
        not a plain value. Complete-AsyncScript was assigning that collection
        straight into Result without unwrapping it, so every already-installed
        module's version comparison threw "Cannot convert ... PSDataCollection
        ... to type System.Version" and failed. Worse, modules being installed
        for the first time skipped that comparison and passed the broken
        value straight into -RequiredVersion, silently installing with a
        blank/undefined version instead of erroring. Now unwraps via @() and
        extracts a scalar when there's exactly one result.
      - Added explicit checks after every Find-Module/Find-Script resolution:
        if the resolved version comes back empty, the script now throws a
        clear error for that module instead of silently continuing.
      - FIXED false positive in Test-ModulePathHealth: PowerShell 7+ and
        Windows PowerShell 5.1 each have their own module roots by design, so
        a module living in both (e.g. under C:\Program Files\PowerShell\
        Modules AND C:\Program Files\WindowsPowerShell\Modules) is expected,
        not scope fragmentation. The check now buckets by PowerShell edition
        first and only flags duplicates within the same edition.

    Changes from v2.2.0:
      - New self-healing pre-flight pass: Repair-DuplicateModuleVersions scans
        every module in $script:ModuleTable, plus a Microsoft.Graph.* wildcard
        sweep (since the meta-package's 47+ submodules aren't individually
        listed), for more than one installed version. Anything older than the
        newest gets uninstalled automatically. This is what makes the script
        self-correcting on repeat runs -- including cleaning up leftovers from
        the pre-2.2.0 version of this script that didn't fully remove
        Microsoft.Graph submodules on update.
      - Get-AutopilotDiagnostics (the one Script-type entry) now gets the same
        update-and-replace treatment as modules: it checks Find-Script for a
        newer version and uninstalls/reinstalls if out of date, instead of
        only ever installing once and never touching it again.
      - New -SkipDuplicateCleanup switch to skip the pre-flight dedup pass.

    Changes from v2.1.0:
      - Fixed the actual root cause behind the recurring Graph submodule
        version mismatch: Microsoft.Graph is a meta-package with no cmdlets
        of its own -- it just lists 47+ service modules as dependencies, and
        Uninstall-Module Microsoft.Graph only ever removed that thin
        meta-package, not the submodules it pulled in. Old submodule versions
        were quietly piling up on every update. The update path now runs
        Uninstall-MicrosoftGraphFully, which follows Microsoft's documented
        cleanup order: every Microsoft.Graph.* submodule first, then
        Microsoft.Graph.Authentication (everything else depends on it), then
        the meta-package -- before the fresh install pulls the full tree back
        down at the target version.
      - Note: this script installs the v1.0 SDK (Microsoft.Graph) only, not
        Microsoft.Graph.Beta. Add it to $script:ModuleTable if you need beta
        endpoint cmdlets too.

    Changes from v2.0.0:
      - Winget-style live UI: braille spinner while resolving the latest
        version from PSGallery, then a redrawing progress bar while the
        install/uninstall runs, ending in a "Found X [v]" / checkmark line.
      - Installs now run in a background runspace (BeginInvoke/EndInvoke) so
        the console can animate while Install-Module is working, instead of
        the terminal just freezing until it returns.
      - IMPORTANT: Install-Module does not expose real byte-level download
        progress (unlike winget's downloader). The install bar below is a
        smooth time-based approximation that eases toward 95% and snaps to
        100% on completion -- it's a "still working" indicator, not a
        literal download percentage. Flagging this so it's never mistaken
        for real telemetry later.
      - PSGallery is set to Trusted up front. This is required so the
        background runspace never hits an interactive untrusted-repository
        prompt it has no way to answer (that would hang silently).

    Changes carried over from v2.0.0:
      - All installs forced to -Scope AllUsers so modules land in ONE
        consistent location (C:\Program Files\WindowsPowerShell\Modules)
        instead of split between CurrentUser and AllUsers paths -- the
        actual fix for the Microsoft.Graph.Authentication-vs-other-submodule
        version mismatch. Modules are NOT installed to System32; that path
        is reserved for Windows PowerShell's inbox modules.
      - Pre-flight scan flags any module already split across multiple
        PSModulePath locations before installing anything.
      - Data-driven module table instead of ~15 near-duplicate functions.
      - -WhatIf / -Confirm support via SupportsShouldProcess.
.PARAMETER SkipPathHealthCheck
    Skip the pre-flight scan for modules duplicated across PSModulePath scopes.
.PARAMETER SkipDuplicateCleanup
    Skip the pre-flight scan/removal of duplicate installed versions of any module.
.NOTES
    To use Microsoft Graph Intune, run once after install: Connect-MSGraph -AdminConsent
.LINK
    Source: https://o365reports.com/2019/11/01/install-all-office-365-powershell-modules/
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipPathHealthCheck,
    [switch]$SkipDuplicateCleanup
)

#region Console setup
Clear-Host
$Host.UI.RawUI.WindowTitle = "M365 / Azure PowerShell Module Installer"

$script:Symbols = @{
    OK    = [char]0x2713   # check mark
    FAIL  = [char]0x2717   # cross mark
    WARN  = [char]0x26A0   # warning triangle
    ARROW = [char]0x2192   # right arrow
}
$script:SpinnerFrames = @(
    [char]0x280B, [char]0x2819, [char]0x2839, [char]0x2838, [char]0x283C,
    [char]0x2834, [char]0x2826, [char]0x2827, [char]0x2807, [char]0x280F
)
$script:BlockFull  = [char]0x2588
$script:BlockEmpty = [char]0x2591
#endregion

#region Visual helpers
function Write-Banner {
    $line = ('=' * 63)
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "               M365 / Azure PowerShell Modules               " -ForegroundColor Cyan
    Write-Host "                        v2.3.2 - j0shbl0ck                    " -ForegroundColor DarkCyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-SectionHeader {
    param([string]$Text)
    Write-Host ""
    Write-Host " $Text" -ForegroundColor Magenta
    Write-Host (' ' + ('-' * $Text.Length)) -ForegroundColor DarkGray
}

function Clear-ConsoleLine {
    Write-Host -NoNewline ("`r" + (' ' * 100) + "`r")
}

function Write-StepResult {
    param(
        [Parameter(Mandatory)][ValidateSet('OK', 'INSTALL', 'UPDATE', 'SKIP', 'FAIL', 'WARN')]
        [string]$Tag,
        [Parameter(Mandatory)][string]$Message
    )
    $colorMap = @{ OK = 'Green'; INSTALL = 'Yellow'; UPDATE = 'Yellow'; SKIP = 'DarkGray'; FAIL = 'Red'; WARN = 'DarkYellow' }
    Clear-ConsoleLine
    Write-Host ("  [{0,-7}] " -f $Tag) -ForegroundColor $colorMap[$Tag] -NoNewline
    Write-Host $Message
}
#endregion

#region Async runspace helpers (what makes the live animation possible)
function Invoke-AsyncScript {
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @()
    )
    $ps = [System.Management.Automation.PowerShell]::Create()
    [void]$ps.AddScript($ScriptBlock)
    foreach ($arg in $ArgumentList) { [void]$ps.AddArgument($arg) }
    $handle = $ps.BeginInvoke()
    [PSCustomObject]@{ PowerShell = $ps; Handle = $handle }
}

function Complete-AsyncScript {
    param([Parameter(Mandatory)]$AsyncOp)
    try {
        # EndInvoke returns a PSDataCollection<PSObject>, not a plain value --
        # wrapping it in @() unwraps that collection into a real PowerShell
        # array so callers get the actual output object(s), not the wrapper.
        $raw = $AsyncOp.PowerShell.EndInvoke($AsyncOp.Handle)
    } catch {
        $raw = $null
    }
    $resultArray = @($raw)
    if ($resultArray.Count -eq 0) {
        $result = $null
    } elseif ($resultArray.Count -eq 1) {
        $result = $resultArray[0]
    } else {
        $result = $resultArray
    }
    $errors = $AsyncOp.PowerShell.Streams.Error
    $AsyncOp.PowerShell.Dispose()
    [PSCustomObject]@{ Result = $result; Errors = $errors }
}

# Spinner-only: for quick lookups like Find-Module resolution.
function Show-ResolvingSpinner {
    param(
        [Parameter(Mandatory)]$AsyncOp,
        [Parameter(Mandatory)][string]$Label
    )
    $tick = 0
    while (-not $AsyncOp.Handle.IsCompleted) {
        $spin = $script:SpinnerFrames[$tick % $script:SpinnerFrames.Count]
        Write-Host -NoNewline ("`r  {0} {1}" -f $spin, $Label.PadRight(50)) -ForegroundColor DarkCyan
        $tick++
        Start-Sleep -Milliseconds 90
    }
    Clear-ConsoleLine
    Complete-AsyncScript -AsyncOp $AsyncOp
}

# Winget-style redrawing bar with eased pseudo-progress. See header note:
# this is time-based, not a literal byte count.
function Show-DownloadStyleProgress {
    param(
        [Parameter(Mandatory)]$AsyncOp,
        [Parameter(Mandatory)][string]$Label,
        [string]$DoneLabel
    )
    if (-not $DoneLabel) { $DoneLabel = $Label }
    $barLength = 32
    $tick = 0
    $start = Get-Date

    while (-not $AsyncOp.Handle.IsCompleted) {
        $elapsedSec = ((Get-Date) - $start).TotalSeconds
        $pct = [math]::Min(95, [int](95 * (1 - [math]::Exp(-$elapsedSec / 3))))
        $filled = [math]::Round(($barLength * $pct) / 100)
        $bar = ($script:BlockFull.ToString() * $filled) + ($script:BlockEmpty.ToString() * ($barLength - $filled))
        $spin = $script:SpinnerFrames[$tick % $script:SpinnerFrames.Count]

        Write-Host -NoNewline ("`r  {0} " -f $spin) -ForegroundColor Cyan
        Write-Host -NoNewline ("[{0}] " -f $bar) -ForegroundColor Green
        Write-Host -NoNewline ("{0,3}%  " -f $pct) -ForegroundColor White
        Write-Host -NoNewline ($Label.PadRight(42).Substring(0, 42)) -ForegroundColor Gray

        $tick++
        Start-Sleep -Milliseconds 90
    }

    $bar = $script:BlockFull.ToString() * $barLength
    Clear-ConsoleLine
    Write-Host -NoNewline ("  {0} " -f $script:Symbols.OK) -ForegroundColor Green
    Write-Host -NoNewline ("[{0}] " -f $bar) -ForegroundColor Green
    Write-Host -NoNewline "100%  " -ForegroundColor White
    Write-Host $DoneLabel.PadRight(42).Substring(0, 42) -ForegroundColor Gray

    Complete-AsyncScript -AsyncOp $AsyncOp
}
#endregion

#region Admin / environment checks
function Test-IsAdmin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  $($script:Symbols.FAIL) This script must be run as an administrator." -ForegroundColor Red
        Write-Host "     Closing in 5 seconds..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 5
        exit 1
    }
}

function Set-GalleryTrust {
    # Required so the background runspace never hits an interactive
    # untrusted-repository prompt it has no way to answer.
    $repo = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
    if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
        if ($PSCmdlet.ShouldProcess('PSGallery', 'Set InstallationPolicy to Trusted')) {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        }
        Write-StepResult -Tag OK -Message "PSGallery set to Trusted (required for background installs)."
    }
}

function Get-ModulePathEdition {
    # PowerShell 7+ and Windows PowerShell 5.1 each have their own AllUsers/
    # CurrentUser module roots by design (e.g. C:\Program Files\PowerShell\
    # Modules vs C:\Program Files\WindowsPowerShell\Modules). A module
    # legitimately living in both is expected when both editions are in use
    # on a box -- it is NOT the CurrentUser/AllUsers scope-fragmentation this
    # check exists to catch, so it's bucketed separately and not flagged.
    param([string]$Root)
    if ($Root -match 'WindowsPowerShell') { 'WindowsPowerShell (5.1)' } else { 'PowerShell (7+)' }
}

function Test-ModulePathHealth {
    Write-SectionHeader "Pre-flight: checking for scope-fragmented modules"

    $namesToCheck = $script:ModuleTable | Where-Object { $_.Type -eq 'Module' } | Select-Object -ExpandProperty Name
    $flagged = @()

    foreach ($name in $namesToCheck) {
        $installed = Get-Module -ListAvailable -Name $name -ErrorAction SilentlyContinue
        if (-not $installed) { continue }

        $roots = $installed |
            ForEach-Object { Split-Path (Split-Path $_.ModuleBase -Parent) -Parent } |
            Sort-Object -Unique |
            ForEach-Object { [PSCustomObject]@{ Root = $_; Edition = Get-ModulePathEdition $_ } }

        foreach ($editionGroup in ($roots | Group-Object -Property Edition)) {
            if ($editionGroup.Count -gt 1) {
                $flagged += [PSCustomObject]@{
                    Name      = $name
                    Edition   = $editionGroup.Name
                    Locations = ($editionGroup.Group.Root -join ' | ')
                }
            }
        }
    }

    if ($flagged.Count -eq 0) {
        Write-StepResult -Tag OK -Message "No modules found split across multiple PSModulePath locations within the same PowerShell edition."
    } else {
        Write-StepResult -Tag WARN -Message "Found $($flagged.Count) module(s) split within a single PowerShell edition:"
        foreach ($f in $flagged) {
            Write-Host "             $($script:Symbols.ARROW) $($f.Name) [$($f.Edition)]" -ForegroundColor DarkYellow
            Write-Host "               $($f.Locations)" -ForegroundColor DarkGray
        }
        Write-Host "             This is the usual cause of submodule version mismatches" -ForegroundColor DarkGray
        Write-Host "             (e.g. Microsoft.Graph.Authentication resolving to a" -ForegroundColor DarkGray
        Write-Host "             different version than its sibling Graph modules)." -ForegroundColor DarkGray
        Write-Host "             This script installs everything to -Scope AllUsers going" -ForegroundColor DarkGray
        Write-Host "             forward; consider removing the CurrentUser-scope copies" -ForegroundColor DarkGray
        Write-Host "             with Uninstall-Module once you've confirmed nothing else" -ForegroundColor DarkGray
        Write-Host "             depends on them." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "             Note: a module appearing under both PowerShell (7+) and" -ForegroundColor DarkGray
    Write-Host "             WindowsPowerShell (5.1) roots is expected and not flagged --" -ForegroundColor DarkGray
    Write-Host "             those are separate module paths by design, one per edition." -ForegroundColor DarkGray
    Write-Host ""
}
#endregion

#region Microsoft.Graph full-tree cleanup
# The Microsoft.Graph meta-package has no cmdlets of its own -- it just lists
# every service module (47+ as of mid-2026) as a dependency, and installing it
# pulls the whole tree. But "Uninstall-Module Microsoft.Graph" only removes
# that thin meta-package, NOT the 47+ submodules it pulled in. Left alone,
# that's exactly how you end up with old submodule versions sitting next to
# new ones -- which is what produces the Authentication-vs-sibling-module
# mismatch. This follows Microsoft's own documented cleanup order: every
# Microsoft.Graph.* submodule first, Microsoft.Graph.Authentication last
# (everything else depends on it), then the meta-package itself.
function Uninstall-MicrosoftGraphFully {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess('Microsoft.Graph (all submodules)', 'Full uninstall')) { return }

    $op = Invoke-AsyncScript -ScriptBlock {
        Get-InstalledModule -Name 'Microsoft.Graph.*' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'Microsoft.Graph.Authentication' } |
            ForEach-Object { Uninstall-Module -Name $_.Name -AllVersions -Force -Confirm:$false -ErrorAction SilentlyContinue }

        Uninstall-Module -Name 'Microsoft.Graph.Authentication' -AllVersions -Force -Confirm:$false -ErrorAction SilentlyContinue
        Uninstall-Module -Name 'Microsoft.Graph' -AllVersions -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
    [void](Show-ResolvingSpinner -AsyncOp $op -Label "Removing all Microsoft.Graph submodules (this can take a bit)...")
}
#endregion

#region Self-healing duplicate version cleanup
# Makes every run converge to "one version per module" on its own, instead of
# relying on a human to notice stragglers. Covers every module in the table
# plus a Microsoft.Graph.* wildcard sweep (the 47+ submodules aren't
# individually listed there). Safe to re-run: if nothing's duplicated, it's a
# no-op.
function Repair-DuplicateModuleVersions {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-SectionHeader "Pre-flight: cleaning up duplicate module versions"

    $trackedNames = $script:ModuleTable | Where-Object { $_.Type -eq 'Module' } | Select-Object -ExpandProperty Name
    $patterns = @($trackedNames | Where-Object { $_ -ne 'Microsoft.Graph' }) + @('Microsoft.Graph.*')

    $anyFound = $false

    foreach ($pattern in $patterns) {
        try {
            $allVersions = Get-InstalledModule -Name $pattern -AllVersions -ErrorAction SilentlyContinue
        } catch {
            continue
        }
        if (-not $allVersions) { continue }

        foreach ($group in ($allVersions | Group-Object -Property Name)) {
            if ($group.Count -le 1) { continue }

            try {
                $sorted = $group.Group | Sort-Object { [version]$_.Version } -Descending
            } catch {
                continue
            }
            $keep = $sorted[0]
            $remove = $sorted | Select-Object -Skip 1
            if (-not $remove) { continue }

            $anyFound = $true
            Write-StepResult -Tag WARN -Message "$($group.Name) has $($group.Count) versions installed; keeping v$($keep.Version)."

            foreach ($old in $remove) {
                if ($PSCmdlet.ShouldProcess("$($group.Name) v$($old.Version)", "Uninstall duplicate version")) {
                    $op = Invoke-AsyncScript -ScriptBlock {
                        param($n, $v) Uninstall-Module -Name $n -RequiredVersion $v -Force -Confirm:$false -ErrorAction SilentlyContinue
                    } -ArgumentList @($group.Name, $old.Version)
                    [void](Show-ResolvingSpinner -AsyncOp $op -Label "Removing $($group.Name) v$($old.Version)...")
                }
            }
        }
    }

    if (-not $anyFound) {
        Write-StepResult -Tag OK -Message "No duplicate module versions found."
    }
    Write-Host ""
}
#endregion

#region Core install logic
function Install-OrUpdateModule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][PSCustomObject]$ModuleInfo,
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][int]$Total
    )

    Write-Host ""
    Write-Host ("  [{0}/{1}] {2}" -f $Index, $Total, $ModuleInfo.Name) -ForegroundColor White

    try {
        if ($ModuleInfo.Type -eq 'Script') {
            $installed = Get-InstalledScript -Name $ModuleInfo.Name -ErrorAction SilentlyContinue

            if (-not $installed) {
                if ($PSCmdlet.ShouldProcess($ModuleInfo.Name, "Install script (AllUsers)")) {
                    $op = Invoke-AsyncScript -ScriptBlock {
                        param($n) Install-Script -Name $n -Scope AllUsers -Force -Confirm:$false
                    } -ArgumentList @($ModuleInfo.Name)
                    $res = Show-DownloadStyleProgress -AsyncOp $op -Label "Installing $($ModuleInfo.Name)" -DoneLabel "Installed $($ModuleInfo.Name)"
                    if ($res.Errors.Count -gt 0) { throw $res.Errors[0] }
                }
                Write-StepResult -Tag INSTALL -Message "$($ModuleInfo.Name) installed."
                return
            }

            $findOp = Invoke-AsyncScript -ScriptBlock {
                param($n) (Find-Script -Name $n -Repository PSGallery -ErrorAction Stop | Select-Object -First 1).Version
            } -ArgumentList @($ModuleInfo.Name)
            $findRes = Show-ResolvingSpinner -AsyncOp $findOp -Label "Resolving $($ModuleInfo.Name)..."
            if ($findRes.Errors.Count -gt 0) { throw $findRes.Errors[0] }
            $latestVersion = $findRes.Result
            if (-not $latestVersion) { throw "Could not resolve a version for $($ModuleInfo.Name) from PSGallery (empty result)." }
            Write-Host ("  Found {0} [{1}]" -f $ModuleInfo.Name, $latestVersion) -ForegroundColor DarkCyan

            if ([version]$installed.Version -lt [version]$latestVersion) {
                if ($PSCmdlet.ShouldProcess($ModuleInfo.Name, "Update v$($installed.Version) -> v$latestVersion")) {
                    $uOp = Invoke-AsyncScript -ScriptBlock {
                        param($n) Uninstall-Script -Name $n -Force -Confirm:$false -ErrorAction SilentlyContinue
                    } -ArgumentList @($ModuleInfo.Name)
                    [void](Show-ResolvingSpinner -AsyncOp $uOp -Label "Removing v$($installed.Version)...")

                    $iOp = Invoke-AsyncScript -ScriptBlock {
                        param($n) Install-Script -Name $n -Scope AllUsers -Force -Confirm:$false
                    } -ArgumentList @($ModuleInfo.Name)
                    $res = Show-DownloadStyleProgress -AsyncOp $iOp -Label "Updating $($ModuleInfo.Name)" -DoneLabel "Updated $($ModuleInfo.Name) $latestVersion"
                    if ($res.Errors.Count -gt 0) { throw $res.Errors[0] }
                }
                Write-StepResult -Tag UPDATE -Message "$($ModuleInfo.Name) updated v$($installed.Version) -> v$latestVersion."
            } else {
                Write-StepResult -Tag OK -Message "$($ModuleInfo.Name) up to date (v$($installed.Version))."
            }
            return
        }

        $installed = Get-InstalledModule -Name $ModuleInfo.Name -ErrorAction SilentlyContinue

        if ($ModuleInfo.RequiredVersion) {
            if (-not $installed -or $installed.Version -ne $ModuleInfo.RequiredVersion) {
                if ($installed) {
                    $uOp = Invoke-AsyncScript -ScriptBlock {
                        param($n) Uninstall-Module -Name $n -AllVersions -Force -Confirm:$false -ErrorAction SilentlyContinue
                    } -ArgumentList @($ModuleInfo.Name)
                    [void](Show-ResolvingSpinner -AsyncOp $uOp -Label "Removing existing $($ModuleInfo.Name)...")
                }
                if ($PSCmdlet.ShouldProcess($ModuleInfo.Name, "Install v$($ModuleInfo.RequiredVersion) (AllUsers)")) {
                    $iOp = Invoke-AsyncScript -ScriptBlock {
                        param($n, $v) Install-Module -Name $n -RequiredVersion $v -Scope AllUsers -Force -AllowClobber -Confirm:$false
                    } -ArgumentList @($ModuleInfo.Name, $ModuleInfo.RequiredVersion)
                    $res = Show-DownloadStyleProgress -AsyncOp $iOp -Label "Installing $($ModuleInfo.Name)" -DoneLabel "Installed $($ModuleInfo.Name) $($ModuleInfo.RequiredVersion)"
                    if ($res.Errors.Count -gt 0) { throw $res.Errors[0] }
                }
                Write-StepResult -Tag INSTALL -Message "$($ModuleInfo.Name) pinned to v$($ModuleInfo.RequiredVersion)."
            } else {
                Write-StepResult -Tag OK -Message "$($ModuleInfo.Name) already at required v$($installed.Version)."
            }
            return
        }

        $findOp = Invoke-AsyncScript -ScriptBlock {
            param($n) (Find-Module -Name $n -Repository PSGallery -ErrorAction Stop | Select-Object -First 1).Version
        } -ArgumentList @($ModuleInfo.Name)
        $findRes = Show-ResolvingSpinner -AsyncOp $findOp -Label "Resolving $($ModuleInfo.Name)..."
        if ($findRes.Errors.Count -gt 0) { throw $findRes.Errors[0] }
        $latestVersion = $findRes.Result
        if (-not $latestVersion) { throw "Could not resolve a version for $($ModuleInfo.Name) from PSGallery (empty result)." }
        Write-Host ("  Found {0} [{1}]" -f $ModuleInfo.Name, $latestVersion) -ForegroundColor DarkCyan

        if (-not $installed) {
            if ($PSCmdlet.ShouldProcess($ModuleInfo.Name, "Install v$latestVersion (AllUsers)")) {
                $iOp = Invoke-AsyncScript -ScriptBlock {
                    param($n, $v) Install-Module -Name $n -RequiredVersion $v -Scope AllUsers -Force -AllowClobber -Confirm:$false
                } -ArgumentList @($ModuleInfo.Name, $latestVersion)
                $res = Show-DownloadStyleProgress -AsyncOp $iOp -Label "Installing $($ModuleInfo.Name)" -DoneLabel "Installed $($ModuleInfo.Name) $latestVersion"
                if ($res.Errors.Count -gt 0) { throw $res.Errors[0] }
            }
            Write-StepResult -Tag INSTALL -Message "$($ModuleInfo.Name) installed (v$latestVersion)."
        } elseif ([version]$installed.Version -lt [version]$latestVersion) {
            if ($PSCmdlet.ShouldProcess($ModuleInfo.Name, "Update v$($installed.Version) -> v$latestVersion")) {
                if ($ModuleInfo.Name -eq 'Microsoft.Graph') {
                    # Meta-package uninstall alone leaves 47+ old submodules
                    # behind -- do the full documented cleanup instead.
                    Uninstall-MicrosoftGraphFully
                } else {
                    $uOp = Invoke-AsyncScript -ScriptBlock {
                        param($n) Uninstall-Module -Name $n -AllVersions -Force -Confirm:$false -ErrorAction SilentlyContinue
                    } -ArgumentList @($ModuleInfo.Name)
                    [void](Show-ResolvingSpinner -AsyncOp $uOp -Label "Removing v$($installed.Version)...")
                }

                $iOp = Invoke-AsyncScript -ScriptBlock {
                    param($n, $v) Install-Module -Name $n -RequiredVersion $v -Scope AllUsers -Force -AllowClobber -Confirm:$false
                } -ArgumentList @($ModuleInfo.Name, $latestVersion)
                $res = Show-DownloadStyleProgress -AsyncOp $iOp -Label "Updating $($ModuleInfo.Name)" -DoneLabel "Updated $($ModuleInfo.Name) $latestVersion"
                if ($res.Errors.Count -gt 0) { throw $res.Errors[0] }
            }
            Write-StepResult -Tag UPDATE -Message "$($ModuleInfo.Name) updated v$($installed.Version) -> v$latestVersion."
        } else {
            Write-StepResult -Tag OK -Message "$($ModuleInfo.Name) up to date (v$($installed.Version))."
        }
    } catch {
        Write-StepResult -Tag FAIL -Message "$($ModuleInfo.Name): $($_.Exception.Message)"
    }
}

function Resolve-LegacyModuleConflict {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$LegacyName,
        [Parameter(Mandatory)][string]$ReplacementName
    )

    $legacyInstalled = Get-InstalledModule -Name $LegacyName -ErrorAction SilentlyContinue
    if (-not $legacyInstalled) { return $false }

    Write-StepResult -Tag WARN -Message "$LegacyName found; it conflicts with $ReplacementName."
    $choice = Read-Host "             Uninstall $LegacyName so $ReplacementName can be installed? [y/n]"

    if ($choice -eq 'y') {
        if ($PSCmdlet.ShouldProcess($LegacyName, "Uninstall")) {
            $op = Invoke-AsyncScript -ScriptBlock {
                param($n) Uninstall-Module -Name $n -AllVersions -Force -Confirm:$false
            } -ArgumentList @($LegacyName)
            [void](Show-ResolvingSpinner -AsyncOp $op -Label "Uninstalling $LegacyName...")
        }
        Write-StepResult -Tag OK -Message "$LegacyName uninstalled."
        return $true
    }

    Write-StepResult -Tag SKIP -Message "Keeping $LegacyName; skipping $ReplacementName install."
    return $false
}
#endregion

#region Module table
# NOTE: MSOnline and AzureAD are NOT in this table -- both are fully retired
# by Microsoft (MSOnline retired Apr-May 2025, AzureAD/AzureADPreview retired
# starting mid-Oct 2025). They're no longer resolvable on PSGallery, so
# Find-Module returns an empty result and Install-OrUpdateModule throws its
# "Could not resolve a version ... (empty result)" error by design -- that's
# not a bug in this script, it's the expected outcome for a dead module.
# Microsoft.Graph (already in this table) is the supported replacement for
# both; any scripts still calling Msol*/AzureAD* cmdlets need to be migrated
# to their Microsoft Graph PowerShell SDK equivalents.
$script:ModuleTable = @(
    [PSCustomObject]@{ Name = 'PowerShellGet';                          Type = 'Module' }
    [PSCustomObject]@{ Name = 'ExchangeOnlineManagement';                Type = 'Module' }
    [PSCustomObject]@{ Name = 'Microsoft.Online.SharePoint.PowerShell';  Type = 'Module'; RequiredVersion = '16.0.23612.12000' }
    [PSCustomObject]@{ Name = 'MicrosoftTeams';                         Type = 'Module' }
    [PSCustomObject]@{ Name = 'Microsoft.Graph.Intune';                  Type = 'Module' }
    [PSCustomObject]@{ Name = 'PSIntuneAuth';                            Type = 'Module' }
    [PSCustomObject]@{ Name = 'Microsoft.Graph';                         Type = 'Module' }
    [PSCustomObject]@{ Name = 'Get-AutopilotDiagnostics';                Type = 'Script' }
)
#endregion

#region Main
Test-IsAdmin
Write-Banner
Set-GalleryTrust

if (-not $SkipDuplicateCleanup) {
    Repair-DuplicateModuleVersions
}

if (-not $SkipPathHealthCheck) {
    Test-ModulePathHealth
}

Write-SectionHeader "Installing / updating modules"
$total = $script:ModuleTable.Count
for ($i = 0; $i -lt $total; $i++) {
    Install-OrUpdateModule -ModuleInfo $script:ModuleTable[$i] -Index ($i + 1) -Total $total
}
Write-Host ""

Write-SectionHeader "Legacy module conflicts (PnP, Az, AIPService)"

# SharePoint PnP: SharePointPnPPowerShellOnline (legacy) -> PnP.PowerShell
$pnpReplaced = Resolve-LegacyModuleConflict -LegacyName 'SharePointPnPPowerShellOnline' -ReplacementName 'PnP.PowerShell'
if ($pnpReplaced -or -not (Get-InstalledModule -Name 'SharePointPnPPowerShellOnline' -ErrorAction SilentlyContinue)) {
    Install-OrUpdateModule -ModuleInfo ([PSCustomObject]@{ Name = 'PnP.PowerShell'; Type = 'Module' }) -Index 1 -Total 1
}

# AzureRM (legacy) -> Az
$azReplaced = Resolve-LegacyModuleConflict -LegacyName 'AzureRM' -ReplacementName 'Az'
if ($azReplaced -or -not (Get-InstalledModule -Name 'AzureRM' -ErrorAction SilentlyContinue)) {
    Install-OrUpdateModule -ModuleInfo ([PSCustomObject]@{ Name = 'Az'; Type = 'Module' }) -Index 1 -Total 1
}

# AADRM (legacy) -> AIPService
$aipReplaced = Resolve-LegacyModuleConflict -LegacyName 'AADRM' -ReplacementName 'AIPService'
if ($aipReplaced -or -not (Get-InstalledModule -Name 'AADRM' -ErrorAction SilentlyContinue)) {
    Install-OrUpdateModule -ModuleInfo ([PSCustomObject]@{ Name = 'AIPService'; Type = 'Module' }) -Index 1 -Total 1
}

Write-Host ""
Write-Host ('=' * 63) -ForegroundColor Cyan
Write-Host "  $($script:Symbols.OK) All M365 / Azure PowerShell modules are installed and current." -ForegroundColor Green
Write-Host ('=' * 63) -ForegroundColor Cyan
Write-Host ""

Pause
#endregion
