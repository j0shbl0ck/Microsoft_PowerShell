<#
.SYNOPSIS
    This script deploys web shortcuts to the desktop of a user.
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.0
    Date: 01.02.24
    Type: Public
.NOTES
    This script it built for the Datto RMM platform.
.LINK
    https://github.com/j0shbl0ck
    https://community.spiceworks.com/topic/2460962-powershell-script-to-create-desktop-shortcut-using-inprivate-incognito-mode
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
    Add-Content -Path "C:\temp\datto_client_links.txt" -Value $logLine
}

# Create Microsoft 365 Link for Microsoft Edge
$wshshell = New-Object -ComObject WScript.Shell
try {
    $lnk = $wshshell.CreateShortcut($env:PUBLIC + "\Desktop\microsoft365.lnk")
    $lnk.WorkingDirectory = "C:\Program Files (x86)\Microsoft\Edge\Application"
    $lnk.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    $lnk.Arguments = "https://www.microsoft365.com/"
    $lnk.Save()
    Write-Log "Microsoft 365 link created successfully."
} catch {
    Write-Log "Failed to create Microsoft 365 link: $($_.Exception.Message)", $false
}

# Create Outlook Web Link for Chrome
$wshshell = New-Object -ComObject WScript.Shell
try {
    $lnk = $wshshell.CreateShortcut($env:PUBLIC + "\Desktop\outlookweb.lnk")
    $lnk.WorkingDirectory = "C:\Program Files (x86)\Microsoft\Edge\Application"
    $lnk.TargetPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    $lnk.Arguments = "https://outlook.office.com/"
    $lnk.Save()
    Write-Log "Outlook Web created successfully."
} catch {
    Write-Log "Failed to create Outlook Web link: $($_.Exception.Message)", $false
}

## Duplicate the above code for each link you want to create