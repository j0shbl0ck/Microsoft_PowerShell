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
## Required for first time use (uncomment and run in seperate PS session)
# Connect-MSGraph -AdminConsent

# Install Autopilot Diagnostics
Install-Script Get-AutopilotDiagnostics -Force

# Install Teams PowerShell Module
Install-Module -Name MicrosoftTeams -Force -AllowClobber