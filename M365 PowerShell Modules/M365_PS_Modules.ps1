<#
.SYNOPSIS
    This script installs the M365 Powershell Module Services.
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.12.22
    Type: Public
.NOTES
    You will need accept the "Untrusted Repository" prompts.
    To use Microsoft Graph Intune, you will need to run for the first time:  Connect-MSGraph -AdminConsent 
.LINK
    Source: https://o365reports.com/2019/11/01/install-all-office-365-powershell-modules/
#>

# To be able to execute scripts, if not already performed
Set-ExecutionPolicy RemoteSigned
Install-Module -Name PowerShellGet -Force -AllowClobber

# Installs Exchange Powershell Module
Install-Module -Name ExchangeOnlineManagement

# Installs SharePoint Online Powershell Module
Install-Module -Name PowerShellGet -Force -AllowClobber

# Install SharePoint PNP Powershell Module
Install-Module PnP.PowerShell

# Install AzureAD V1 Powershell Module
Install-Module -Name MSOnline

# Install AzureAD V2 PowerShell Module
Install-Module -Name AzureAD

# Install Microsoft Intune PowerShell Module
Install-Module Microsoft.Graph.Intune

# Install Autopilot Diagnostics
Install-Script Get-AutopilotDiagnostics -Force

# Install Teams PowerShell Module
Install-Module -Name MicrosoftTeams -Force -AllowClobber

Pause