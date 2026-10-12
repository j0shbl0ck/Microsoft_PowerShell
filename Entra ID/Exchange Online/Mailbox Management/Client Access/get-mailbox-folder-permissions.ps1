<#
.SYNOPSIS
    Interactive, menu-driven tool for reviewing and managing Exchange Online mailbox folder permissions.

.DESCRIPTION
    Mailbox Folder Permission Manager gives administrators and delegate-support staff a guided
    console menu for working with folder-level permissions on any Exchange Online mailbox,
    such as a shared mailbox or a mailbox an assistant manages on someone's behalf.

    No parameters are required. From the menu you can:
      - Look up a mailbox by its email address
      - Review the full folder tree with every explicit folder permission
      - Search for a folder by name, path fragment, or wildcard
      - Grant, update, or remove folder permissions
      - Optionally add FolderVisible to parent folders so a shared subfolder appears in Outlook
      - Export a detailed permission report to CSV
      - Export the folder tree as a self-contained, interactive HTML report

    Reports are saved to a "Reports" folder under the current working directory.

.EXAMPLE
    .\MailboxFolderPermissionManager.ps1

    Connects to Exchange Online (if not already connected) and opens the main menu.

.NOTES
    Name:      MailboxFolderPermissionManager.ps1
    Author:    Josh Block
    Version:   1.0.0
    Requires:  ExchangeOnlineManagement module; an account with permission to read and
               change mailbox folder permissions (for example, the Exchange Administrator role)

    Changes made through this tool take effect immediately. Test against a non-production
    mailbox before using it in production.

.LINK
    https://github.com/j0shbl0ck
#>

#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SelectedMailbox = $null
$script:FolderCache = @()

# Safe in a script file, console paste, ISE selection, or VS Code selection.
$script:BasePath = (Get-Location).Path
if ([string]::IsNullOrWhiteSpace($script:BasePath)) {
    $script:BasePath = [Environment]::GetFolderPath('MyDocuments')
}
$script:ReportRoot = Join-Path -Path $script:BasePath -ChildPath 'Reports'

function Write-Title {
    param([Parameter(Mandatory)][string]$Text)
    Clear-Host
    $line = '=' * 72
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host (' {0}' -f $Text) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host
}

function Pause-Menu {
    [void](Read-Host 'Press Enter to continue')
}

function Read-MenuChoice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$ValidChoices
    )

    while ($true) {
        $choice = (Read-Host $Prompt).Trim()
        if ($ValidChoices -contains $choice) { return $choice }
        Write-Host 'Invalid selection. Please try again.' -ForegroundColor Yellow
    }
}

function Test-EmailAddress {
    param([Parameter(Mandatory)][string]$Address)
    return $Address -match '^[^\s@]+@[^\s@]+\.[^\s@]+$'
}

function Connect-ExchangeOnlineSession {
    Write-Title 'Mailbox Folder Permission Manager'

    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw 'ExchangeOnlineManagement is not installed. Run: Install-Module ExchangeOnlineManagement -Scope CurrentUser'
    }

    Import-Module ExchangeOnlineManagement -ErrorAction Stop

    $connected = $false
    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        try {
            $connected = $null -ne (Get-ConnectionInformation -ErrorAction Stop |
                Where-Object { $_.State -eq 'Connected' } |
                Select-Object -First 1)
        }
        catch {
            $connected = $false
        }
    }

    if (-not $connected) {
        Write-Host 'Connecting to Exchange Online...' -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false
    }
}

function ConvertTo-MailboxFolderPath {
    param([Parameter(Mandatory)][string]$FolderPath)

    if ($FolderPath -eq '/') { return '\' }
    return ($FolderPath -replace '^/', '\' -replace '/', '\')
}

function Get-FolderIdentity {
    param(
        [Parameter(Mandatory)][string]$MailboxAddress,
        [Parameter(Mandatory)][string]$FolderPath
    )

    $convertedPath = ConvertTo-MailboxFolderPath -FolderPath $FolderPath
    return '{0}:{1}' -f $MailboxAddress, $convertedPath
}

function Get-MailboxFolderCache {
    param([switch]$Refresh)

    if (-not $script:SelectedMailbox) {
        throw 'No mailbox is selected.'
    }

    if ($script:FolderCache.Count -gt 0 -and -not $Refresh) {
        return $script:FolderCache
    }

    Write-Host 'Loading mailbox folders...' -ForegroundColor Cyan
    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()

    # Use the standard Exchange Online remote cmdlet for folder statistics.
    $statistics = @(Get-MailboxFolderStatistics -Identity $mailboxAddress -ErrorAction Stop)

    $script:FolderCache = @(
        $statistics |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_.FolderPath) -and
                $_.FolderType -ne 'RecoverableItemsRoot' -and
                $_.FolderPath -notlike '/Recoverable Items*' -and
                $_.FolderPath -notlike '/Top of Information Store*'
            } |
            Sort-Object FolderPath |
            Select-Object Name, FolderPath, FolderType, ItemsInFolder, FolderSize
    )

    return $script:FolderCache
}

function Get-VisibleFolderPermissions {
    param([Parameter(Mandatory)][string]$FolderPath)

    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    $identity = Get-FolderIdentity -MailboxAddress $mailboxAddress -FolderPath $FolderPath

    try {
        return @(
            Get-MailboxFolderPermission -Identity $identity -ErrorAction Stop |
                Where-Object {
                    $userText = $_.User.ToString()
                    $userText -notin @('Default', 'Anonymous') -and
                    $_.AccessRights -notcontains 'None'
                }
        )
    }
    catch {
        Write-Verbose ('Unable to read permissions for {0}: {1}' -f $identity, $_.Exception.Message)
        return @()
    }
}

function Show-FolderTree {
    Write-Title 'Mailbox Folder Tree'
    Write-Host ('Mailbox: {0}' -f $script:SelectedMailbox.PrimarySmtpAddress) -ForegroundColor White
    Write-Host 'The full tree is expanded. Permissions are assigned on the exact folder shown.' -ForegroundColor DarkGray
    Write-Host

    try {
        $snapshot = @(Get-FolderPermissionSnapshot -Refresh)
    }
    catch {
        Write-Host ('Unable to load mailbox folders: {0}' -f $_.Exception.Message) -ForegroundColor Red
        Pause-Menu
        return
    }

    foreach ($entry in $snapshot) {
        $path = $entry.Folder.FolderPath
        $segments = @($path.Trim('/') -split '/')
        $depth = if ($path -eq '/') { 0 } else { [Math]::Max(0, $segments.Count - 1) }
        $indent = '    ' * $depth
        $displayName = if ($path -eq '/') { 'Mailbox Root' } else { $segments[-1] }

        Write-Host ('{0}{1}' -f $indent, $displayName) -ForegroundColor Cyan
        $permissions = @($entry.Permissions)

        if ($permissions.Count -eq 0) {
            Write-Host ('{0}    [No assigned user permissions]' -f $indent) -ForegroundColor DarkGray
        }
        else {
            foreach ($permission in $permissions) {
                Write-Host ('{0}    [{1} - {2}]' -f $indent, $permission.User, ($permission.AccessRights -join ', ')) -ForegroundColor Gray
            }
        }
    }

    Write-Host
    Write-Host '1. Export to HTML'
    Write-Host '2. Back'
    Write-Host

    $choice = Read-MenuChoice -Prompt 'Select option' -ValidChoices @('1', '2')
    if ($choice -eq '1') {
        Export-FolderTreeHtml -Snapshot $snapshot
        Pause-Menu
    }
}

function Search-MailboxFolder {
    try {
        $folders = @(Get-MailboxFolderCache)
    }
    catch {
        Write-Host ('Unable to load mailbox folders: {0}' -f $_.Exception.Message) -ForegroundColor Red
        Pause-Menu
        return $null
    }

    Write-Title 'Modify Folder Permissions'
    Write-Host 'Enter a folder name, path fragment, or wildcard.' -ForegroundColor Gray
    Write-Host 'Typing Inbox returns Inbox and paths containing Inbox.' -ForegroundColor Gray
    Write-Host 'Examples: Inbox, Travel, Board*, *Vendor*' -ForegroundColor DarkGray
    Write-Host

    $searchText = (Read-Host 'Folder search, or B to go back').Trim()
    if ($searchText -match '^(?i)b$' -or [string]::IsNullOrWhiteSpace($searchText)) {
        return $null
    }

    $hasWildcard = $searchText.Contains('*') -or $searchText.Contains('?')
    $pattern = if ($hasWildcard) { $searchText } else { '*{0}*' -f $searchText }

    $matches = @(
        $folders |
            Where-Object { $_.FolderPath -like $pattern -or $_.Name -like $pattern } |
            Sort-Object FolderPath
    )

    if ($matches.Count -eq 0) {
        Write-Host 'No matching folders were found.' -ForegroundColor Yellow
        Pause-Menu
        return $null
    }

    Write-Host
    for ($i = 0; $i -lt $matches.Count; $i++) {
        $displayPath = if ($matches[$i].FolderPath -eq '/') {
            'Mailbox Root'
        }
        else {
            $matches[$i].FolderPath.TrimStart('/') -replace '/', '\'
        }
        Write-Host ('{0,3}. {1}' -f ($i + 1), $displayPath)
    }
    Write-Host '  0. Back'
    Write-Host

    while ($true) {
        $selectionText = (Read-Host 'Select folder number').Trim()
        $selection = 0
        if ([int]::TryParse($selectionText, [ref]$selection)) {
            if ($selection -eq 0) { return $null }
            if ($selection -ge 1 -and $selection -le $matches.Count) {
                return $matches[$selection - 1]
            }
        }
        Write-Host 'Invalid selection. Please try again.' -ForegroundColor Yellow
    }
}

