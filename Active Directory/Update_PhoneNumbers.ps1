<#
.SYNOPSIS
    This takes a CSV using the headers "Work Email","Work Phone", and "Mobile Phone" to update respective attributes in AD.
.NOTES
    Author: Josh Block
    Date: 01.09.25
    Type: Public
    Version: 1.0.4
.LINK
    https://github.com/j0shbl0ck
#>

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
    # Validate required columns exist
    if (-not ($user."Work Email" -and ($user."Work Phone" -or $user."Mobile Phone"))) {
        Write-Host "Skipping row due to missing required columns." -ForegroundColor Yellow
        continue
    }

    # Extract and sanitize values from each column header. 
    $userPrincipalName = $user."Work Email"
    $workPhone = $user."Work Phone" -replace "[^\d]", ""
    $mobilePhone = $user."Mobile Phone" -replace "[^\d]", ""
    $department = $user."Department"
    $jobTitle = $user."Job Title"
    $Manager = $user."Reporting to"
    $findManager = Get-ADUser -Filter { displayName -like "*$Mananger*" }
    $office = $user."Location"

    Get-ADUser  -filter * -SearchBase "OU=Chariton Valley Staff,DC=corp,DC=cvalley,DC=net" | Set-ADUser -OfficePhone $workPhone -MobilePhone $mobilePhone -Department $department -Title $jobTitle -Manager $findManager -Office $office -ErrorAction Ignore
    Write-Host "Updated $userPrincipalName work phone: $workPhone, mobile phone: $mobilePhone, department: $department, job title: $jobTitle, manager: $Manager, office: $office`n" -ForegroundColor Green
}