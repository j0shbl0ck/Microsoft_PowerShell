
<#
.SYNOPSIS
    Retrieves users created in the last 30 days who have been assigned the SPE_E3 license.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 09.04.25
    Type: Public
.NOTES
    Requires the Microsoft Graph PowerShell SDK to be installed.
    Requires the User.Read.All and Directory.Read.All permissions.
    Ensure you have the necessary permissions to run this script.
.LINK
#>

Clear-Host

function Write-Message {
    param (
        [string]$Message,
        [ConsoleColor]$Color = "Gray"
    )
    $currentColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host "[*] $Message"
    $Host.UI.RawUI.ForegroundColor = $currentColor
}

function Update-GraphModule {
    $RequiredModules = @(
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Reports"   # required for audit logs
    )

    foreach ($Module in $RequiredModules) {
        Write-Message "Checking module: $Module" -Color Yellow

        $InstalledVersions = Get-InstalledModule -Name $Module -AllVersions -ErrorAction SilentlyContinue

        if ($InstalledVersions) {
            $LatestInstalled = $InstalledVersions | Sort-Object Version -Descending | Select-Object -First 1

            foreach ($Ver in $InstalledVersions) {
                if ($Ver.Version -ne $LatestInstalled.Version) {
                    Write-Message "Removing older version $($Ver.Version) of $Module..." -Color Yellow
                    try {
                        Uninstall-Module -Name $Module -RequiredVersion $Ver.Version -Force -ErrorAction Stop
                        Write-Message "Removed version $($Ver.Version) of $Module." -Color DarkGray
                    } catch {
                        Write-Message "Failed to remove $Module version $($Ver.Version). Error: $_" -Color Red
                    }
                }
            }

            try {
                Import-Module $Module -Force -ErrorAction Stop
                Write-Message "$Module version $($LatestInstalled.Version) is already installed and has been imported." -Color Green
            } catch {
                Write-Message "Failed to import $Module. Error: $_" -Color Red
                return
            }
        } else {
            Write-Message "$Module not found. Installing..." -Color Yellow
            try {
                Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Import-Module $Module -Force -ErrorAction Stop
                $NewVer = (Get-InstalledModule -Name $Module).Version
                Write-Message "Installed and imported $Module version $NewVer." -Color Green
            } catch {
                Write-Message "Failed to install or import $Module. Error: $_" -Color Red
                return
            }
        }
    }
}

# --- MAIN EXECUTION ---
Update-GraphModule

try {
    Connect-MgGraph -NoWelcome -Scopes "AuditLog.Read.All","User.Read.All","Directory.Read.All" -ErrorAction Stop
    Write-Message "Connected to Microsoft Graph via interactive login." -Color Green
    Write-Host ""
} catch {
    Write-Message "Interactive auth failed: $_" -Color Red
    return
}

# Define date range and E3 SKU
$startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
$e3SkuId   = "05e9a617-0261-4cee-bb44-138d3ef5d965"

Write-Message "Retrieving license assignment audit logs since $startDate..." -Color Cyan

try {
    $licenseEvents = Get-MgAuditLogDirectoryAudit -Filter "activityDateTime ge $startDate and activityDisplayName eq 'Assign license'" -All
} catch {
    Write-Message "Failed to query audit logs: $_" -Color Red
    return
}

# Filter to just E3 assignments
$e3Assignments = $licenseEvents | Where-Object {
    $_.TargetResources.ModifiedProperties |
        Where-Object { $_.DisplayName -eq "AssignedLicenses" -and $_.NewValue -match $e3SkuId }
}

if (-not $e3Assignments) {
    Write-Message "No E3 license assignments found in the last 30 days." -Color Yellow
    return
}

Write-Message "Found $($e3Assignments.Count) E3 assignments in last 30 days..." -Color Green

# Collect unique user IDs and fetch details
$assignedUserIds = $e3Assignments.TargetResources.Id | Sort-Object -Unique

$report = foreach ($userId in $assignedUserIds) {
    try {
        $u = Get-MgUser -UserId $userId -Property DisplayName,UserPrincipalName,Department,JobTitle
        [PSCustomObject]@{
            DisplayName       = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
            Department        = $u.Department
            JobTitle          = $u.JobTitle
        }
    } catch {
        Write-Message "Could not retrieve details for UserId $userId" -Color Red
    }
}

# Save report to CSV
$csvPath = "$env:USERPROFILE\Desktop\E3_Assignments_Last30Days.csv"
$report | Export-Csv -Path $csvPath -NoTypeInformation

Write-Message "Report saved to: $csvPath" -Color Green
Write-Message "E3 Assignments Report Complete." -Color Cyan
