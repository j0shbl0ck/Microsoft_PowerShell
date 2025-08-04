<#
.SYNOPSIS
    This script uploads user photos to Microsoft Entra ID (Azure AD) using the Microsoft Graph PowerShell SDK.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 07.17.25
    Type: Public
.NOTES
    Requires the Microsoft Graph PowerShell SDK to be installed.
    Requires the User.ReadWrite.All permissions.
    Ensure you have the necessary permissions to run this script.
.LINK
    https://office365itpros.com/2024/01/12/user-extension-attributes-sdk/
    https://practical365.com/guest-account-expiration/
    https://o365info.com/manage-user-photos-microsoft-graph-powershell/
    https://ourcloudnetwork.com/how-to-update-user-photos-with-microsoft-graph-powershell/
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

# Ensure required Microsoft Graph modules are up to date
function Update-GraphModule {
    $RequiredModules = @(
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Authentication"
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
                exit 1
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
                exit 1
            }
        }
    }
}

# --- MAIN EXECUTION ---

# Load Microsoft Graph modules
Update-GraphModule

# Use beta profile for full user photo support
#Select-MgProfile -Name "beta"

# Authenticate via interactive login
try {
    Connect-MgGraph -NoWelcome -Scopes "User.ReadWrite.All" -ErrorAction Stop
    Write-Message "Connected to Microsoft Graph via interactive login." -Color Green
    Write-Host ""
} catch {
    Write-Message "Interactive auth failed: $_" -Color Red
    exit 1
}

# --- CONFIGURATION ---

$RootFolder = "C:\UserPhotos"
if (!(Test-Path $RootFolder)) {
    Write-Host "Root folder not found: $RootFolder" -ForegroundColor Red
    exit 1
}

$PhotoFiles = @()
$Extensions = "*.jpg", "*.jpeg", "*.png", "*.bmp"

foreach ($ext in $Extensions) {
    $PhotoFiles += Get-ChildItem -Path $RootFolder -Filter $ext -File
}

$TotalUsers = $PhotoFiles.Count
$UserIndex = 0

foreach ($Photo in $PhotoFiles) {
    $UserIndex++
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($Photo.Name)
    $Status = "[$UserIndex/$TotalUsers] File: $($Photo.Name)"
    Write-Progress -Activity "Uploading user photo" -Status $Status -PercentComplete (($UserIndex / $TotalUsers) * 100)

    try {
        $User = Get-MgUser -Filter "onPremisesExtensionAttributes/extensionAttribute3 eq '$BaseName'" -ConsistencyLevel eventual -CountVariable CountVar -All

        if ($User) {
            $UserId = $User.Id
            $UPN = $User.UserPrincipalName
            Write-Host "Match found! Photo '$($Photo.Name)' corresponds to user: $UPN" -ForegroundColor Yellow

            try {
                Set-MgUserPhotoContent -UserId $UserId -InFile $Photo.FullName -ContentType "image/jpeg"
                Write-Host "Photo uploaded for $UPN" -ForegroundColor Green

                # Rename the photo file to append "-uploaded" before the extension
                $NewName = [System.IO.Path]::GetFileNameWithoutExtension($Photo.Name) + "-uploaded" + $Photo.Extension
                $NewFullPath = Join-Path -Path $Photo.DirectoryName -ChildPath $NewName

                # Rename the file
                Rename-Item -Path $Photo.FullName -NewName $NewName -ErrorAction Stop
                Write-Host "Renamed photo to '$NewName'" -ForegroundColor Cyan
                Write-Host ""

            } catch {
                Write-Host "Error uploading photo for ${UPN}: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "No user found with ExtensionAttribute3 = $BaseName" -ForegroundColor DarkRed
        }
    } catch {
        Write-Host "Error processing $($Photo.Name): $_" -ForegroundColor Red
    }
}

# Disconnect from Graph
Write-Message "Disconnecting from Microsoft Graph."
Disconnect-MgGraph

Write-Message "Script execution finished."

