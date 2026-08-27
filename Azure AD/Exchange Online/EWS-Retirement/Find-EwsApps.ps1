<#
.SYNOPSIS
    Resolves EWS App IDs from the tenant EWS usage report into friendly application names.

.DESCRIPTION
    Cross-references the App IDs found in the M365 admin center EWS usage report export
    against Microsoft's published list of first-party application IDs and, for anything
    not on that list, queries Entra ID (app registrations and service principals) to
    resolve a display name. Outputs two CSVs: one with resolved app names, one with App
    IDs that couldn't be matched to anything in the tenant (candidates for manual
    follow-up / possible external or decommissioned apps).

    Part of the Commerce Bank EWS retirement working set. Feeds the app inventory step
    of the EWS deprecation runbook (Phase 1 — app usage discovery).

.PARAMETER OutputPath
    Optional. Local folder to write output CSVs to. Defaults to Downloads.

.PARAMETER EwsUsageReportPath
    Optional. Path to the EWS usage report CSV exported from the M365 admin center
    (Reports > Usage > Exchange > EWS usage tab). If omitted, the script looks for a
    single EWSWeeklyUsage*.csv in -SearchFolder and uses it automatically; if it finds
    none or more than one, it opens a file picker pre-filtered to that pattern.

.PARAMETER SearchFolder
    Optional. Folder to auto-search for an EWSWeeklyUsage*.csv when -EwsUsageReportPath
    isn't given, and the starting folder for the file picker if it opens. Defaults to
    your Downloads folder.

.EXAMPLE
    .\Find-EwsApps.ps1
    # Zero-parameter run: auto-detects/prompts for the usage report in Downloads and
    # writes EwsApps.csv / EwsAppsNotFound.csv back to Downloads.

.EXAMPLE
    .\Find-EwsApps.ps1 -OutputPath C:\Temp\EWS
    # Auto-detects or prompts for the usage report CSV in Downloads, writes output to C:\Temp\EWS.

.EXAMPLE
    .\Find-EwsApps.ps1 -OutputPath C:\Temp\EWS -EwsUsageReportPath C:\Temp\EWS\EWSWeeklyUsage_8_27_2026_12_28_20.csv
    # Skips detection/picker and uses the exact file given.

.NOTES
    Version:      1.2.0 (Commerce Bank internal build)
    Author:       Josh Block
    Adapted from: Microsoft's Exchange-App-Usage-Reporting project (MIT licensed,
                  Copyright (c) Microsoft Corporation)
                  https://github.com/jmartinmsft/Exchange-App-Usage-Reporting
    GitHub:       https://github.com/j0shbl0ck (internal fork — not yet published)
    Requires:     Microsoft.Graph.Applications module, Application.Read.All (or higher)

    Original MIT license text is preserved below per license terms.
#>

<#
    MIT License

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE
#>

#region Parameters
[CmdletBinding(SupportsShouldProcess)]
param (
    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to write output CSVs to. Defaults to Downloads.")]
    [string] $OutputPath = (Join-Path $env:USERPROFILE "Downloads"),

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Path to the EWS usage report CSV exported from the M365 admin center. If omitted, the script auto-detects an EWSWeeklyUsage*.csv in -SearchFolder, or prompts with a file picker if it can't resolve to exactly one match.")]
    [string] $EwsUsageReportPath,

    [ValidateScript({ Test-Path $_ })]
    [Parameter(Mandatory = $false, HelpMessage = "Folder to auto-search for an EWSWeeklyUsage*.csv when -EwsUsageReportPath isn't specified. Defaults to Downloads.")]
    [string] $SearchFolder = (Join-Path $env:USERPROFILE "Downloads")
)
#endregion

#region Constants
$script:Version = "1.1.0"
$script:FirstPartyAppListUri = "https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv"
$script:UsageReportPattern = "EWSWeeklyUsage*.csv"
#endregion

#region Helper Functions
function Write-Status {
    <#
        Color-coded console output. Keeps this consistent with the rest of the
        Commerce Bank M365 tooling set instead of bare Write-Host calls.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string] $Level = 'Info'
    )

    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }

    Write-Host $Message -ForegroundColor $color
}

function Select-EwsUsageReportFile {
    <#
        Resolves the EWS usage report CSV to use, in order of preference:
          1. Explicit -EwsUsageReportPath, if supplied
          2. Auto-detect: exactly one EWSWeeklyUsage*.csv in -SearchFolder
          3. File picker dialog, pre-filtered to EWSWeeklyUsage*.csv, starting in
             -SearchFolder — used both when auto-detect finds 0 or 2+ matches
    #>
    param(
        [string] $ExplicitPath,
        [string] $SearchFolder
    )

    if (-not [string]::IsNullOrEmpty($ExplicitPath)) {
        return $ExplicitPath
    }

    $candidates = @(Get-ChildItem -Path $SearchFolder -Filter $script:UsageReportPattern -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)

    if ($candidates.Count -eq 1) {
        Write-Status "Auto-detected usage report: $($candidates[0].FullName)" -Level Success
        return $candidates[0].FullName
    }

    if ($candidates.Count -gt 1) {
        Write-Status "Found $($candidates.Count) EWSWeeklyUsage files in $SearchFolder — most recent is $($candidates[0].Name). Opening picker so you can confirm which one." -Level Warning
    }
    else {
        Write-Status "No EWSWeeklyUsage*.csv found in $SearchFolder — opening file picker." -Level Info
    }

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.InitialDirectory = $SearchFolder
    $dialog.Filter = "EWS Usage Report (EWSWeeklyUsage*.csv)|EWSWeeklyUsage*.csv|All CSV files (*.csv)|*.csv"
    $dialog.Title = "Select the EWS usage report export"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "No file selected — aborting."
    }

    return $dialog.FileName
}


