<#
.SYNOPSIS
    This takes a CSV using the headers "Work Email","Work Phone", "Manager, and "Mobile Phone" to update respective attributes in AD.
.NOTES
    Author: Josh Block
    Date: 01.09.25
    Type: Public
    Version: 1.0.7
.LINK
    https://github.com/j0shbl0ck
#>

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

Import-Module ActiveDirectory

# Prompt user to select the CSV file
Add-Type -AssemblyName System.Windows.Forms
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$openFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
$openFileDialog.Title = "Select the CSV file"

if ($openFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Exiting script." -ForegroundColor Red
    exit
}

$csvPath = $openFileDialog.FileName

# Import CSV
try {
    $users = Import-Csv -Path $csvPath
} catch {
    Write-Host "Failed to import CSV. Ensure the file format is correct." -ForegroundColor Red
    exit
}

foreach ($user in $users) {
    if (-not ($user."Work Email" -and ($user."Work Phone" -or $user."Mobile Phone"))) {
        Write-Host "Skipping row due to missing required columns." -ForegroundColor Yellow
        continue
    }

    $userPrincipalName = $user."Work Email"
    $workPhone = $user."Work Phone" -replace "[^\d]", ""
    $mobilePhone = $user."Mobile Phone" -replace "[^\d]", ""
    $department = $user."Department"
    $jobTitle = $user."Job Title"
    $Manager = $user."Reporting to"
    $office = $user."Location"

    try {
        $adUser = Get-ADUser -Filter { emailaddress -like $userPrincipalName } -Properties SamAccountName
        if ($null -eq $adUser) {
            Write-Host "User with email $userPrincipalName not found in AD. Skipping." -ForegroundColor Yellow
            continue
        }

        $findManager = if ($Manager) { 
            Get-ADUser -Filter { displayName -like ${Manager} } -Properties * | Select-Object -ExpandProperty DistinguishedName 
        } else { 
            $null
        }

        $params = @{}
        if ($workPhone) { $params['OfficePhone'] = $workPhone }
        if ($mobilePhone) { $params['MobilePhone'] = $mobilePhone }
        if ($department) { $params['Department'] = $department }
        if ($jobTitle) { $params['Title'] = $jobTitle }
        if ($findManager) { $params['Manager'] = $findManager }
        if ($office) { $params['Office'] = $office }

        Set-ADUser -Identity $adUser @params -ErrorAction Stop
        Write-Host "Updated user: $($adUser.SamAccountName)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to update user: $userPrincipalName. Error: $_" -ForegroundColor Red
    }
}
