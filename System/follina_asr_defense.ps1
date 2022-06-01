<#
.SYNOPSIS
    This script blocks Office applications from creating child processes. If the device is managed by Intune, use ASR configuration as this won't work if it is. Run script as administrator. 
    Author: Josh Block
.NOTES
    Version: 1.0.0
    Date: 06.01.22
    Type: Public
.LINK
    https://github.com/j0shbl0ck
    https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference?view=o365-worldwide#block-all-office-applications-from-creating-child-processes
    https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/enable-attack-surface-reduction?view=o365-worldwide
    https://blog.ciaops.com/2020/11/23/show-asr-settings-for-device-with-powershell/
    https://github.com/directorcia/Office365/blob/master/win10-asr-get.ps1

#>

# <d4f940ab-401b-4efc-aadc-ad5f3c50688a> is the GUID for "Block all Office applications from creating child processes"
Set-MpPreference -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a -AttackSurfaceReductionRules_Actions Enabled
