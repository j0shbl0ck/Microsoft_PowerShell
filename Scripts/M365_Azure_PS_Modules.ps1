<#
.SYNOPSIS
    This script installs the M365 and Azure Powershell Module Services.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.5.1
    Date: 01.12.22
    Type: Public
.NOTES
    To use Microsoft Graph Intune, you will need to run for the first time:  Connect-MSGraph -AdminConsent 
.LINK
    Source: https://o365reports.com/2019/11/01/install-all-office-365-powershell-modules/
#>

Clear-Host

# Function to check for admin privileges
Function Block-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "This script must be run as an administrator. Closing in 5 seconds..." 
        Start-Sleep -Seconds 5
        Break
    }
}

Block-Admin;

# Display intro to script
function Write-Intro {
Write-Host ""
Write-Host -ForegroundColor Cyan "========================================================="
Write-Host -ForegroundColor Cyan "               M365/Azure Powershell Modules             "
Write-Host -ForegroundColor Cyan "========================================================="
Write-Host ""
Write-Host -ForegroundColor Cyan "Checking for latest M365 and Azure Powershell modules..."
Write-Host ""
}

Write-Intro;

# To be able to execute scripts, if not already performed
function Install-PowerShellGetModule {
    $moduleName = "PowerShellGet"
    Write-Host -ForegroundColor Yellow "Finding PowerShellGet Module..."
    try {
        $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue       
        if (-not $installedModule) {
            Write-Host -ForegroundColor Red "$moduleName not found. Installing $moduleName..."
            Set-ExecutionPolicy RemoteSigned
            Install-Module -Name $moduleName -Force -AllowClobber -Confirm:$False
            Write-Host -ForegroundColor Green "$moduleName Installed!"
        } else {
            Write-Host -ForegroundColor Green "$moduleName Installed!"
        }
    } catch {
        Write-Host -ForegroundColor Red "Error occurred during PowerShellGet module installation: $($_.Exception.Message)"
    }
}

Install-PowerShellGetModule;

# Installs Exchange Powershell Module
function Install-ExchangeModule {
    $exo = "ExchangeOnlineManagement"   
    Write-Host -ForegroundColor Yellow "Finding Exchange PowerShell Module..."   
    try {
        # Check for the latest version of the module
        $latestVersion = (Find-Module -Name $exo -Repository PSGallery | Select-Object -First 1).Version     
        # Check if the module is already installed
        $installedModule = Get-InstalledModule -Name $exo -ErrorAction SilentlyContinue
        
        if (-not $installedModule) {
            # If the module is not installed, install the latest version
            Write-Host -ForegroundColor Red "${exo} not found. Installing latest version (${latestVersion})..."
            Install-Module -Name $exo -RequiredVersion $latestVersion -Force -Confirm:$false
            Write-Host -ForegroundColor Green "${exo} Installed!"
        } elseif ($installedModule.Version -lt $latestVersion) {
            # If the installed module is an older version, uninstall and install the latest version
            Write-Host -ForegroundColor Red "Uninstalling ${exo} version $($installedModule.Version)..."
            Uninstall-Module -Name $exo -RequiredVersion $installedModule.Version -Force -Confirm:$false
            Write-Host -ForegroundColor Red "Installing latest version (${latestVersion})..."
            Install-Module -Name $exo -RequiredVersion $latestVersion -Force -Confirm:$false
            Write-Host -ForegroundColor Green "${exo} Installed!"
        } else {
            # If the installed module is already up to date, inform the user
            Write-Host -ForegroundColor Green "${exo} version $($installedModule.Version) already installed."
        }
    }
    catch {
        Write-Host -ForegroundColor Red "Error occurred during module installation: $($_.Exception.Message)"
    }
}

Install-ExchangeModule;

