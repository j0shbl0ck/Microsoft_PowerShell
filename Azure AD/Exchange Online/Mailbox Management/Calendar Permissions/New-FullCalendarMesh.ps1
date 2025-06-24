<#
.SYNOPSIS
    Creates editor-level calendar permissions between all licensed users in Microsoft 365 using Microsoft Graph.
.DESCRIPTION
    This script builds a fully-connected calendar permission mesh by granting each licensed mailbox user "Editor" access 
    to every other licensed user's primary calendar. It uses Microsoft Graph PowerShell SDK and supports validation 
    to ensure each user has the expected number of permissions.

    Author: j0shbl0ck (https://github.com/j0shbl0ck)
    Version: 1.0.0
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

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Calendars.ReadWrite"

# Get all licensed users (i.e., users with at least one assigned license)
Write-Host "Retrieving licensed users..." -ForegroundColor Yellow
$licensedUsers = Get-MgUser -Filter "AssignedLicenses/$count ne 0" -ConsistencyLevel eventual -CountVariable count -All
$userList = $licensedUsers | Select-Object -ExpandProperty UserPrincipalName

$totalUsers = $userList.Count
Write-Host "Total licensed users: $totalUsers" -ForegroundColor Green

# Loop through users
$counter = 0
$log = @()

foreach ($user in $userList) {
    $counter++
    $percentComplete = [math]::Round(($counter / $totalUsers) * 100)

    Write-Progress -Activity "Assigning Calendar Permissions" -Status "Processing $user" -PercentComplete $percentComplete

    $otherUsers = $userList | Where-Object { $_ -ne $user }

    foreach ($targetUser in $otherUsers) {
        # Skip if permission already exists
        $existingPerm = Get-MgUserCalendarPermission -UserId $targetUser -CalendarId "calendar" -ErrorAction SilentlyContinue |
                        Where-Object { $_.EmailAddress.Address -eq $user }

        if (-not $existingPerm) {
            try {
                New-MgUserCalendarPermission -UserId $targetUser `
                                             -CalendarId "calendar" `
                                             -BodyParameter @{
                                                 Role = "editor"
                                                 EmailAddress = @{
                                                     Address = $user
                                                 }
                                             } | Out-Null
            } catch {
                Write-Warning "Failed to grant $user editor access to $targetUser's calendar: $_"
                $log += [PSCustomObject]@{
                    User        = $user
                    Target      = $targetUser
                    Status      = "Failed"
                    Error       = $_.Exception.Message
                }
            }
        }
    }

    # ✅ Validate: User should have (totalUsers - 1) calendar permissions
    try {
        $grantedPerms = 0

        foreach ($targetUser in $otherUsers) {
            $perms = Get-MgUserCalendarPermission -UserId $targetUser -CalendarId "calendar" -ErrorAction SilentlyContinue
            if ($perms | Where-Object { $_.EmailAddress.Address -eq $user -and $_.Role -eq 'editor' }) {
                $grantedPerms++
            }
        }

        if ($grantedPerms -eq ($totalUsers - 1)) {
            Write-Host "$user successfully granted access to $grantedPerms calendars." -ForegroundColor Green
            $log += [PSCustomObject]@{
                User   = $user
                Status = "Success"
                Count  = $grantedPerms
                Error  = ""
            }
        } else {
            Write-Warning "$user has only $grantedPerms of $($totalUsers - 1) permissions."
            $log += [PSCustomObject]@{
                User   = $user
                Status = "Partial"
                Count  = $grantedPerms
                Error  = "Expected $($totalUsers - 1)"
            }
        }
    } catch {
        Write-Warning "Validation failed for ${user}: $_"
        $log += [PSCustomObject]@{
            User   = $user
            Status = "Validation Error"
            Count  = 0
            Error  = $_.Exception.Message
        }
    }
}

# Export summary log
$log | Export-Csv -Path "./CalendarPermissionLog.csv" -NoTypeInformation
Write-Host "`nScript complete. Log saved to CalendarPermissionLog.csv" -ForegroundColor Cyan

