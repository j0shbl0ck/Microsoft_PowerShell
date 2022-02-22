<#
.SYNOPSIS
    This script installs the M365 and Azure Powershell Module Services.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.3.8
    Date: 01.12.22
    Type: Public
.NOTES
    To use Microsoft Graph Intune, you will need to run for the first time:  Connect-MSGraph -AdminConsent 
.LINK
    Source: https://o365reports.com/2019/11/01/install-all-office-365-powershell-modules/
#>

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
Write-Host -ForegroundColor Yellow "Finding PowerShellGet Module..."
if (-not(Get-InstalledModule -Name PowerShellGet -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "PowerShellGet Not Found. Installing PowerShellGet..."
    Set-ExecutionPolicy RemoteSigned
    Install-Module -Name PowerShellGet -Force -AllowClobber -Confirm:$False
    Write-Host -ForegroundColor Green "PowerShellGet Installed!"
} else {
    Write-Host -ForegroundColor Green "PowerShellGet Installed!"
}


# Installs Exchange Powershell Module
Write-Host -ForegroundColor Yellow "Finding Exchange PowerShell Module..."
$exo = "ExchangeOnlineManagement"
if (-not(Get-InstalledModule -Name $exo -MinimumVersion 2.0.5 -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${exo} Not Found. Installing ${exo}..."
    Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${exo} Installed!"
} else {
    Write-Host -ForegroundColor Green "${exo} Installed!"
}

# Installs SharePoint Online Powershell Module
Write-Host -ForegroundColor Yellow "Finding SharePoint Online PowerShell Module..."
$sop = "Microsoft.Online.SharePoint.PowerShell"
if (-not(Get-InstalledModule -Name $sop -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${sop} Not Found. Installing ${sop}..."
    Install-Module -Name $sop -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${sop} Installed!"
} else {
    Write-Host -ForegroundColor Green "${sop} Installed!"
}

# Install Teams PowerShell Module
Write-Host -ForegroundColor Yellow "Finding Microsoft Teams Module..."
$mst = "MicrosoftTeams"
if (-not(Get-InstalledModule -Name $mst -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mst} Not Found. Installing ${mst}..."
    Install-Module -Name $mst -Force -AllowClobber -Confirm:$False
    Write-Host -ForegroundColor Green "${mst} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mst} Installed!"
}

# Install SharePoint PNP Powershell Module
Write-Host -ForegroundColor Yellow "Finding SharePoint PNP PowerShell Module..."
$pnp = "SharePointPnPPowerShellOnline"
if (-not(Get-InstalledModule -Name $pnp -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${pnp} Not Found. Installing ${pnp}..."
    Install-Module -Name $pnp -SkipPublisherCheck -AllowClobber -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${pnp} Installed!"
} else {
    Write-Host -ForegroundColor Green "${pnp} Installed!"
}

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


Write-Host ""
Write-Host -ForegroundColor Cyan "All latest M365 and Azure Powershell modules have been installed. You may close this session."

Pause
