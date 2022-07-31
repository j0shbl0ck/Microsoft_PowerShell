<#
.SYNOPSIS
    This script creates a localadmin account on the device. Use .\ to login into system.
    Author: Josh Block
.NOTES
    Version: 1.0.8
    Date: 07.25.22
    Type: Public
.LINK
    https://github.com/j0shbl0ck
#>

# Ask user for username

Clear-Host
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$ObjLocalUser = $null

#User to search for
$USERNAME = $(Write-Host "Enter a username for the user account: " -ForegroundColor Cyan -NoNewLine; Read-Host) 

try {
    Write-Host "Searching for $($USERNAME) in User Accounts..." -ForegroundColor yellow
    $ObjLocalUser = Get-LocalUser $USERNAME
    $userfound = $(Write-Host "User $($USERNAME) was found! Reset $($USERNAME) password to continue? (y/n) " -ForegroundColor red -NoNewLine; Read-Host)
    do {
        if ($userfound -eq "y") {
            # user to enter new password if user found
            $Password = $(Write-Host "Enter a password for $($USERNAME): " -ForegroundColor yellow -NoNewLine; Read-Host)
            $convertedpassword = ConvertTo-SecureString $Password -AsPlainText -Force
            Write-Host "Resetting $($USERNAME) from User Accounts" -ForegroundColor yellow
            Set-LocalUser -Name $USERNAME -Password $convertedpassword -PasswordNeverExpires:$true
            Write-Host "User $($USERNAME) password was reset." -ForegroundColor green
            Write-Host "See $($USERNAME) information below. " -ForegroundColor DarkGray
            Get-LocalUser -Name $USERNAME | Select-Object *
            # get groups the user is in
            Write-Host "User $($USERNAME) is in the following groups: " -ForegroundColor DarkGray
            foreach ($LocalGroup in Get-LocalGroup) {
                if (Get-LocalGroupMember $LocalGroup -Member $USERNAME -ErrorAction SilentlyContinue)
                {
                    $LocalGroup.Name | Format-Table -AutoSize 
                }
            }
            break
        }
    } until ($userfound -eq "n")

}
catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
    Write-Host "User $($USERNAME) was not found!" -ForegroundColor green | Write-Warning
}
catch {
    "An unspecifed error occured" | Write-Error
    Exit # Stop Powershell! 
}

#Create the user if it was not found (Example)
if (!$ObjLocalUser) {
    Write-Host "Creating User $($USERNAME)..." -ForegroundColor yellow
    # Ask user for password
    $Password = $(Write-Host "Enter a password for the user account: " -ForegroundColor Magenta -NoNewLine; Read-Host)
    $convertedpassword = ConvertTo-SecureString $Password -AsPlainText -Force

    # Ask user for full name
    $FullName = $(Write-Host "Enter the full name for the user account: " -ForegroundColor Magenta -NoNewLine; Read-Host)

    # Ask user for description of account
    $Description = $(Write-Host "Enter a description for the user account: " -ForegroundColor Magenta -NoNewLine; Read-Host)

    # Get local groups and ask user which one the user should be added to
    Get-LocalGroup | Format-Table -AutoSize 
    $localgroup = $(Write-Host "Enter the name of the group the user should be added to: " -ForegroundColor Magenta -NoNewLine; Read-Host)

    # Create the user
    New-LocalUser $USERNAME -Password $convertedpassword -FullName $FullName -Description $Description
    Add-LocalGroupMember -Group $localgroup -Member $USERNAME
    Set-LocalUser -Name $USERNAME -PasswordNeverExpires:$true
    Write-Host ""

    # Ask user if they would like to view user account in Local Users and Groups
    $viewuser = $(Write-Host "User has been created. Would you like to view the user information in Local Users and Groups? (y/n): " -ForegroundColor Cyan -NoNewLine; Read-Host)
    if ($viewuser -eq "y")
    {
        # open Local Users and Groups
        Start-Process lusrmgr -Verb runas
    } else {
        # Show user information
        Write-Host "See $($USERNAME) information below. " -ForegroundColor green
        Get-LocalUser -Name $USERNAME | Select-Object *
        # get groups the user is in
        Write-Host "User $($USERNAME) is in the following groups: " -ForegroundColor DarkGray
        foreach ($LocalGroup in Get-LocalGroup) {
            if (Get-LocalGroupMember $LocalGroup -Member $USERNAME -ErrorAction SilentlyContinue)
            {
            $LocalGroup.Name | Format-Table -AutoSize 
            }
        }
        
        # end the script
        Write-Host ""
        Write-Host "Press Any Key To Exit" -ForegroundColor DarkMagenta -NoNewLine; Read-Host
        exit
    }
}



