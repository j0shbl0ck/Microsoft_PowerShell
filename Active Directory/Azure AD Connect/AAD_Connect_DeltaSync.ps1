<#
.SYNOPSIS
    This script performs a delta sync on Azure AD Connect. 
.DESCRIPTION
    Author: j0shbl0ck https://github.com/j0shbl0ck
    Version: 1.0.7
    Date: 02.10.22
    Type: Public
.NOTES

.LINK

#>


# ask user if they are on dc or local machine
$userlocation = Read-Host -Prompt "Are you on the DC (where AAD Connect is hosted) [y/n]" -AsSecureString -RawInput
# if enters y
if ($userlocation -eq "y") {
    # ask for what type of sync they want to perform
    $syncType = Read-Host -Prompt "What type of sync do you want to perform? [full/delta]" -AsSecureString -RawInput
    # if enters full
    if ($syncType -eq "full") {
        # run full sync
        $fullSync = Start-Process -FilePath "C:\Program Files\Azure Active Directory Connect\AzureADConnectSync.exe" -ArgumentList "-full" -Wait
        # if full sync is successful
        if ($fullSync.ExitCode -eq 0) {
            # write to log
            Write-Host "Full sync completed successfully."
        }
        # if full sync fails
        else {
            # write to log
            Write-Host "Full sync failed."
        }
    }
    # if enters delta
    elseif ($syncType -eq "delta") {
        # ask for what type of delta sync they want to perform
        $deltaSyncType = Read-Host -Prompt "What type of delta sync do you want to perform? [full/incremental]" -AsSecureString -RawInput
        # if enters full
        if ($deltaSyncType -eq "full") {
            # run full delta sync
            $fullDeltaSync = Start-Process -FilePath "C:\Program Files\Azure Active Directory Connect\AzureADConnectSync.exe" -ArgumentList "-full" -Wait
            # if full delta sync is successful
            if ($fullDeltaSync.ExitCode -eq 0) {
                # write to log
                Write-Host "Full delta sync completed successfully."
            }
            # if full delta sync fails
            else {
                # write to log
                Write-Host "Full delta sync failed."
            }
        }
        # if enters incremental
        elseif ($deltaSyncType -eq "incremental") {
            # run incremental delta sync
            $incrementalDeltaSync = Start-Process -FilePath "C:\Program Files\Azure Active Directory Connect\AzureADConnectSync.exe" -ArgumentList "-incremental" -Wait
            # if incremental delta sync is successful
            if ($incrementalDeltaSync.ExitCode -eq 0) {
                # write to log
                Write-Host "Incremental delta sync completed successfully."
            }
            # if incremental delta sync fails
            else {
                # write to log
                Write-Host "Incremental delta sync failed."
            }
        }
    }

}
# if enters n
if ($userlocation -eq "[nN]") {

    $userlocal = Read-Host -Prompt "Are you on a local Windows machine connected to the same network as the DC [y/n]" -AsSecureString -RawInput

    # if enters y
    if ($userlocal -eq "[yY]") {
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
            "MSOnline Module not found. Would you like to install it?"
            $installmsol = Read-Host -Prompt "Install MSOnline Module [y/n]" -AsSecureString -RawInput
            # if enters y
            if ($installmsol -eq "[yY]") {
                Install-Module MSOnline
                Write-Host "MSOnline Module Installed!"
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
            elseif ($installmsol -eq "[nN]") {
                Write-Host "User denied installation of MSOnline Module. Exiting..."
            }
        }
    }
    # if enters n
    elseif ($userlocal -eq "[nN]") {
        Write-Host "Computer not under same network or denied permissions. Exiting..."
    }

}
# if enters anything else
else {
    Write-Host "Invalid input. Please enter y or n."
    # run script again
}
