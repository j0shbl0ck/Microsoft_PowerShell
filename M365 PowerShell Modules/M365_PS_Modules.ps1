<#
.SYNOPSIS
    This script installs the M365 Powershell Module Services.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.2
    Date: 01.12.22
    Type: Public
.NOTES
    You will need accept the "Untrusted Repository" prompts.
    To use Microsoft Graph Intune, you will need to run for the first time:  Connect-MSGraph -AdminConsent 
.LINK
    Source: https://o365reports.com/2019/11/01/install-all-office-365-powershell-modules/
#>
Write-Host -ForegroundColor Cyan "Checking for latest M365 Powershell modules..."
# To be able to execute scripts, if not already performed
if (-not(Get-InstalledModule -Name PowerShellGet -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "PowerShellGet Not Found. Installing PowerShellGet..."
    Set-ExecutionPolicy RemoteSigned
    Install-Module -Name PowerShellGet -Force -AllowClobber -Confirm:$False
    Write-Host -ForegroundColor Green "PowerShellGet Installed!"
} else {
    Write-Host -ForegroundColor Green "PowerShellGet Installed!"
}


# Installs Exchange Powershell Module
$exo = "ExchangeOnlineManagement"
if (-not(Get-InstalledModule -Name -Name $exo -MinimumVersion 2.0.5 -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${exo} Not Found. Installing ${exo}..."
    Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5 -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${exo} Installed!"
} else {
    Write-Host -ForegroundColor Green "${exo} Installed!"
}


# Installs SharePoint Online Powershell Module
$sop = "Microsoft.Online.SharePoint.PowerShell"
if (-not(Get-InstalledModule -Name -Name $sop -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${sop} Not Found. Installing ${sop}..."
    Install-Module -Name $sop -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${sop} Installed!"
} else {
    Write-Host -ForegroundColor Green "${sop} Installed!"
}

# Install SharePoint PNP Powershell Module
$pnp = "PnP.PowerShell"
if (-not(Get-InstalledModule -Name -Name $pnp -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${pnp} Not Found. Installing ${pnp}..."
    Install-Module -Name $pnp -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${pnp} Installed!"
} else {
    Write-Host -ForegroundColor Green "${pnp} Installed!"
}

# Install AzureAD V1 Powershell Module
$mso = "MSOnline"
if (-not(Get-InstalledModule -Name -Name $mso -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mso} Not Found. Installing ${mso}..."
    Install-Module -Name $mso -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${mso} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mso} Installed!"
}

# Install AzureAD V2 PowerShell Module
$aad = "AzureAD"
if (-not(Get-InstalledModule -Name -Name $aad -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${aad} Not Found. Installing ${aad}..."
    Install-Module -Name $aad -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${aad} Installed!"
} else {
    Write-Host -ForegroundColor Green "${aad} Installed!"
}

# Install Microsoft Intune PowerShell Module
$mgi = "Microsoft.Graph.Intune"
if (-not(Get-InstalledModule -Name -Name $mgi -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mgi} Not Found. Installing ${mgi}..."
    Install-Module -Name $mgi -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${mgi} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mgi} Installed!"
}

# Install Autopilot Diagnostics
$gad = "Microsoft.Graph.Intune"
if (-not(Get-InstalledScript -Name -Name $gad -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${gad} Not Found. Installing ${gad}..."
    Install-Script -Name $gad -Force -Confirm:$False
    Write-Host -ForegroundColor Green "${gad} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mgi} Installed!"
}

# Install Teams PowerShell Module
$mst = "MicrosoftTeams"
if (-not(Get-InstalledModule -Name -Name $mst -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red "${mst} Not Found. Installing ${mst}..."
    Install-Module -Name $mst -Force -AllowClobber -Confirm:$False
    Write-Host -ForegroundColor Green "${mst} Installed!"
} else {
    Write-Host -ForegroundColor Green "${mst} Installed!"
}

Pause