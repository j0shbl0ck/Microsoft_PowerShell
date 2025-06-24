<#
.SYNOPSIS
    Creates editor-level calendar permissions between all licensed users in Microsoft 365 using Microsoft Graph.
.DESCRIPTION
    This script builds a fully-connected calendar permission mesh by granting each licensed mailbox user "Editor" access 
    to every other licensed user's primary calendar. It uses Microsoft Graph PowerShell SDK and supports validation 
    to ensure each user has the expected number of permissions.

    Author: j0shbl0ck (https://github.com/j0shbl0ck)
    Version: 1.0.2
    Date: 06.24.25
    Type: Public
.EXAMPLE
    .\New-FullCalendarMesh.ps1
    Connects to Microsoft Graph, gathers all licensed users, assigns calendar permissions, and validates access mesh.
.NOTES
    Prerequisites:
    - Microsoft Graph PowerShell SDK [Install-Module Microsoft.Graph -Scope CurrentUser]
    - App registration or delegated Graph access with Calendars.ReadWrite and User.Read.All
    - Admin consent must be granted for required Graph scopes
#>

function Ensure-RunningAsAdministrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Not running as administrator. Re-launching script with elevated privileges..." -ForegroundColor Yellow

        $scriptPath = $MyInvocation.MyCommand.Definition
        $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""

        Start-Process powershell -Verb RunAs -ArgumentList $arguments
        exit
    }
}

function Ensure-GraphModule {
    $requiredGraphVersion = [version]"2.28.0"
    $installedGraph = Get-InstalledModule -Name Microsoft.Graph -ErrorAction SilentlyContinue

    if (-not $installedGraph) {
        Write-Warning "Microsoft.Graph module is not installed. Installing it now..."
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }
    elseif ($installedGraph.Version -lt $requiredGraphVersion) {
        Write-Warning "Microsoft.Graph version $($installedGraph.Version) is below required $requiredGraphVersion. Updating..."
        Update-Module Microsoft.Graph -Force
    } else {
        Write-Host "Microsoft.Graph version $($installedGraph.Version) meets the requirement ($requiredGraphVersion)." -ForegroundColor Green
    }

    Import-Module Microsoft.Graph -ErrorAction Stop
}

function Connect-ToGraph {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "User.Read.All", "Calendars.ReadWrite" | Out-Null
}

function Get-LicensedUsers {
    Write-Host "Retrieving licensed users..." -ForegroundColor Yellow
    $allUsers = Get-MgUser -All -Property "UserPrincipalName,AssignedLicenses"
    return $allUsers | Where-Object { $_.AssignedLicenses.Count -gt 0 } | Select-Object -ExpandProperty UserPrincipalName
}

function Grant-CalendarPermissions {
    param (
        [string[]]$UserList,
        [ref]$LogRef
    )

    $totalUsers = $UserList.Count
    $counter = 0

    foreach ($user in $UserList) {
        $counter++
        $percentComplete = [math]::Round(($counter / $totalUsers) * 100)
        Write-Progress -Activity "Assigning Calendar Permissions" -Status "Processing $user" -PercentComplete $percentComplete

        $otherUsers = $UserList | Where-Object { $_ -ne $user }

        foreach ($targetUser in $otherUsers) {
            $existingPerm = Get-MgUserCalendarPermission -UserId $targetUser -CalendarId "calendar" -ErrorAction SilentlyContinue |
                            Where-Object { $_.EmailAddress.Address -eq $user }

            if (-not $existingPerm) {
                try {
                    New-MgUserCalendarPermission -UserId $targetUser -CalendarId "calendar" -BodyParameter @{
                        Role = "editor"
                        EmailAddress = @{ Address = $user }
                    } | Out-Null
                } catch {
                    Write-Warning "Failed to grant $user editor access to $targetUser's calendar: $_"
                    $LogRef.Value += [PSCustomObject]@{
                        User   = $user
                        Target = $targetUser
                        Status = "Failed"
                        Error  = $_.Exception.Message
                    }
                }
            }
        }

        Validate-UserPermissions -User $user -OtherUsers $otherUsers -TotalExpected ($totalUsers - 1) -LogRef $LogRef
    }
}

function Validate-UserPermissions {
    param (
        [string]$User,
        [string[]]$OtherUsers,
        [int]$TotalExpected,
        [ref]$LogRef
    )

    try {
        $grantedPerms = 0

        foreach ($targetUser in $OtherUsers) {
            $perms = Get-MgUserCalendarPermission -UserId $targetUser -CalendarId "calendar" -ErrorAction SilentlyContinue
            if ($perms | Where-Object { $_.EmailAddress.Address -eq $User -and $_.Role -eq 'editor' }) {
                $grantedPerms++
            }
        }

        if ($grantedPerms -eq $TotalExpected) {
            Write-Host "$User successfully granted access to $grantedPerms calendars." -ForegroundColor Green
            $LogRef.Value += [PSCustomObject]@{
                User   = $User
                Status = "Success"
                Count  = $grantedPerms
                Error  = ""
            }
        } else {
            Write-Warning "$User has only $grantedPerms of $TotalExpected permissions."
            $LogRef.Value += [PSCustomObject]@{
                User   = $User
                Status = "Partial"
                Count  = $grantedPerms
                Error  = "Expected $TotalExpected"
            }
        }
    } catch {
        Write-Warning "Validation failed for $User: $_"
        $LogRef.Value += [PSCustomObject]@{
            User   = $User
            Status = "Validation Error"
            Count  = 0
            Error  = $_.Exception.Message
        }
    }
}

function Main {
    Ensure-RunningAsAdministrator
    Ensure-GraphModule
    Connect-ToGraph
    Clear-Host

    $userList = Get-LicensedUsers
    $totalUsers = $userList.Count
    Write-Host "Total licensed users: $totalUsers" -ForegroundColor Green

    $log = @()
    Grant-CalendarPermissions -UserList $userList -LogRef ([ref]$log)

    $log | Export-Csv -Path "./CalendarPermissionLog.csv" -NoTypeInformation
    Write-Host "`nScript complete. Log saved to CalendarPermissionLog.csv" -ForegroundColor Cyan
}

# Execute
Main
