<#
.SYNOPSIS
    This script creates a disables Windows Hello for Business
    Author: Josh Block
.NOTES
    Version: 1.0.0
    Date: 1.02.25
    Type: Private
.LINK
    https://github.com/j0shbl0ck
#>

function Write-Log {
    param(
        [string] $message,
        [bool] $success = $true
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "${timestamp}: ${message}"
    if ($success) {
        $logLine = "[SUCCESS] $logLine"
    } else {
        $logLine = "[ERROR] $logLine"
    }
    
    # Replace "C:\path\to\your\logfile.txt" with your desired log file path
    Add-Content -Path "C:\temp\DisableWHfB_Conf.txt" -Value $logLine
}


# Modify registry key for disabling WHfB
try {
    Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name 'AllowDomainPINLogon' -Value 0
} catch {
    Write-Log "Failed to set registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name 'AllowDomainPINLogon' -Value 0
} catch {
    Write-Log "Failed to set registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    Set-ItemProperty HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions -Name 'value' -Value 0
} catch {
    Write-Log "Failed to set registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\' -Name 'Biometrics' -Force
} catch {
    Write-Log "Failed to create registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Biometrics' -Name 'Enabled' -Value 0 -PropertyType Dword -Force
} catch {
    Write-Log "Failed to set registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\' -Name 'PassportforWork' -Force
} catch {
    Write-Log "Failed to create registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\PassportforWork' -Name 'Enabled' -Value 0 -PropertyType Dword -Force
} catch {
    Write-Log "Failed to set registry key for disabling WHfB: $($_.Exception.Message)", $false
}
try {
    Start-Process cmd -ArgumentList '/s,/c,takeown /f C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC /r /d y & icacls C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC /grant administrators:F /t & RD /S /Q C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc & MD C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc & icacls C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc /T /Q /C /RESET' -Verb runAs
} catch {
    Write-Log "Failed to delete NGC folder: $($_.Exception.Message)", $false
}