function Resolve-EwsAppName {
    <#
        Attempts to resolve a single App ID to a display name via app registration,
        falling back to service principal lookup if the direct app lookup misses.
    #>
    param(
        [Parameter(Mandatory = $true)][string] $AppId
    )

    try {
        $application = Get-MgApplication -Filter "AppId eq '$AppId'" -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($application.DisplayName)) {
            return $application.DisplayName
        }

        $servicePrincipal = Get-MgServicePrincipal -Filter "ServicePrincipalNames/any(s:s eq '$AppId')" -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($servicePrincipal.DisplayName)) {
            return $servicePrincipal.DisplayName
        }

        return $null
    }
    catch {
        Write-Status "Error resolving AppId $AppId : $($_.Exception.Message)" -Level Error
        throw
    }
}
#endregion

#region Main
Write-Status "Find-EwsApps v$script:Version — resolving EWS App IDs to display names" -Level Info

try {
    #region Prerequisite checks
    if (-not (Get-Module -Name Microsoft.Graph.Applications -ListAvailable)) {
        Write-Status "Microsoft Graph PowerShell module is not installed. Install it with: Install-Module -Name Microsoft.Graph.Applications" -Level Error
        return
    }

    if (-not (Get-MgContext)) {
        Write-Status "Connecting to Microsoft Graph (Application.Read.All)..." -Level Info
        Connect-MgGraph -Scopes Application.Read.All -NoWelcome
    }
    #endregion

    #region Load first-party app reference list
    $firstPartyCsvPath = Join-Path $OutputPath "MicrosoftApps.csv"
    if ($PSCmdlet.ShouldProcess($firstPartyCsvPath, "Download latest Microsoft first-party app list")) {
        Write-Status "Downloading current first-party app list..." -Level Info
        Invoke-WebRequest -Uri $script:FirstPartyAppListUri -OutFile $firstPartyCsvPath
    }

    $microsoftApps = Import-Csv -Path $firstPartyCsvPath
    $firstPartyLookup = @{}
    foreach ($app in $microsoftApps) {
        $firstPartyLookup[$app.AppId] = $app.appDisplayName
    }
    Write-Status "Loaded $($firstPartyLookup.Count) known first-party app IDs." -Level Success
    #endregion

    #region Load tenant EWS usage report
    $resolvedReportPath = Select-EwsUsageReportFile -ExplicitPath $EwsUsageReportPath -SearchFolder $SearchFolder
    Write-Status "Using usage report: $resolvedReportPath" -Level Info
    $ewsApps = Import-Csv $resolvedReportPath | Sort-Object AppId -Unique
    Write-Status "Found $($ewsApps.Count) unique App IDs in the EWS usage report." -Level Info
    #endregion

    #region Resolve app names
    $resolvedApps = [System.Collections.Generic.List[object]]::new()
    $unresolvedApps = [System.Collections.Generic.List[object]]::new()

    foreach ($app in $ewsApps) {
        if ($firstPartyLookup.ContainsKey($app.AppId)) {
            $resolvedApps.Add([PSCustomObject]@{
                AppId       = $app.AppId
                DisplayName = "$($firstPartyLookup[$app.AppId]) (MSFT)"
            })
            continue
        }

        Write-Status "Resolving $($app.AppId)..." -Level Info
        try {
            $displayName = Resolve-EwsAppName -AppId $app.AppId
            if ($displayName) {
                $resolvedApps.Add([PSCustomObject]@{
                    AppId       = $app.AppId
                    DisplayName = $displayName
                })
            }
            else {
                Write-Status "  No match found for $($app.AppId) — flagging for manual follow-up." -Level Warning
                $unresolvedApps.Add([PSCustomObject]@{ AppId = $app.AppId })
            }
        }
        catch {
            Write-Status "Stopping — unrecoverable error resolving $($app.AppId)." -Level Error
            break
        }
    }
    #endregion

    #region Output
    Write-Status "Resolved $($resolvedApps.Count) app(s); $($unresolvedApps.Count) unresolved." -Level Success

    $resolvedApps | Out-GridView -Title "EWS Applications"

    $resolvedCsvPath = Join-Path $OutputPath "EwsApps.csv"
    $unresolvedCsvPath = Join-Path $OutputPath "EwsAppsNotFound.csv"

    if ($PSCmdlet.ShouldProcess($resolvedCsvPath, "Write resolved app list")) {
        $resolvedApps | Export-Csv -Path $resolvedCsvPath -NoTypeInformation -Force
        Write-Status "Wrote $resolvedCsvPath" -Level Success
    }

    if ($PSCmdlet.ShouldProcess($unresolvedCsvPath, "Write unresolved app list")) {
        $unresolvedApps | Export-Csv -Path $unresolvedCsvPath -NoTypeInformation -Force
        Write-Status "Wrote $unresolvedCsvPath" -Level Success
    }
    #endregion
}
catch {
    Write-Status "Unhandled error: $($_.Exception.Message)" -Level Error
    throw
}
#endregion