# Installs SharePoint Online Powershell Module
function Install-SharePointOnlineModule {
    $sop = "Microsoft.Online.SharePoint.PowerShell"
    Write-Host -ForegroundColor Yellow "Finding SharePoint Online PowerShell Module..."
    try {
        if (-not (Get-InstalledModule -Name $sop -ErrorAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "${sop} not found. Installing ${sop}..."
            Install-Module -Name $sop -RequiredVersion "16.0.23612.12000" -Force -Confirm:$False
            Write-Host -ForegroundColor Green "${sop} Installed!"
        } else {
            Write-Host -ForegroundColor Green "${sop} Installed!"
        }
    } catch {
        Write-Host -ForegroundColor Red "Error occurred during SharePoint Online module installation: $($_.Exception.Message)"
    }
}

Install-SharePointOnlineModule;

# Install Teams PowerShell Module
function Install-MicrosoftTeamsModule {
    $mst = "MicrosoftTeams"   
    Write-Host -ForegroundColor Yellow "Finding Microsoft Teams Module..." 
    try {
        if (-not (Get-InstalledModule -Name $mst -ErrorAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "${mst} not found. Installing ${mst}..."
            Install-Module -Name $mst -Force -AllowClobber -Confirm:$False
            Write-Host -ForegroundColor Green "${mst} Installed!"
        } else {
            Write-Host -ForegroundColor Green "${mst} Installed!"
        }
    } catch {
        Write-Host -ForegroundColor Red "Error occurred during Microsoft Teams module installation: $($_.Exception.Message)"
    }
}

Install-MicrosoftTeamsModule;

<# # Install SharePoint PNP Powershell Module (Deprecated)
Write-Host -ForegroundColor Yellow "Finding SharePoint PNP PowerShell Module..."
Write-Host -ForegroundColor Yellow "Finding PnP PowerShell Module..."
$pnp = "SharePointPnPPowerShellOnline"
if (-not(Get-InstalledModule -Name $pnp -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${pnp} Not Found. Installing ${pnp}..."
    Install-Module -Name $pnp -SkipPublisherCheck -AllowClobber -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${pnp} Installed!"
} else {
    Write-Host -ForegroundColor Green "${pnp} Installed!"
} #>

# Install PnP PowerShell Module
function Install-PnPPowerShellModule {
    $pnpps = "PnP.PowerShell"
    $sppnp = "SharePointPnPPowerShellOnline"
    Write-Host -ForegroundColor Yellow "Finding PnP PowerShell Module..."
    try {
        if (Get-InstalledModule -Name $sppnp -ErrorAction SilentlyContinue) {
            Write-Warning "${sppnp} Found. Requires uninstall to install PnP PowerShell Module...`n"
            $choice = ''       
            while ($choice -ne 'y' -and $choice -ne 'n') {
                $choice = Read-Host -Prompt "Do you want to uninstall SharePoint PnP Module? [y/n]"              
                if ($choice -eq 'y') {
                    Write-Host -ForegroundColor Red "Uninstalling SharePoint PnP Module..."
                    Uninstall-Module -Name $sppnp -AllVersions
                    Write-Host -ForegroundColor Green "${sppnp} Uninstalled!"                   
                    if (-not (Get-InstalledModule -Name $pnpps -ErrorAction SilentlyContinue)) {
                        Write-Host -ForegroundColor Red "${pnpps} Not Found. Installing ${pnpps}..."
                        Install-Module -Name $pnpps -Force -AllowClobber -Confirm:$False
                        Write-Host -ForegroundColor Green "${pnpps} Installed!"
                    } 
                } elseif ($choice -eq 'n') {
                    Write-Host -ForegroundColor Red "Denied uninstall of SharePoint PnP Module. Continuing..."
                    break
                } else {
                    Write-Host -ForegroundColor Red "Invalid input. Please enter 'y' or 'n'"
                }
            }
        } else {
            if (-not (Get-InstalledModule -Name $pnpps -ErrorAction SilentlyContinue)) {
                Write-Host -ForegroundColor Red "${pnpps} Not Found. Installing ${pnpps}..."
                Install-Module -Name $pnpps -Force -AllowClobber -Confirm:$False
                Write-Host -ForegroundColor Green "${pnpps} Installed!"
            } else {
                Write-Host -ForegroundColor Green "${pnpps} Installed!"
            }
        }
    } catch {
        Write-Host -ForegroundColor Red "Error occurred during PnP PowerShell module installation: $($_.Exception.Message)"
    }
}

Install-PnPPowerShellModule;


# Install AzureAD V1 Powershell Module
Write-Host -ForegroundColor Yellow "Finding AzureAD V1 PowerShell Module..."
$mso = "MSOnline"
if (-not(Get-InstalledModule -Name $mso -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mso} Not Found. Installing ${mso}..."
    Install-Module -Name $mso -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${mso} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mso} Installed!"
}

# Install AzureAD V2 PowerShell Module
Write-Host -ForegroundColor Yellow "Finding AzureAD V2 PowerShell Module..."
$aad = "AzureAD"
if (-not(Get-InstalledModule -Name $aad -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${aad} Not Found. Installing ${aad}..."
    Install-Module -Name $aad -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${aad} Installed!"
} else {
    Write-Host -ForegroundColor Green "${aad} Installed!"
}

# Install Microsoft Intune PowerShell Module
Write-Host -ForegroundColor Yellow "Finding Microsoft Intune PowerShell Module..."
$mgi = "Microsoft.Graph.Intune"
if (-not(Get-InstalledModule -Name $mgi -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mgi} Not Found. Installing ${mgi}..."
    Install-Module -Name $mgi -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${mgi} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mgi} Installed!"
}

# Install PSIntuneAuth PowerShell Module
Write-Host -ForegroundColor Yellow "Finding PSIntuneAuth PowerShell Module..."
$pia = "PSIntuneAuth"
if (-not(Get-InstalledModule -Name $pia -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${pia} Not Found. Installing ${pia}..."
    Install-Module -Name $pia -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${pia} Installed!"
} else {
    Write-Host -ForegroundColor Green "${pia} Installed!"
}

# Install Microsoft Graph PowerShell Module
Write-Host -ForegroundColor Yellow "Finding Microsoft Graph PowerShell Module..."
$mgp = "Microsoft.Graph"
if (-not(Get-InstalledModule -Name $mgp -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mgp} Not Found. Installing ${mgp}..."
    Install-Module -Name $mgp -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${mgp} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mgp} Installed!"
}

# Install Autopilot Diagnostics
$gad = "Get-AutopilotDiagnostics"
Write-Host -ForegroundColor Yellow "Finding Autopilot Diagnostics script..."
if (-not(Get-InstalledScript -Name $gad -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${gad} Not Found. Installing ${gad}..."
    Install-Script -Name $gad -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${gad} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mgi} Installed!"
}

<# # Install Azure CLI PowerShell Module
Write-Host -ForegroundColor Yellow "Finding Azure CLI Module..."
$arm = "AzureRM"
if (-not(Get-InstalledModule -Name $arm -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${arm} Not Found. Installing ${arm}..."
    Install-Module -Name $arm -Force -AllowClobber -Confirm:$False
    Write-Host -ForegroundColor Green "${arm} Installed!"
} else {
    Write-Host -ForegroundColor Green "${arm} Installed!"
} #>

# Install Azure Az PowerShell Module
Write-Host -ForegroundColor Yellow "Finding Azure Az Module..."
$az = "Az"
$arm = "AzureRM"
if (Get-InstalledModule -Name $arm -ErrorAction SilentlyContinue) {
        Write-Host -ForegroundColor Red "${arm} Found. Requires uninstall to install Azure Az Module..."
        $confirmation = Read-Host "Do you want to uninstall AzureRM Module? [y/n]"
        while($confirmation -ne "y")
        {
            if ($confirmation -eq 'n') {
                break
                Write-Host -ForegroundColor Red "Denied uninstall of AzureRM Module. Continuing..."
            }
            $confirmation = Read-Host "Do you want to uninstall AzureRM Module? [y/n]"
            break
        }
            if ($confirmation -eq 'y') {
            Write-Host -ForegroundColor Red "Uninstalling AzureRM Module..."
            Uninstall-Module -Name $arm -AllVersions
            Write-Host -ForegroundColor Green "${arm} Uninstalled!"
            if (-not(Get-InstalledModule -Name $az -ErrorAction SilentlyContinue)) {
                Write-Host -ForegroundColor Red "${az} Not Found. Installing ${az}..."
                Install-Module -Name $az -Force -AllowClobber -Confirm:$False
                Write-Host -ForegroundColor Green "${az} Installed!"
            } else {
                Write-Host -ForegroundColor Green "${az} Installed!"
            }
        }
}else {
    $az = "Az"
    if (-not(Get-InstalledModule -Name $az -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red "${az} Not Found. Installing ${az}..."
        Install-Module -Name $az -Force -AllowClobber -Confirm:$False
        Write-Host -ForegroundColor Green "${az} Installed!"
    } else {
        Write-Host -ForegroundColor Green "${az} Installed!"
    }
}

# Install AIPService PowerShell Module
Write-Host -ForegroundColor Yellow "Finding AIPService PowerShell Module..."
$aip = "AIPService"
$aadrm = "AADRM"
if (Get-InstalledModule -Name $aadrm -ErrorAction SilentlyContinue) {
        Write-Host -ForegroundColor Red "${aadrm} Found. Requires uninstall to install AIPService PowerShell Module..."
        $confirmation = Read-Host "Do you want to uninstall AADRM Module? [y/n]"
        while($confirmation -ne "y")
        {
            if ($confirmation -eq 'n') {
                break
                Write-Host -ForegroundColor Red "Denied uninstall of AADRM Module. Continuing..."
            }
            $confirmation = Read-Host "Do you want to uninstall AADRM Module? [y/n]"
            break
        }
            if ($confirmation -eq 'y') {
            Write-Host -ForegroundColor Red "Uninstalling AADRM Module..."
            Uninstall-Module -Name $aadrm -AllVersions
            Write-Host -ForegroundColor Green "${aadrm} Uninstalled!"
            if (-not(Get-InstalledModule -Name $aip -ErrorAction SilentlyContinue)) {
                Write-Host -ForegroundColor Red "${aip} Not Found. Installing ${az}..."
                Install-Module -Name $az -Force -AllowClobber -Confirm:$False
                Write-Host -ForegroundColor Green "${aip} Installed!"
            } else {
                Write-Host -ForegroundColor Green "${aip} Installed!"
            }
        }
}else {
    $aip = "AIPService"
    if (-not(Get-InstalledModule -Name $aip -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red "${aip} Not Found. Installing ${aip}..."
        Install-Module -Name $aip -Force -AllowClobber -Confirm:$False
        Write-Host -ForegroundColor Green "${aip} Installed!"
    } else {
        Write-Host -ForegroundColor Green "${aip} Installed!"
    }
}





Write-Host ""
Write-Host -ForegroundColor Cyan "All latest M365 and Azure Powershell modules have been installed. You may close this session."

Pause