function Resolve-PermissionUser {
    while ($true) {
        $address = (Read-Host 'Enter the user email address, or B to go back').Trim()
        if ($address -match '^(?i)b$' -or [string]::IsNullOrWhiteSpace($address)) { return $null }

        if (-not (Test-EmailAddress -Address $address)) {
            Write-Host 'Enter a valid email address.' -ForegroundColor Yellow
            continue
        }

        try {
            return Get-Recipient -Identity $address -ErrorAction Stop
        }
        catch {
            Write-Host 'Recipient not found. Verify the email address and try again.' -ForegroundColor Yellow
        }
    }
}

function Select-AccessRight {
    $rights = @(
        'Owner',
        'PublishingEditor',
        'Editor',
        'PublishingAuthor',
        'Author',
        'NonEditingAuthor',
        'Reviewer',
        'Contributor',
        'FolderVisible'
    )

    Write-Host
    for ($i = 0; $i -lt $rights.Count; $i++) {
        Write-Host ('{0}. {1}' -f ($i + 1), $rights[$i])
    }
    Write-Host '0. Back'

    while ($true) {
        $inputValue = (Read-Host 'Select permission').Trim()
        $number = 0
        if ([int]::TryParse($inputValue, [ref]$number)) {
            if ($number -eq 0) { return $null }
            if ($number -ge 1 -and $number -le $rights.Count) {
                return $rights[$number - 1]
            }
        }
        Write-Host 'Invalid selection. Please try again.' -ForegroundColor Yellow
    }
}

function Confirm-Action {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host
    Write-Host $Message -ForegroundColor Yellow
    return (Read-MenuChoice -Prompt '1. Continue  2. Cancel' -ValidChoices @('1', '2')) -eq '1'
}

function Ensure-ParentFolderVisible {
    param(
        [Parameter(Mandatory)][string]$FolderPath,
        [Parameter(Mandatory)][string]$UserAddress
    )

    if ($FolderPath -eq '/') { return }

    $segments = @($FolderPath.Trim('/') -split '/')
    if ($segments.Count -le 1) { return }

    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    $parentPaths = New-Object System.Collections.Generic.List[string]
    $parentPaths.Add('/')

    for ($i = 1; $i -lt $segments.Count; $i++) {
        $parentPaths.Add('/' + (($segments[0..($i - 1)]) -join '/'))
    }

    foreach ($parentPath in @($parentPaths | Select-Object -Unique)) {
        $identity = Get-FolderIdentity -MailboxAddress $mailboxAddress -FolderPath $parentPath
        $existing = $null

        try {
            $existing = Get-MailboxFolderPermission -Identity $identity -User $UserAddress -ErrorAction Stop
        }
        catch {
            $existing = $null
        }

        if ($null -eq $existing) {
            Add-MailboxFolderPermission -Identity $identity -User $UserAddress -AccessRights FolderVisible -Confirm:$false | Out-Null
            Write-Host ('Added FolderVisible: {0}' -f $parentPath) -ForegroundColor Green
        }
        elseif ($existing.AccessRights -contains 'None') {
            Set-MailboxFolderPermission -Identity $identity -User $UserAddress -AccessRights FolderVisible -Confirm:$false | Out-Null
            Write-Host ('Updated to FolderVisible: {0}' -f $parentPath) -ForegroundColor Green
        }
    }
}

