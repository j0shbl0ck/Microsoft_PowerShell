
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Check if PSWindowsUpdate module is installed
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "PSWindowsUpdate module is not installed. Installing..."
    #Install-Module -Name PSWindowsUpdate -Confirm:$false

} else {
    Write-Host "PSWindowsUpdate module is already installed."
}

# Import the PSWindowsUpdate module
Import-Module PSWindowsUpdate

# Install the available Windows updates
Install-WindowsUpdate -AcceptAll -IgnoreReboot