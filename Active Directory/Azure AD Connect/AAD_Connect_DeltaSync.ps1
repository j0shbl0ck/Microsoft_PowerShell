<#
.SYNOPSIS
    This script performs a delta sync on Azure AD Connect. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.8
    Date: 02.10.22
    Type: Public
.NOTES

.LINK

#>

#Requires -RunAsAdministrator
Clear-Host

# ask user if they are on dc or local machine
$userlocation = Read-Host -Prompt "Are you on the DC (where AAD Connect is hosted) [y/n]"
# if enters y
if ($userlocation -eq "y") {
    # ask for what type of sync they want to perform
    $syncType = Read-Host -Prompt "What type of sync do you want to perform? [full/delta]"
    # if enters full
    if ($syncType -eq "full") {
        # run full sync
        Start-ADSyncSyncCycle -PolicyType Initial
    }
    # if enters delta
    elseif ($syncType -eq "delta") {
        Start-ADSyncSyncCycle -PolicyType Delta
        }
}

# if enters n
if ($userlocation -eq "n") {

    $userlocal = Read-Host -Prompt "Are you on a local Windows machine connected to the same network as the DC [y/n]"

    # if enters y
    if ($userlocal -eq "y") {
        # check if msol module is installed
        Write-Host "Checking for MSOnline Module..."
        $msolInstalled = (Get-Module -ListAvailable -Name MSOnline)

        # create function if msol module is installed
        if ($msolInstalled) {
            Write-Host "MSOnline Module Found!"
            # Enter global admin credentials
            Connect-MsolService
            # Retrives AD Connect Hostname
            $adconnectserver = (Get-MsolCompanyInformation).DirSyncClientMachineName
            Write-Host "Current Azure AD Connect Server: $adconnectserver"
            Write-Host "Creating remote session to $adconnectserver..."
            # create remote session
            $session = New-PSSession -ComputerName $adconnectserver -Credential $credential -Authentication Kerberos
            Import-Module ADSync
            # show current schedule settings for ADSync
            Get-ADSyncSchedule
            performsync
            # close remote session
            Exit-PSSession -Session $session

        }
        }
        # if msol module is not installed
        else {
            Write-Host -ForegroundColor Yellow "MSOnline Module not found. Would you like to install it?"
            $installmsol = Read-Host -Prompt "Install MSOnline Module [y/n]"
            # if enters y
            if ($installmsol -eq "y") {
                Write-Host -ForegroundColor Yellow "Finding AzureAD V1 PowerShell Module..."
                $mso = "MSOnline"
                if (-not(Get-InstalledModule -Name $mso -ErrorAction SilentlyContinue)) {
                    Write-Host -ForegroundColor Red "${mso} Not Found. Installing ${mso}..."
                    Install-Module -Name $mso -Force -Confirm:$False
                    Write-Host -ForegroundColor Green "${mso} Installed!"
                } else {
                    Write-Host -ForegroundColor Green "${mso} Installed!"
                }
                # Enter global admin credentials
                Connect-MsolService
                # Retrives AD Connect Hostname
                $adconnectserver = (Get-MsolCompanyInformation).DirSyncClientMachineName
                Write-Host "Current Azure AD Connect Server: $adconnectserver"
                Write-Host "Creating remote session to $adconnectserver..."
                # create remote session
                $session = New-PSSession -ComputerName $adconnectserver -Credential $credential -Authentication Kerberos
                Import-Module ADSync
                # show current schedule settings for ADSync
                Get-ADSyncSchedule
                performsync
                # close remote session
                Exit-PSSession -Session $session
            }
            # if enters n
            elseif ($installmsol -eq "n") {
                Write-Host "User denied installation of MSOnline Module. Exiting..."
            }
        }
    }
    # if enters n
    elseif ($userlocal -eq "n") {
        Write-Host "Computer not under same network or denied permissions. Exiting..."
    }

# if enters anything else
#else {
    # Write-Host "Invalid input. Please enter y or n."
    # run script again
#}