function Add-SelectedFolderPermission {
    param([Parameter(Mandatory)]$Folder)

    $recipient = Resolve-PermissionUser
    if (-not $recipient) { return }

    $right = Select-AccessRight
    if (-not $right) { return }

    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    $identity = Get-FolderIdentity -MailboxAddress $mailboxAddress -FolderPath $Folder.FolderPath
    $userAddress = $recipient.PrimarySmtpAddress.ToString()

    if (-not (Confirm-Action -Message ('Grant {0} to {1} on {2}?' -f $right, $userAddress, $identity))) { return }

    try {
        Add-MailboxFolderPermission -Identity $identity -User $userAddress -AccessRights $right -Confirm:$false | Out-Null
        Write-Host 'Permission granted.' -ForegroundColor Green

        if ($Folder.FolderPath -ne '/' -and $right -ne 'FolderVisible') {
            $choice = Read-MenuChoice -Prompt 'Add FolderVisible on missing parent folders?  1. Yes  2. No' -ValidChoices @('1', '2')
            if ($choice -eq '1') {
                Ensure-ParentFolderVisible -FolderPath $Folder.FolderPath -UserAddress $userAddress
            }
        }
    }
    catch {
        Write-Host ('Grant failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
    }

    Pause-Menu
}

function Select-ExistingPermission {
    param([Parameter(Mandatory)]$Folder)

    $permissions = @(Get-VisibleFolderPermissions -FolderPath $Folder.FolderPath)
    if ($permissions.Count -eq 0) {
        Write-Host 'No assigned user permissions exist on this folder.' -ForegroundColor Yellow
        Pause-Menu
        return $null
    }

    Write-Host
    for ($i = 0; $i -lt $permissions.Count; $i++) {
        Write-Host ('{0}. {1} [{2}]' -f ($i + 1), $permissions[$i].User, ($permissions[$i].AccessRights -join ', '))
    }
    Write-Host '0. Back'

    while ($true) {
        $inputValue = (Read-Host 'Select user').Trim()
        $number = 0
        if ([int]::TryParse($inputValue, [ref]$number)) {
            if ($number -eq 0) { return $null }
            if ($number -ge 1 -and $number -le $permissions.Count) {
                return $permissions[$number - 1]
            }
        }
        Write-Host 'Invalid selection. Please try again.' -ForegroundColor Yellow
    }
}

function Set-SelectedFolderPermission {
    param([Parameter(Mandatory)]$Folder)

    $permission = Select-ExistingPermission -Folder $Folder
    if (-not $permission) { return }

    $right = Select-AccessRight
    if (-not $right) { return }

    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    $identity = Get-FolderIdentity -MailboxAddress $mailboxAddress -FolderPath $Folder.FolderPath
    $userText = $permission.User.ToString()

    if (-not (Confirm-Action -Message ('Update {0} to {1} on {2}?' -f $userText, $right, $identity))) { return }

    try {
        Set-MailboxFolderPermission -Identity $identity -User $userText -AccessRights $right -Confirm:$false | Out-Null
        Write-Host 'Permission updated.' -ForegroundColor Green
    }
    catch {
        Write-Host ('Update failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
    }

    Pause-Menu
}

function Remove-SelectedFolderPermission {
    param([Parameter(Mandatory)]$Folder)

    $permission = Select-ExistingPermission -Folder $Folder
    if (-not $permission) { return }

    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    $identity = Get-FolderIdentity -MailboxAddress $mailboxAddress -FolderPath $Folder.FolderPath
    $userText = $permission.User.ToString()

    if (-not (Confirm-Action -Message ('Remove {0} from {1}?' -f $userText, $identity))) { return }

    try {
        Remove-MailboxFolderPermission -Identity $identity -User $userText -Confirm:$false
        Write-Host 'Permission removed.' -ForegroundColor Green
        Write-Host 'Outlook may require time or a restart before the folder disappears.' -ForegroundColor DarkGray
    }
    catch {
        Write-Host ('Removal failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
    }

    Pause-Menu
}

function Show-FolderDetailsMenu {
    param([Parameter(Mandatory)]$Folder)

    while ($true) {
        Write-Title 'Folder Details'
        $displayPath = if ($Folder.FolderPath -eq '/') {
            'Mailbox Root'
        }
        else {
            $Folder.FolderPath.TrimStart('/') -replace '/', '\'
        }

        Write-Host ('Folder: {0}' -f $displayPath) -ForegroundColor White
        Write-Host
        Write-Host 'Current Permissions' -ForegroundColor Cyan

        $permissions = @(Get-VisibleFolderPermissions -FolderPath $Folder.FolderPath)
        if ($permissions.Count -eq 0) {
            Write-Host '  No assigned user permissions.' -ForegroundColor DarkGray
        }
        else {
            foreach ($permission in $permissions) {
                Write-Host ('  {0,-40} {1}' -f $permission.User.ToString(), ($permission.AccessRights -join ', '))
            }
        }

        Write-Host
        Write-Host '1. Grant Access'
        Write-Host '2. Update Access'
        Write-Host '3. Remove Access'
        Write-Host '4. Back'
        Write-Host

        $choice = Read-MenuChoice -Prompt 'Select option' -ValidChoices @('1', '2', '3', '4')
        switch ($choice) {
            '1' { Add-SelectedFolderPermission -Folder $Folder }
            '2' { Set-SelectedFolderPermission -Folder $Folder }
            '3' { Remove-SelectedFolderPermission -Folder $Folder }
            '4' { return }
        }
    }
}

function Start-ModifyPermissions {
    while ($true) {
        $folder = Search-MailboxFolder
        if (-not $folder) { return }
        Show-FolderDetailsMenu -Folder $folder
    }
}

function Export-DetailedPermissionReport {
    Write-Title 'Export Detailed Permission Report'
    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    Write-Host ('Mailbox: {0}' -f $mailboxAddress)
    Write-Host

    if (-not (Confirm-Action -Message 'Generate the detailed permission report as CSV?')) { return }

    if (-not (Initialize-ReportFolder)) {
        Pause-Menu
        return
    }

    $rows = New-Object System.Collections.Generic.List[object]

    try {
        $folders = @(Get-MailboxFolderCache -Refresh)
    }
    catch {
        Write-Host ('Unable to load mailbox folders: {0}' -f $_.Exception.Message) -ForegroundColor Red
        Pause-Menu
        return
    }

    foreach ($folder in $folders) {
        $displayPath = if ($folder.FolderPath -eq '/') {
            'Mailbox Root'
        }
        else {
            $folder.FolderPath.TrimStart('/') -replace '/', '\'
        }

        foreach ($permission in @(Get-VisibleFolderPermissions -FolderPath $folder.FolderPath)) {
            $rows.Add([pscustomobject]@{
                Mailbox        = $mailboxAddress
                FolderPath     = $displayPath
                User           = $permission.User.ToString()
                PermissionType = if ($folder.FolderType -eq 'Calendar') { 'Calendar' } else { 'Folder' }
                Permission     = ($permission.AccessRights -join ';')
            })
        }
    }

    foreach ($access in @(Get-MailboxLevelAccess)) {
        $rows.Add([pscustomobject]@{
            Mailbox        = $mailboxAddress
            FolderPath     = ''
            User           = $access.User
            PermissionType = $access.Type
            Permission     = if ($access.Type -eq 'FullAccess') { 'FullAccess' } else { 'Granted' }
        })
    }

    $safeName = ($mailboxAddress.Split('@')[0] -replace '[^a-zA-Z0-9._-]', '_')
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $csvPath = Join-Path -Path $script:ReportRoot -ChildPath ('{0}_{1}_DetailedPermissions.csv' -f $safeName, $timestamp)

    try {
        $rows |
            Sort-Object PermissionType, FolderPath, User |
            Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop

        Write-Host
        Write-Host 'Export completed successfully.' -ForegroundColor Green
        Write-Host $csvPath -ForegroundColor White
    }
    catch {
        Write-Host ('CSV export failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
    }

    Write-Host
    Pause-Menu
}

function Initialize-ReportFolder {
    if (Test-Path -LiteralPath $script:ReportRoot) { return $true }

    try {
        New-Item -ItemType Directory -Path $script:ReportRoot -Force -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Host ('Unable to create report folder: {0}' -f $_.Exception.Message) -ForegroundColor Red
        return $false
    }
}

function Get-FolderPermissionSnapshot {
    param([switch]$Refresh)

    $folders = @(Get-MailboxFolderCache -Refresh:$Refresh)
    $snapshot = New-Object System.Collections.Generic.List[object]
    $total = [Math]::Max(1, $folders.Count)
    $index = 0

    foreach ($folder in $folders) {
        $index++
        Write-Progress -Activity 'Reading folder permissions' -Status $folder.FolderPath -PercentComplete ([int](($index / $total) * 100))
        $snapshot.Add([pscustomobject]@{
            Folder      = $folder
            Permissions = @(Get-VisibleFolderPermissions -FolderPath $folder.FolderPath)
        })
    }

    Write-Progress -Activity 'Reading folder permissions' -Completed
    return $snapshot.ToArray()
}

function Get-MailboxLevelAccess {
    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()
    $results = New-Object System.Collections.Generic.List[object]

    try {
        foreach ($permission in @(Get-MailboxPermission -Identity $mailboxAddress -ErrorAction Stop |
            Where-Object {
                -not $_.IsInherited -and
                -not $_.Deny -and
                $_.User.ToString() -ne 'NT AUTHORITY\SELF' -and
                $_.AccessRights -contains 'FullAccess'
            })) {
            $results.Add([pscustomobject]@{ User = $permission.User.ToString(); Type = 'FullAccess' })
        }
    }
    catch {
        Write-Warning ('Full Access permissions could not be read: {0}' -f $_.Exception.Message)
    }

    try {
        foreach ($permission in @(Get-RecipientPermission -Identity $mailboxAddress -ErrorAction Stop |
            Where-Object {
                -not $_.IsInherited -and
                -not $_.Deny -and
                $_.Trustee.ToString() -ne 'NT AUTHORITY\SELF' -and
                $_.AccessRights -contains 'SendAs'
            })) {
            $results.Add([pscustomobject]@{ User = $permission.Trustee.ToString(); Type = 'SendAs' })
        }
    }
    catch {
        Write-Warning ('Send As permissions could not be read: {0}' -f $_.Exception.Message)
    }

    foreach ($delegate in @($script:SelectedMailbox.GrantSendOnBehalfTo)) {
        if ($null -eq $delegate) { continue }
        $results.Add([pscustomobject]@{ User = $delegate.ToString(); Type = 'SendOnBehalf' })
    }

    return $results.ToArray()
}

function Export-FolderTreeHtml {
    param([object[]]$Snapshot)

    $mailboxAddress = $script:SelectedMailbox.PrimarySmtpAddress.ToString()

    if (-not $Snapshot) {
        Write-Title 'Export Folder Tree (HTML)'
        Write-Host ('Mailbox: {0}' -f $mailboxAddress)
        Write-Host

        if (-not (Confirm-Action -Message 'Generate the folder tree as an HTML report?')) { return }

        try {
            $Snapshot = @(Get-FolderPermissionSnapshot -Refresh)
        }
        catch {
            Write-Host ('Unable to load mailbox folders: {0}' -f $_.Exception.Message) -ForegroundColor Red
            Pause-Menu
            return
        }
    }

    if (-not (Initialize-ReportFolder)) {
        Pause-Menu
        return
    }

    Write-Host 'Building HTML report...' -ForegroundColor Cyan

    $folderNodes = foreach ($entry in $Snapshot) {
        $folder = $entry.Folder
        $sizeText = ''
        if ($null -ne $folder.FolderSize) {
            # "12.5 MB (13,107,200 bytes)" -> "12.5 MB"
            $sizeText = ($folder.FolderSize.ToString() -replace '\s*\(.*\)\s*$', '').Trim()
        }

        [ordered]@{
            path  = [string]$folder.FolderPath
            name  = [string]$folder.Name
            type  = [string]$folder.FolderType
            items = if ($null -ne $folder.ItemsInFolder) { [int64]$folder.ItemsInFolder } else { $null }
            size  = $sizeText
            perms = @(
                foreach ($permission in @($entry.Permissions)) {
                    [ordered]@{
                        user   = $permission.User.ToString()
                        rights = @($permission.AccessRights | ForEach-Object { $_.ToString() })
                    }
                }
            )
        }
    }

    $mailboxAccess = foreach ($access in @(Get-MailboxLevelAccess)) {
        [ordered]@{ user = $access.User; type = $access.Type }
    }

    $payload = [ordered]@{
        meta          = [ordered]@{
            mailbox     = $mailboxAddress
            displayName = [string]$script:SelectedMailbox.DisplayName
            archive     = [string]$script:SelectedMailbox.ArchiveStatus
            generated   = Get-Date -Format 'MMMM d, yyyy h:mm tt'
            generatedBy = $env:USERNAME
            tool        = 'MailboxFolderPermissionManager.ps1'
        }
        mailboxAccess = @($mailboxAccess)
        folders       = @($folderNodes)
    }

    # Escape "<" so folder or user names can never close the embedded <script> block.
    $json = (ConvertTo-Json -InputObject $payload -Depth 8 -Compress) -replace '<', '\u003c'
    $html = (Get-FolderTreeHtmlTemplate).Replace('__REPORT_DATA__', $json)

    $safeName = ($mailboxAddress.Split('@')[0] -replace '[^a-zA-Z0-9._-]', '_')
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $htmlPath = Join-Path -Path $script:ReportRoot -ChildPath ('{0}_{1}_FolderTree.html' -f $safeName, $timestamp)

    try {
        [System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host
        Write-Host 'HTML report exported successfully.' -ForegroundColor Green
        Write-Host $htmlPath -ForegroundColor White
    }
    catch {
        Write-Host ('HTML export failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
        Pause-Menu
        return
    }

    Write-Host
    $open = Read-MenuChoice -Prompt 'Open the report now?  1. Yes  2. No' -ValidChoices @('1', '2')
    if ($open -eq '1') {
        try {
            Invoke-Item -LiteralPath $htmlPath -ErrorAction Stop
        }
        catch {
            Write-Host ('Unable to open the report: {0}' -f $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

function Get-FolderTreeHtmlTemplate {
    # Self-contained page: no external assets, works offline. __REPORT_DATA__ is replaced with JSON.
    return @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Mailbox folder access</title>
<style>
:root {
  --bg: #F3F5F8;
  --surface: #FFFFFF;
  --surface-2: #F8F9FB;
  --ink: #17202B;
  --ink-2: #485363;
  --ink-3: #7A8594;
  --line: #DFE4EA;
  --line-strong: #C9D0D9;
  --accent: #2547B8;
  --accent-soft: #E7ECFA;
  --focus: #2547B8;
  --warn: #9A5B00;
  --warn-bg: #FFF4E0;
  --t0: #66717F; --t0-bg: #EDEFF2;
  --t1: #1E68A8; --t1-bg: #E4EFF9;
  --t2: #0D7A6E; --t2-bg: #DFF3EF;
  --t3: #9C5A00; --t3-bg: #FAEDD5;
  --t4: #B0223B; --t4-bg: #FBE3E7;
  --radius-s: 6px;
  --radius-m: 10px;
  --font: "Segoe UI Variable Text", "Segoe UI", system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif;
  --font-display: "Segoe UI Variable Display", "Segoe UI", system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif;
  color-scheme: light;
  box-sizing: border-box;
  padding-top: env(safe-area-inset-top, 0px);
  padding-bottom: env(safe-area-inset-bottom, 0px);
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0E1319; --surface: #151C24; --surface-2: #1A222C;
    --ink: #E5EAF0; --ink-2: #A9B3BF; --ink-3: #78838F;
    --line: #253039; --line-strong: #33404B;
    --accent: #8EA6FF; --accent-soft: #1F2A4A; --focus: #8EA6FF;
    --warn: #F2B65A; --warn-bg: #3A2A10;
    --t0: #A3ADB8; --t0-bg: #232C36;
    --t1: #7DB8F0; --t1-bg: #15293D;
    --t2: #5FD1BF; --t2-bg: #12302C;
    --t3: #F0B45E; --t3-bg: #36270F;
    --t4: #FF8C9E; --t4-bg: #3D1820;
    color-scheme: dark;
  }
}
:root[data-theme="dark"] {
  --bg: #0E1319; --surface: #151C24; --surface-2: #1A222C;
  --ink: #E5EAF0; --ink-2: #A9B3BF; --ink-3: #78838F;
  --line: #253039; --line-strong: #33404B;
  --accent: #8EA6FF; --accent-soft: #1F2A4A; --focus: #8EA6FF;
  --warn: #F2B65A; --warn-bg: #3A2A10;
  --t0: #A3ADB8; --t0-bg: #232C36;
  --t1: #7DB8F0; --t1-bg: #15293D;
  --t2: #5FD1BF; --t2-bg: #12302C;
  --t3: #F0B45E; --t3-bg: #36270F;
  --t4: #FF8C9E; --t4-bg: #3D1820;
  color-scheme: dark;
}
*, *::before, *::after { box-sizing: inherit; }
html { scroll-padding-top: env(safe-area-inset-top, 0px); }
body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
  font: 15px/1.5 var(--font);
  -webkit-font-smoothing: antialiased;
}
button, input { font: inherit; color: inherit; }
:focus-visible { outline: 2px solid var(--focus); outline-offset: 2px; border-radius: 4px; }
[hidden] { display: none !important; }
.num { font-variant-numeric: tabular-nums; }

.wrap { max-width: 1320px; margin: 0 auto; padding: 0 clamp(16px, 3vw, 40px); }

/* Masthead */
.masthead { background: var(--surface); border-bottom: 1px solid var(--line); }
.masthead .wrap { padding-top: clamp(24px, 4vw, 44px); padding-bottom: 28px; }
.mast-top { display: flex; flex-wrap: wrap; gap: 24px 48px; justify-content: space-between; align-items: flex-end; }
.who h1 {
  margin: 0;
  font-family: var(--font-display);
  font-size: clamp(28px, 4.2vw, 42px);
  line-height: 1.1;
  font-weight: 600;
  letter-spacing: -0.02em;
}
.who .addr { margin-top: 6px; color: var(--ink-2); font-size: 16px; word-break: break-all; }
.facts { display: grid; grid-template-columns: repeat(3, auto); gap: 4px 28px; margin: 0; }
.facts div { min-width: 0; }
.facts dt { color: var(--ink-3); font-size: 12.5px; }
.facts dd { margin: 0; font-weight: 600; font-size: 14.5px; }
.summary { margin: 22px 0 0; font-size: clamp(16px, 1.6vw, 19px); color: var(--ink-2); max-width: 70ch; }
.summary strong { color: var(--ink); font-weight: 600; }
.summary .warn-text { color: var(--warn); }

.mbx-access { display: flex; flex-wrap: wrap; gap: 12px 32px; margin-top: 22px; padding-top: 18px; border-top: 1px dashed var(--line-strong); }
.mbx-group { display: flex; align-items: baseline; gap: 10px; flex-wrap: wrap; }
.mbx-group h3 { margin: 0; font-size: 13px; font-weight: 600; color: var(--ink-3); }
.mbx-people { display: flex; flex-wrap: wrap; gap: 6px; }
.pill { display: inline-flex; align-items: center; gap: 6px; padding: 2px 10px; border-radius: 999px; background: var(--surface-2); border: 1px solid var(--line); font-size: 13.5px; }
.pill.none { color: var(--ink-3); border-style: dashed; background: transparent; }
.pill.strong { background: var(--t4-bg); border-color: transparent; color: var(--t4); font-weight: 600; }

/* Layout */
.layout { display: grid; grid-template-columns: 300px minmax(0, 1fr); gap: 28px; padding-top: 28px; padding-bottom: 56px; align-items: start; }
@media (max-width: 900px) { .layout { grid-template-columns: minmax(0, 1fr); } }

aside { display: flex; flex-direction: column; gap: 28px; position: sticky; top: calc(16px + env(safe-area-inset-top, 0px)); }
@media (max-width: 900px) { aside { position: static; } .step .lbl span { display: none; } }
.side-h { display: flex; justify-content: space-between; align-items: baseline; margin: 0 0 10px; }
.side-h h2 { margin: 0; font-size: 15px; font-weight: 600; }
.side-h p { margin: 0; font-size: 12.5px; color: var(--ink-3); }

/* Access ladder: each step steps further right as access grows */
.ladder { display: flex; flex-direction: column; gap: 4px; margin: 0; padding: 0; list-style: none; }
.step {
  width: 100%;
  display: grid;
  grid-template-columns: 64px 1fr auto;
  align-items: center;
  gap: 10px;
  padding: 7px 10px 7px 0;
  background: none;
  border: 1px solid transparent;
  border-radius: var(--radius-s);
  text-align: left;
  cursor: pointer;
}
.step:hover { background: var(--surface); border-color: var(--line); }
.step[aria-pressed="true"] { background: var(--surface); border-color: var(--line-strong); box-shadow: inset 3px 0 0 var(--tc); }
.step .rail { height: 22px; width: var(--rail); border-radius: 0 4px 4px 0; background: var(--tc); justify-self: start; }
.step .lbl { display: flex; flex-direction: column; line-height: 1.25; min-width: 0; }
.step .lbl b { font-weight: 600; font-size: 14px; }
.step .lbl span { font-size: 12px; color: var(--ink-3); }
.step .cnt { font-size: 13px; color: var(--ink-2); }
.step.empty .lbl b, .step.empty .cnt { color: var(--ink-3); }
.step.t4 { --tc: var(--t4); --rail: 64px; }
.step.t3 { --tc: var(--t3); --rail: 52px; }
.step.t2 { --tc: var(--t2); --rail: 40px; }
.step.t1 { --tc: var(--t1); --rail: 28px; }
.step.t0 { --tc: var(--t0); --rail: 16px; }

.people { display: flex; flex-direction: column; gap: 2px; margin: 0; padding: 0; list-style: none; }
.person {
  width: 100%;
  display: grid;
  grid-template-columns: 32px 1fr;
  gap: 10px;
  align-items: center;
  padding: 7px 8px;
  border: 1px solid transparent;
  border-radius: var(--radius-s);
  background: none;
  text-align: left;
  cursor: pointer;
}
.person:hover { background: var(--surface); border-color: var(--line); }
.person[aria-pressed="true"] { background: var(--accent-soft); border-color: transparent; }
.avatar { width: 32px; height: 32px; border-radius: 50%; display: grid; place-items: center; font-size: 12px; font-weight: 600; background: var(--tb); color: var(--tc); }
.person .pn { font-weight: 600; font-size: 14px; line-height: 1.25; overflow-wrap: anywhere; }
.person .pd { font-size: 12.5px; color: var(--ink-3); }
.person .pw { font-size: 12.5px; color: var(--warn); display: flex; align-items: center; gap: 4px; }
.side-empty { font-size: 13.5px; color: var(--ink-3); margin: 0; }

/* Tree panel */
.panel { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius-m); min-width: 0; }
.toolbar { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; padding: 14px 16px; border-bottom: 1px solid var(--line); }
.search { flex: 1 1 260px; position: relative; }
.search svg { position: absolute; left: 11px; top: 50%; transform: translateY(-50%); color: var(--ink-3); pointer-events: none; }
.search input {
  width: 100%;
  padding: 8px 12px 8px 36px;
  border: 1px solid var(--line-strong);
  border-radius: var(--radius-s);
  background: var(--surface-2);
}
.search input::placeholder { color: var(--ink-3); }
.search input:focus-visible { outline-offset: 0; background: var(--surface); }
.switch { display: inline-flex; align-items: center; gap: 8px; font-size: 14px; cursor: pointer; user-select: none; }
.switch input { appearance: none; width: 34px; height: 20px; border-radius: 999px; background: var(--line-strong); position: relative; cursor: pointer; margin: 0; transition: background .15s; }
.switch input::after { content: ""; position: absolute; top: 3px; left: 3px; width: 14px; height: 14px; border-radius: 50%; background: #fff; transition: transform .15s; }
.switch input:checked { background: var(--accent); }
.switch input:checked::after { transform: translateX(14px); }
.btns { display: flex; gap: 6px; flex-wrap: wrap; }
.btn { padding: 7px 12px; border: 1px solid var(--line-strong); background: var(--surface); border-radius: var(--radius-s); font-size: 13.5px; cursor: pointer; white-space: nowrap; }
.btn:hover { background: var(--surface-2); }
.btn.link { border-color: transparent; color: var(--accent); padding-left: 6px; padding-right: 6px; }

.status { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; justify-content: space-between; padding: 10px 16px; font-size: 13px; color: var(--ink-3); border-bottom: 1px solid var(--line); background: var(--surface-2); }
.status .filters { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
.fchip { display: inline-flex; align-items: center; gap: 6px; padding: 2px 4px 2px 10px; border-radius: 999px; background: var(--accent-soft); color: var(--ink); font-size: 12.5px; }
.fchip button { border: 0; background: none; cursor: pointer; padding: 0 4px; color: var(--ink-2); font-size: 15px; line-height: 1; }

/* Tree */
.tree, .tree ul { list-style: none; margin: 0; padding: 0; }
.tree { padding: 8px 8px 14px; }
.tree ul { margin-left: 19px; padding-left: 10px; border-left: 1px solid var(--line); }
.row {
  position: relative;
  display: grid;
  grid-template-columns: 22px 20px minmax(0, 1fr);
  column-gap: 8px;
  align-items: center;
  padding: 6px 8px;
  border-radius: var(--radius-s);
}
.row:hover { background: var(--surface-2); }
.row.shared::before { content: ""; position: absolute; left: -11px; top: 8px; bottom: 8px; width: 3px; border-radius: 2px; background: var(--tc); }
.tree > li > .row.shared::before { left: 0; }
.row.context { opacity: .5; }
.row.context .grants { display: none; }
.twisty { width: 22px; height: 22px; display: grid; place-items: center; border: 0; background: none; border-radius: 4px; cursor: pointer; color: var(--ink-3); padding: 0; }
.twisty:hover { background: var(--line); color: var(--ink); }
.twisty svg { transition: transform .15s; }
.twisty[aria-expanded="true"] svg { transform: rotate(90deg); }
.ficon { color: var(--ink-3); display: grid; place-items: center; }
.row.shared .ficon { color: var(--tc); }
.main { display: flex; flex-wrap: wrap; align-items: baseline; gap: 2px 12px; min-width: 0; }
.fname { font-weight: 500; overflow-wrap: anywhere; }
.row.shared .fname { font-weight: 600; }
.fmeta { font-size: 12.5px; color: var(--ink-3); white-space: nowrap; }
.grants { grid-column: 3; display: flex; flex-wrap: wrap; gap: 6px; margin-top: 5px; }
.grant {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 2px 9px 2px 8px;
  border-radius: 5px;
  background: var(--tb);
  color: var(--ink);
  font-size: 13px;
  line-height: 1.5;
  border-left: 3px solid var(--tc);
  transition: opacity .15s;
}
.grant b { color: var(--tc); font-weight: 600; }
.grant .w { color: var(--warn); display: inline-flex; }
.grant.dim { opacity: .35; }
.grant.focus { box-shadow: 0 0 0 1.5px var(--tc); }
.t0 { --tc: var(--t0); --tb: var(--t0-bg); }
.t1 { --tc: var(--t1); --tb: var(--t1-bg); }
.t2 { --tc: var(--t2); --tb: var(--t2-bg); }
.t3 { --tc: var(--t3); --tb: var(--t3-bg); }
.t4 { --tc: var(--t4); --tb: var(--t4-bg); }
.hint { grid-column: 3; margin-top: 5px; font-size: 12.5px; color: var(--warn); background: var(--warn-bg); padding: 4px 10px; border-radius: 5px; justify-self: start; }

.empty-state { padding: 48px 24px; text-align: center; color: var(--ink-2); }
.empty-state p { margin: 0 0 12px; }

footer { color: var(--ink-3); font-size: 12.5px; padding-bottom: 40px; }
footer p { margin: 0 0 4px; max-width: 90ch; }

@media (max-width: 600px) {
  .facts { grid-template-columns: repeat(2, auto); }
  .fmeta { white-space: normal; }
  .tree ul { margin-left: 10px; padding-left: 6px; }
}
@media (prefers-reduced-motion: reduce) {
  * { transition: none !important; }
}
@media print {
  body { background: #fff; font-size: 12px; }
  aside, .toolbar, .twisty, .status .btn { display: none !important; }
  .layout { display: block; padding-top: 12px; }
  .panel { border: 0; }
  .masthead { border: 0; }
  .row { break-inside: avoid; }
}
</style>
</head>
<body>
<header class="masthead">
  <div class="wrap">
    <div class="mast-top">
      <div class="who">
        <h1 id="mbx-name">Mailbox</h1>
        <div class="addr" id="mbx-addr"></div>
      </div>
      <dl class="facts" id="facts"></dl>
    </div>
    <p class="summary" id="summary"></p>
    <div class="mbx-access" id="mbx-access"></div>
  </div>
</header>

<div class="wrap layout">
  <aside aria-label="Filters">
    <section>
      <div class="side-h"><h2>Access level</h2><p>Grants</p></div>
      <ul class="ladder" id="ladder"></ul>
    </section>
    <section>
      <div class="side-h"><h2>People</h2><p>Folders</p></div>
      <ul class="people" id="people"></ul>
    </section>
  </aside>

  <main class="panel">
    <div class="toolbar">
      <label class="search">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><circle cx="7" cy="7" r="5"/><path d="m11 11 3.5 3.5" stroke-linecap="round"/></svg>
        <input id="q" type="search" placeholder="Filter by folder or person" autocomplete="off" aria-label="Filter by folder or person">
      </label>
      <label class="switch"><input id="shared-only" type="checkbox"> Shared folders only</label>
      <div class="btns">
        <button class="btn" id="expand">Expand all</button>
        <button class="btn" id="collapse">Collapse all</button>
        <button class="btn" id="theme">Theme: Auto</button>
        <button class="btn" id="print">Print</button>
      </div>
    </div>
    <div class="status">
      <span id="count" class="num"></span>
      <div class="filters" id="active-filters"></div>
    </div>
    <ul class="tree" id="tree" role="tree" aria-label="Mailbox folders"></ul>
    <div class="empty-state" id="empty" hidden>
      <p>No folders match these filters.</p>
      <button class="btn" id="clear-empty">Clear filters</button>
    </div>
  </main>
</div>

<footer class="wrap">
  <p id="foot-gen"></p>
  <p>Shows explicit folder permissions. Default and Anonymous entries are excluded, so a folder can still be visible through the Default permission or a group membership.</p>
</footer>

<script id="report-data" type="application/json">__REPORT_DATA__</script>
<script>
(function () {
  'use strict';

  var data = JSON.parse(document.getElementById('report-data').textContent);
  var meta = data.meta || {};
  var folders = data.folders || [];
  var mailboxAccess = data.mailboxAccess || [];

  // ---------- Access model ----------
  var TIERS = [
    { id: 0, name: 'Visible only',  roles: 'FolderVisible' },
    { id: 1, name: 'Read',          roles: 'Reviewer, LimitedDetails, AvailabilityOnly' },
    { id: 2, name: 'Create items',  roles: 'Contributor, NonEditingAuthor, Author, PublishingAuthor' },
    { id: 3, name: 'Edit all',      roles: 'Editor, PublishingEditor' },
    { id: 4, name: 'Full control',  roles: 'Owner' }
  ];
  var ROLE_TIER = {
    Owner: 4, PublishingEditor: 3, Editor: 3,
    PublishingAuthor: 2, Author: 2, NonEditingAuthor: 2, Contributor: 2,
    Reviewer: 1, LimitedDetails: 1, AvailabilityOnly: 1,
    FolderVisible: 0
  };
  var ROLE_RANK = {
    Owner: 10, PublishingEditor: 9, Editor: 8, PublishingAuthor: 7, Author: 6,
    NonEditingAuthor: 5, Contributor: 4, Reviewer: 3, LimitedDetails: 2, AvailabilityOnly: 1, FolderVisible: 0
  };

  function classify(rights) {
    rights = (rights || []).map(String);
    var best = null;
    rights.forEach(function (r) {
      if (ROLE_RANK.hasOwnProperty(r) && (best === null || ROLE_RANK[r] > ROLE_RANK[best])) { best = r; }
    });
    if (best && rights.length === 1) { return { label: best, tier: ROLE_TIER[best], rank: ROLE_RANK[best] }; }
    if (best && !rights.some(function (r) { return /Items|Folder(Owner|Contact)|CreateSubfolders/.test(r) && r !== 'FolderVisible'; })) {
      return { label: best, tier: ROLE_TIER[best], rank: ROLE_RANK[best] };
    }
    // Granular rights combination
    var t = 0;
    if (rights.indexOf('FolderOwner') > -1) { t = 4; }
    else if (rights.indexOf('EditAllItems') > -1 || rights.indexOf('DeleteAllItems') > -1) { t = 3; }
    else if (rights.indexOf('CreateItems') > -1 || rights.indexOf('EditOwnedItems') > -1) { t = 2; }
    else if (rights.indexOf('ReadItems') > -1) { t = 1; }
    return { label: 'Custom', tier: t, rank: t * 2 + 0.5, detail: rights.join(', ') };
  }

  // ---------- Build tree ----------
  var TYPE_ORDER = ['Root', 'Inbox', 'Drafts', 'SentItems', 'DeletedItems', 'Archive', 'JunkEmail', 'Outbox',
                    'Calendar', 'Contacts', 'Tasks', 'Notes', 'Journal', 'ConversationHistory'];
  var byPath = {};
  var nodes = folders.map(function (f) {
    var path = String(f.path || '/');
    var segs = path === '/' ? [] : path.replace(/^\/+/, '').split('/');
    var n = {
      path: path,
      name: path === '/' ? 'Mailbox root' : String(f.name || segs[segs.length - 1] || path).replace(/\uF8FF/g, '/'),
      type: f.type || '',
      items: f.items,
      size: f.size || '',
      perms: (f.perms || []).map(function (p) {
        var c = classify(p.rights);
        return { user: String(p.user), rights: p.rights || [], label: c.label, tier: c.tier, rank: c.rank, detail: c.detail || '', hiddenBy: null };
      }).sort(function (a, b) { return b.rank - a.rank || a.user.localeCompare(b.user); }),
      children: [],
      parent: null
    };
    n.maxTier = n.perms.reduce(function (m, p) { return Math.max(m, p.tier); }, -1);
    n.search = (n.name + ' ' + path.replace(/\uF8FF/g, '/') + ' ' + n.perms.map(function (p) { return p.user; }).join(' ')).toLowerCase();
    byPath[path] = n;
    return n;
  });

  var roots = [];
  nodes.forEach(function (n) {
    if (n.path === '/') { roots.push(n); return; }
    var p = n.path;
    var parent = null;
    while (p.lastIndexOf('/') > 0) {
      p = p.substring(0, p.lastIndexOf('/'));
      if (byPath[p]) { parent = byPath[p]; break; }
    }
    if (!parent && byPath['/'] && n.path !== '/') { parent = byPath['/']; }
    if (parent) { n.parent = parent; parent.children.push(n); } else { roots.push(n); }
  });

  function sortKey(n) { var i = TYPE_ORDER.indexOf(n.type); return i === -1 ? 99 : i; }
  function sortNodes(list) {
    list.sort(function (a, b) { return sortKey(a) - sortKey(b) || a.name.localeCompare(b.name, undefined, { sensitivity: 'base', numeric: true }); });
    list.forEach(function (n) { sortNodes(n.children); });
  }
  sortNodes(roots);

  // Flag grants that sit under a parent the person has no entry on
  nodes.forEach(function (n) {
    n.perms.forEach(function (p) {
      if (p.tier === 0) { return; }
      var a = n.parent, missing = null;
      while (a) {
        if (!a.perms.some(function (q) { return q.user === p.user; })) { missing = a; }
        a = a.parent;
      }
      p.hiddenBy = missing;
    });
  });

  // People
  var people = {};
  nodes.forEach(function (n) {
    n.perms.forEach(function (p) {
      var x = people[p.user] || (people[p.user] = { user: p.user, folders: 0, best: p, issues: 0 });
      x.folders++;
      if (p.rank > x.best.rank) { x.best = p; }
      if (p.hiddenBy) { x.issues++; }
    });
  });
  var peopleList = Object.keys(people).map(function (k) { return people[k]; })
    .sort(function (a, b) { return b.best.rank - a.best.rank || a.user.localeCompare(b.user); });

  // ---------- Helpers ----------
  function el(tag, attrs, kids) {
    var e = document.createElement(tag);
    if (attrs) { Object.keys(attrs).forEach(function (k) {
      if (k === 'class') { e.className = attrs[k]; }
      else if (k === 'text') { e.textContent = attrs[k]; }
      else if (k === 'html') { e.innerHTML = attrs[k]; }
      else { e.setAttribute(k, attrs[k]); }
    }); }
    (kids || []).forEach(function (c) { if (c) { e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c); } });
    return e;
  }
  function fmtInt(v) { return (v === null || v === undefined || v === '') ? '' : Number(v).toLocaleString(); }
  function plural(n, one, many) { return n + ' ' + (n === 1 ? one : many); }
  function initials(name) {
    var clean = String(name).replace(/@.*$/, '').replace(/[^A-Za-z0-9 ._-]/g, ' ').trim();
    var parts = clean.split(/[ ._-]+/).filter(Boolean);
    if (!parts.length) { return '?'; }
    return (parts[0][0] + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
  }

  var ICONS = {
    chev: '<svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 2.5 8 6l-3.5 3.5"/></svg>',
    folder: '<path d="M2.5 5.5a1 1 0 0 1 1-1h3.6l1.5 1.6h5.9a1 1 0 0 1 1 1v6.4a1 1 0 0 1-1 1H3.5a1 1 0 0 1-1-1z"/>',
    Inbox: '<path d="M2.5 10.5V4.5a1 1 0 0 1 1-1h11a1 1 0 0 1 1 1v6"/><path d="M2.5 10.5h4l1 2h3l1-2h4v3a1 1 0 0 1-1 1h-11a1 1 0 0 1-1-1z"/>',
    Calendar: '<rect x="2.5" y="3.5" width="13" height="11.5" rx="1.2"/><path d="M2.5 7h13M6 2v3M12 2v3"/>',
    Contacts: '<circle cx="9" cy="6.5" r="2.7"/><path d="M3.8 15c.7-2.6 2.8-4 5.2-4s4.5 1.4 5.2 4"/>',
    Tasks: '<rect x="2.5" y="2.5" width="13" height="13" rx="1.5"/><path d="m5.5 9 2.3 2.3 4.7-4.8"/>',
    Notes: '<path d="M3.5 2.5h8l3 3v9a1 1 0 0 1-1 1h-10a1 1 0 0 1-1-1v-11a1 1 0 0 1 1-1z"/><path d="M6 8h6M6 11h4"/>',
    SentItems: '<path d="M15.5 2.5 2.5 8l5 2 2 5z"/><path d="m15.5 2.5-8 7.5"/>',
    DeletedItems: '<path d="M3 5h12M7 5V3.5h4V5M4.5 5l.8 9.6a1 1 0 0 0 1 .9h5.4a1 1 0 0 0 1-.9L13.5 5"/>',
    Drafts: '<path d="m11.8 3.2 3 3-8.3 8.3H3.5v-3z"/>',
    JunkEmail: '<circle cx="9" cy="9" r="6.5"/><path d="m4.4 4.4 9.2 9.2"/>',
    Archive: '<rect x="2" y="3" width="14" height="3.5" rx=".8"/><path d="M3.2 6.5v7.5a1 1 0 0 0 1 1h9.6a1 1 0 0 0 1-1V6.5M7.2 9.5h3.6"/>',
    Outbox: '<path d="M2.5 10.5V4.5a1 1 0 0 1 1-1h11a1 1 0 0 1 1 1v6"/><path d="M2.5 10.5h4l1 2h3l1-2h4v3a1 1 0 0 1-1 1h-11a1 1 0 0 1-1-1zM9 9V5.5M7.3 7 9 5.3 10.7 7"/>',
    Root: '<path d="M2.5 8 9 3l6.5 5v6.5a1 1 0 0 1-1 1h-11a1 1 0 0 1-1-1z"/>',
    warn: '<svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2 1.5 13.5h13z"/><path d="M8 6.5v3.2M8 11.6v.1"/></svg>'
  };
  function folderIcon(type, isRoot) {
    var body = ICONS[isRoot ? 'Root' : type] || ICONS.folder;
    return '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + body + '</svg>';
  }

  // ---------- Masthead ----------
  document.title = (meta.displayName || meta.mailbox || 'Mailbox') + ' folder access';
  document.getElementById('mbx-name').textContent = meta.displayName || meta.mailbox || 'Mailbox';
  document.getElementById('mbx-addr').textContent = meta.mailbox || '';

  var facts = document.getElementById('facts');
  [['Folders', fmtInt(nodes.length)], ['Archive', meta.archive || 'Unknown'], ['Generated', meta.generated || '']].forEach(function (f) {
    facts.appendChild(el('div', null, [el('dt', { text: f[0] }), el('dd', { text: f[1], class: 'num' })]));
  });

  var sharedCount = nodes.filter(function (n) { return n.perms.length; }).length;
  var issueTotal = peopleList.reduce(function (s, p) { return s + p.issues; }, 0);
  var summary = document.getElementById('summary');
  if (!sharedCount) {
    summary.textContent = 'No folders in this mailbox are shared through explicit folder permissions.';
  } else {
    summary.appendChild(el('strong', { text: plural(sharedCount, 'folder', 'folders') }));
    summary.appendChild(document.createTextNode(' of ' + fmtInt(nodes.length) + ' ' + (sharedCount === 1 ? 'is' : 'are') + ' shared with '));
    summary.appendChild(el('strong', { text: plural(peopleList.length, 'person', 'people') }));
    summary.appendChild(document.createTextNode('.'));
    if (issueTotal) {
      summary.appendChild(document.createTextNode(' '));
      summary.appendChild(el('span', { class: 'warn-text', text: plural(issueTotal, 'grant sits', 'grants sit') + ' under a parent folder the person has no access to, so ' + (issueTotal === 1 ? 'it' : 'they') + ' may not appear in Outlook.' }));
    }
  }

  var accessBox = document.getElementById('mbx-access');
  [['FullAccess', 'Full access'], ['SendAs', 'Send as'], ['SendOnBehalf', 'Send on behalf']].forEach(function (g) {
    var who = mailboxAccess.filter(function (a) { return a.type === g[0]; });
    var list = el('div', { class: 'mbx-people' });
    if (!who.length) { list.appendChild(el('span', { class: 'pill none', text: 'None' })); }
    who.forEach(function (a) { list.appendChild(el('span', { class: 'pill' + (g[0] === 'FullAccess' ? ' strong' : ''), text: a.user })); });
    accessBox.appendChild(el('div', { class: 'mbx-group' }, [el('h3', { text: g[1] }), list]));
  });
  document.getElementById('foot-gen').textContent = 'Generated ' + (meta.generated || '') + (meta.generatedBy ? ' by ' + meta.generatedBy : '') + (meta.tool ? ' with ' + meta.tool : '') + '.';

  // ---------- State ----------
  var state = { q: '', sharedOnly: false, minTier: null, person: null };
  var expanded = {};
  nodes.forEach(function (n) { expanded[n.path] = true; });
  var savedExpanded = null;

  function filtersActive() { return !!(state.q || state.sharedOnly || state.minTier !== null || state.person); }

  // ---------- Sidebar ----------
  var ladder = document.getElementById('ladder');
  var tierCounts = [0, 0, 0, 0, 0];
  nodes.forEach(function (n) { n.perms.forEach(function (p) { tierCounts[p.tier]++; }); });
  var stepBtns = [];
  TIERS.slice().reverse().forEach(function (t) {
    var b = el('button', { class: 'step t' + t.id + (tierCounts[t.id] ? '' : ' empty'), 'aria-pressed': 'false', title: 'Show folders with ' + t.name.toLowerCase() + ' or higher' }, [
      el('span', { class: 'rail', 'aria-hidden': 'true' }),
      el('span', { class: 'lbl' }, [el('b', { text: t.name }), el('span', { text: t.roles })]),
      el('span', { class: 'cnt num', text: String(tierCounts[t.id]) })
    ]);
    b.addEventListener('click', function () { state.minTier = state.minTier === t.id ? null : t.id; update(); });
    stepBtns.push({ b: b, id: t.id });
    ladder.appendChild(el('li', null, [b]));
  });

  var peopleUl = document.getElementById('people');
  var personBtns = [];
  if (!peopleList.length) { peopleUl.appendChild(el('li', null, [el('p', { class: 'side-empty', text: 'Nobody has explicit folder permissions.' })])); }
  peopleList.forEach(function (p) {
    var kids = [
      el('span', { class: 'pn', text: p.user }),
      el('span', { class: 'pd', text: plural(p.folders, 'folder', 'folders') + ', up to ' + p.best.label })
    ];
    if (p.issues) {
      var w = el('span', { class: 'pw' });
      w.innerHTML = ICONS.warn;
      w.appendChild(document.createTextNode(plural(p.issues, 'folder', 'folders') + ' may be hidden'));
      kids.push(w);
    }
    var b = el('button', { class: 'person', 'aria-pressed': 'false' }, [
      el('span', { class: 'avatar t' + p.best.tier, text: initials(p.user), 'aria-hidden': 'true' }),
      el('span', { style: 'display:flex;flex-direction:column;min-width:0' }, kids)
    ]);
    b.addEventListener('click', function () { state.person = state.person === p.user ? null : p.user; update(); });
    personBtns.push({ b: b, user: p.user });
    peopleUl.appendChild(el('li', null, [b]));
  });

  // ---------- Tree DOM ----------
  var treeUl = document.getElementById('tree');
  function build(n, parentUl, depth) {
    var li = el('li', { role: 'treeitem', 'aria-level': String(depth + 1) });
    var row = el('div', { class: 'row' + (n.perms.length ? ' shared t' + n.maxTier : '') });
    var twisty;
    if (n.children.length) {
      twisty = el('button', { class: 'twisty', 'aria-expanded': 'true', 'aria-label': 'Toggle ' + n.name, html: ICONS.chev });
      twisty.addEventListener('click', function () { expanded[n.path] = !expanded[n.path]; render(); });
    } else {
      twisty = el('span', { 'aria-hidden': 'true' });
    }
    var metaBits = [];
    if (n.items !== null && n.items !== undefined && n.items !== '') { metaBits.push(plural(Number(n.items), 'item', 'items').replace(/^\d+/, fmtInt(n.items))); }
    if (n.size) { metaBits.push(n.size); }
    row.appendChild(twisty);
    row.appendChild(el('span', { class: 'ficon', html: folderIcon(n.type, n.path === '/') }));
    row.appendChild(el('div', { class: 'main' }, [
      el('span', { class: 'fname', text: n.name }),
      metaBits.length ? el('span', { class: 'fmeta num', text: metaBits.join(', ') }) : null
    ]));
    n.chipEls = [];
    if (n.perms.length) {
      var g = el('div', { class: 'grants' });
      n.perms.forEach(function (p) {
        var title = p.user + ': ' + (p.detail || p.label);
        if (p.hiddenBy) { title += '\nNo permission on parent folder "' + p.hiddenBy.name + '", so this folder may not appear in Outlook.'; }
        var chip = el('span', { class: 'grant t' + p.tier, title: title }, [document.createTextNode(p.user + ' '), el('b', { text: p.label })]);
        if (p.hiddenBy) { var w = el('span', { class: 'w', html: ICONS.warn }); chip.appendChild(w); }
        chip._user = p.user;
        n.chipEls.push(chip);
        g.appendChild(chip);
      });
      row.appendChild(g);
    }
    n.hintEl = el('div', { class: 'hint', hidden: '' });
    row.appendChild(n.hintEl);
    li.appendChild(row);
    n.li = li; n.row = row; n.twisty = n.children.length ? twisty : null;
    if (n.children.length) {
      var ul = el('ul', { role: 'group' });
      n.children.forEach(function (c) { build(c, ul, depth + 1); });
      li.appendChild(ul);
      n.ul = ul;
    }
    parentUl.appendChild(li);
  }
  roots.forEach(function (r) { build(r, treeUl, 0); });

  // ---------- Filtering ----------
  function matches(n) {
    if (state.q && n.search.indexOf(state.q) === -1) { return false; }
    if (state.sharedOnly && !n.perms.length) { return false; }
    var perms = state.person ? n.perms.filter(function (p) { return p.user === state.person; }) : n.perms;
    if (state.person && !perms.length) { return false; }
    if (state.minTier !== null && !perms.some(function (p) { return p.tier >= state.minTier; })) { return false; }
    return true;
  }
  function mark(n) {
    n.matched = matches(n);
    var sub = false;
    n.children.forEach(function (c) { if (mark(c)) { sub = true; } });
    n.subMatch = sub;
    return n.matched || sub;
  }

  var visibleCount = 0;
  function render() {
    var active = filtersActive();
    visibleCount = 0;
    function walk(n) {
      var show = active ? (n.matched || n.subMatch) : true;
      n.li.hidden = !show;
      if (!show) { return; }
      visibleCount++;
      n.row.classList.toggle('context', active && !n.matched);
      n.chipEls.forEach(function (c) {
        c.classList.toggle('dim', !!state.person && c._user !== state.person);
        c.classList.toggle('focus', !!state.person && c._user === state.person);
      });
      var hidden = null;
      if (state.person) {
        n.perms.forEach(function (p) { if (p.user === state.person && p.hiddenBy) { hidden = p.hiddenBy; } });
      }
      if (hidden) {
        n.hintEl.textContent = state.person + ' has no permission on "' + hidden.name + '", so this folder may not appear in their Outlook. Add FolderVisible to the parent folders.';
        n.hintEl.hidden = false;
      } else { n.hintEl.hidden = true; }
      if (n.ul) {
        var open = !!expanded[n.path];
        n.ul.hidden = !open;
        n.twisty.setAttribute('aria-expanded', String(open));
        n.li.setAttribute('aria-expanded', String(open));
        n.children.forEach(walk);
      }
    }
    roots.forEach(walk);

    document.getElementById('empty').hidden = !(active && visibleCount === 0);
    treeUl.hidden = active && visibleCount === 0;
    var shownMatched = active ? nodes.filter(function (n) { return n.matched; }).length : nodes.length;
    document.getElementById('count').textContent = active
      ? plural(shownMatched, 'folder matches', 'folders match') + ' of ' + fmtInt(nodes.length)
      : 'Showing all ' + plural(nodes.length, 'folder', 'folders');
  }

  function update() {
    var active = filtersActive();
    if (active) {
      if (!savedExpanded) { savedExpanded = Object.assign({}, expanded); }
      roots.forEach(mark);
      nodes.forEach(function (n) { expanded[n.path] = n.subMatch; });
    } else if (savedExpanded) {
      expanded = savedExpanded;
      savedExpanded = null;
    }
    stepBtns.forEach(function (s) { s.b.setAttribute('aria-pressed', String(state.minTier === s.id)); });
    personBtns.forEach(function (s) { s.b.setAttribute('aria-pressed', String(state.person === s.user)); });
    renderFilterChips();
    render();
  }

  function renderFilterChips() {
    var box = document.getElementById('active-filters');
    box.innerHTML = '';
    function chip(label, clear) {
      var b = el('button', { 'aria-label': 'Remove filter ' + label, text: '\u00D7' });
      b.addEventListener('click', clear);
      box.appendChild(el('span', { class: 'fchip' }, [document.createTextNode(label), b]));
    }
    if (state.person) { chip(state.person, function () { state.person = null; update(); }); }
    if (state.minTier !== null) { chip(TIERS[state.minTier].name + ' or higher', function () { state.minTier = null; update(); }); }
    if (state.sharedOnly) { chip('Shared only', function () { state.sharedOnly = false; sharedBox.checked = false; update(); }); }
    if (state.q) { chip('\u201C' + qInput.value.trim() + '\u201D', function () { state.q = ''; qInput.value = ''; update(); }); }
    if (filtersActive()) {
      var c = el('button', { class: 'btn link', text: 'Clear filters' });
      c.addEventListener('click', clearAll);
      box.appendChild(c);
    }
  }

  function clearAll() {
    state = { q: '', sharedOnly: false, minTier: null, person: null };
    qInput.value = ''; sharedBox.checked = false;
    update();
  }

  // ---------- Controls ----------
  var qInput = document.getElementById('q');
  var sharedBox = document.getElementById('shared-only');
  var qTimer;
  qInput.addEventListener('input', function () {
    clearTimeout(qTimer);
    qTimer = setTimeout(function () { state.q = qInput.value.trim().toLowerCase(); update(); }, 120);
  });
  qInput.addEventListener('keydown', function (e) { if (e.key === 'Escape') { qInput.value = ''; state.q = ''; update(); } });
  sharedBox.addEventListener('change', function () { state.sharedOnly = sharedBox.checked; update(); });
  document.getElementById('expand').addEventListener('click', function () { nodes.forEach(function (n) { if (!filtersActive() || n.subMatch) { expanded[n.path] = true; } }); render(); });
  document.getElementById('collapse').addEventListener('click', function () { nodes.forEach(function (n) { expanded[n.path] = false; }); render(); });
  document.getElementById('clear-empty').addEventListener('click', clearAll);
  document.getElementById('print').addEventListener('click', function () { window.print(); });

  var themeBtn = document.getElementById('theme');
  var THEMES = ['auto', 'light', 'dark'];
  var theme = 'auto';
  try { theme = localStorage.getItem('mbx-report-theme') || 'auto'; } catch (e) { theme = 'auto'; }
  function applyTheme() {
    if (theme === 'auto') { document.documentElement.removeAttribute('data-theme'); }
    else { document.documentElement.setAttribute('data-theme', theme); }
    themeBtn.textContent = 'Theme: ' + theme.charAt(0).toUpperCase() + theme.slice(1);
  }
  themeBtn.addEventListener('click', function () {
    theme = THEMES[(THEMES.indexOf(theme) + 1) % THEMES.length];
    try { localStorage.setItem('mbx-report-theme', theme); } catch (e) { /* storage unavailable */ }
    applyTheme();
  });
  applyTheme();

  update();
})();
</script>
</body>
</html>
'@
}

function Find-TargetMailbox {
    Write-Title 'Find Mailbox'

    while ($true) {
        $email = (Read-Host 'Enter the mailbox email address, or B to go back').Trim()
        if ($email -match '^(?i)b$') { return $false }

        if (-not (Test-EmailAddress -Address $email)) {
            Write-Host 'Enter a valid email address.' -ForegroundColor Yellow
            continue
        }

        try {
            Write-Host 'Validating mailbox...' -ForegroundColor Cyan
            $mailbox = Get-Mailbox -Identity $email -ErrorAction Stop
            $script:SelectedMailbox = $mailbox
            $script:FolderCache = @()
            return $true
        }
        catch {
            Write-Host ('Mailbox not found or unavailable: {0}' -f $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

function Show-MailboxMenu {
    while ($true) {
        Write-Title 'Mailbox'
        Write-Host ('Name:      {0}' -f $script:SelectedMailbox.DisplayName)
        Write-Host ('Mailbox:   {0}' -f $script:SelectedMailbox.PrimarySmtpAddress)
        Write-Host ('Archive:   {0}' -f $script:SelectedMailbox.ArchiveStatus)
        Write-Host
        Write-Host '1. Folder Tree'
        Write-Host '2. Modify Permissions'
        Write-Host '3. Export Detailed Permission Report (CSV)'
        Write-Host '4. Export Folder Tree (HTML)'
        Write-Host '5. Back'
        Write-Host

        $choice = Read-MenuChoice -Prompt 'Select option' -ValidChoices @('1', '2', '3', '4', '5')
        switch ($choice) {
            '1' { Show-FolderTree }
            '2' { Start-ModifyPermissions }
            '3' { Export-DetailedPermissionReport }
            '4' {
                Export-FolderTreeHtml
                Pause-Menu
            }
            '5' {
                $script:SelectedMailbox = $null
                $script:FolderCache = @()
                return
            }
        }
    }
}

function Start-MailboxFolderPermissionManager {
    Connect-ExchangeOnlineSession

    try {
        while ($true) {
            Write-Title 'Mailbox Folder Permission Manager'
            Write-Host '1. Find Mailbox'
            Write-Host '2. Exit'
            Write-Host

            $choice = Read-MenuChoice -Prompt 'Select option' -ValidChoices @('1', '2')
            switch ($choice) {
                '1' {
                    if (Find-TargetMailbox) {
                        Show-MailboxMenu
                    }
                }
                '2' { return }
            }
        }
    }
    finally {
        Write-Host 'Closing Mailbox Folder Permission Manager.' -ForegroundColor Cyan
    }
}

Start-MailboxFolderPermissionManager