<#
.SYNOPSIS
Add, update, or remove mailbox folder permissions on a folder and (optionally) its subfolders.

.DESCRIPTION
Interactive, menu-driven tool for managing Exchange Online mailbox folder permissions.

  - Choose an action: grant/update a permission role, or remove a user's permission.
  - Choose any built-in permission role (Author, Contributor, Editor, NonEditingAuthor,
    Owner, PublishingAuthor, PublishingEditor, Reviewer, and the calendar-only roles
    AvailabilityOnly and LimitedDetails).
  - Choose a scope: the folder only, the folder plus its direct subfolders, or the
    folder plus every subfolder beneath it.
  - Search for and pick the folder from a numbered list instead of typing exact paths.
  - Review a summary before any change is made, watch progress, and get a results
    table at the end (optionally exported to CSV).

Every value can also be passed as a parameter so the script can run unattended
(add -Force to skip the confirmation prompt). -WhatIf is supported.

Folder paths returned by folder statistics use forward slashes; they are converted
to backslashes for the permission cmdlets. Folder names that contain a "/" are
handled as well.

Author: j0shbl0ck (https://github.com/j0shbl0ck)
Version: 2.0.0
Date: 10.29.26
Type: Public

.PARAMETER Mailbox
The mailbox to modify (e.g., user@contoso.com).

.PARAMETER TargetUser
The user to grant or remove permissions for (e.g., user2@contoso.com).
"Default" and "Anonymous" are also accepted.

.PARAMETER RootFolder
The folder path to start from, using forward slashes (e.g., /Inbox/My Archive).
If omitted you can search for and pick the folder interactively.

.PARAMETER Action
Add    - Grant the selected role, or update the user's existing role.
Remove - Remove the user's permission (Default/Anonymous are reset to None).

.PARAMETER AccessRight
The permission role to grant when Action is Add.

.PARAMETER Scope
FolderOnly                - Only the selected folder.
FolderAndDirectSubfolders - The selected folder and the subfolders directly beneath it.
FolderAndAllSubfolders    - The selected folder and every subfolder beneath it.

.PARAMETER ExportPath
Optional path to a CSV file to save the results to.

.PARAMETER Force
Skip the confirmation prompt.

.EXAMPLE
.\set-folder-permissions.ps1
Runs fully interactive.

.EXAMPLE
.\set-folder-permissions.ps1 -Mailbox shared@contoso.com -TargetUser jane@contoso.com `
    -RootFolder "/Inbox/Projects" -Action Add -AccessRight Editor -Scope FolderAndAllSubfolders

.EXAMPLE
.\set-folder-permissions.ps1 -Mailbox shared@contoso.com -TargetUser jane@contoso.com `
    -RootFolder "/Inbox/Projects" -Action Remove -Scope FolderOnly -Force
#>

Clear-Host

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Mailbox,
    [string]$TargetUser,
    [string]$RootFolder,

    [ValidateSet('Add', 'Remove')]
    [string]$Action,

    [ValidateSet('Author', 'Contributor', 'Editor', 'NonEditingAuthor', 'Owner',
                 'PublishingAuthor', 'PublishingEditor', 'Reviewer',
                 'AvailabilityOnly', 'LimitedDetails')]
    [string]$AccessRight,

    [ValidateSet('FolderOnly', 'FolderAndDirectSubfolders', 'FolderAndAllSubfolders')]
    [string]$Scope,

    [string]$ExportPath,

    [switch]$Force
)

#region ---------- Reference data ----------

$Roles = @(
    [pscustomobject]@{ Name = 'Author';           CalendarOnly = $false; Rights = 'CreateItems, DeleteOwnedItems, EditOwnedItems, FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'Contributor';      CalendarOnly = $false; Rights = 'CreateItems, FolderVisible' }
    [pscustomobject]@{ Name = 'Editor';           CalendarOnly = $false; Rights = 'CreateItems, DeleteAllItems, DeleteOwnedItems, EditAllItems, EditOwnedItems, FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'NonEditingAuthor'; CalendarOnly = $false; Rights = 'CreateItems, DeleteOwnedItems, FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'Owner';            CalendarOnly = $false; Rights = 'CreateItems, CreateSubfolders, DeleteAllItems, DeleteOwnedItems, EditAllItems, EditOwnedItems, FolderContact, FolderOwner, FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'PublishingAuthor'; CalendarOnly = $false; Rights = 'CreateItems, CreateSubfolders, DeleteOwnedItems, EditOwnedItems, FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'PublishingEditor'; CalendarOnly = $false; Rights = 'CreateItems, CreateSubfolders, DeleteAllItems, DeleteOwnedItems, EditAllItems, EditOwnedItems, FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'Reviewer';         CalendarOnly = $false; Rights = 'FolderVisible, ReadItems' }
    [pscustomobject]@{ Name = 'AvailabilityOnly'; CalendarOnly = $true;  Rights = 'View only availability data (calendar folders only)' }
    [pscustomobject]@{ Name = 'LimitedDetails';   CalendarOnly = $true;  Rights = 'View availability data with subject and location (calendar folders only)' }
)

$Scopes = @(
    [pscustomobject]@{ Name = 'FolderOnly';                Label = 'This folder only' }
    [pscustomobject]@{ Name = 'FolderAndDirectSubfolders'; Label = 'This folder + direct subfolders (one level down)' }
    [pscustomobject]@{ Name = 'FolderAndAllSubfolders';    Label = 'This folder + all subfolders (entire tree)' }
)

# Principals that always exist on a folder and cannot be removed, only reset to None
$BuiltInPrincipals = @('Default', 'Anonymous')

#endregion

#region ---------- UI helpers ----------

function Write-Banner {
    param([string]$Title)
    $line = '=' * 64
    Write-Host ''
    Write-Host $line -ForegroundColor DarkCyan
    Write-Host ("  " + $Title) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor DarkCyan
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host ("-- " + $Title + " " + ('-' * [Math]::Max(0, 58 - $Title.Length))) -ForegroundColor DarkCyan
}

function Write-Info    { param([string]$Message) Write-Host "  [i] $Message" -ForegroundColor Gray }
function Write-Ok      { param([string]$Message) Write-Host "  [+] $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Message) Write-Host "  [x] $Message" -ForegroundColor Red }

function Read-Input {
    param(
        [string]$Prompt,
        [switch]$AllowEmpty
    )
    while ($true) {
        Write-Host "  $Prompt" -ForegroundColor White -NoNewline
        $value = Read-Host ' '
        if ($AllowEmpty -or -not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
        Write-Warn 'A value is required.'
    }
}

function Read-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $false
    )
    $hint = if ($Default) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = Read-Input -Prompt "$Prompt $hint" -AllowEmpty
        if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
        switch -Regex ($answer) {
            '^(y|yes)$' { return $true }
            '^(n|no)$'  { return $false }
        }
        Write-Warn 'Please answer Y or N.'
    }
}

function Read-MenuChoice {
    <#
        Shows a numbered menu and returns the zero-based index of the chosen item.
        $Items is an array of objects; $LabelScript / $DetailScript render each row.
    #>
    param(
        [string]$Title,
        [object[]]$Items,
        [scriptblock]$LabelScript,
        [scriptblock]$DetailScript
    )
    Write-Section $Title
    $width = ($Items | ForEach-Object { (& $LabelScript $_).Length } | Measure-Object -Maximum).Maximum
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $num   = ('{0,3}' -f ($i + 1))
        $label = (& $LabelScript $Items[$i]).PadRight($width)
        Write-Host "  $num) " -ForegroundColor Cyan -NoNewline
        Write-Host $label -ForegroundColor White -NoNewline
        if ($DetailScript) {
            Write-Host ("  " + (& $DetailScript $Items[$i])) -ForegroundColor DarkGray
        }
        else {
            Write-Host ''
        }
    }
    while ($true) {
        $choice = Read-Input -Prompt "Select 1-$($Items.Count):"
        $n = 0
        if ([int]::TryParse($choice, [ref]$n) -and $n -ge 1 -and $n -le $Items.Count) {
            return ($n - 1)
        }
        Write-Warn "Enter a number between 1 and $($Items.Count)."
    }
}

#endregion

#region ---------- Exchange helpers ----------

function Connect-ExchangeIfNeeded {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Fail 'The ExchangeOnlineManagement module is not installed.'
        Write-Info 'Install it with: Install-Module ExchangeOnlineManagement -Scope CurrentUser'
        exit 1
    }

    $connected = $null
    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $connected = Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq 'Connected' }
    }

    if ($connected) {
        Write-Ok "Already connected to Exchange Online as $(@($connected)[0].UserPrincipalName)"
    }
    else {
        Write-Info 'Connecting to Exchange Online...'
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
        Write-Ok 'Connected to Exchange Online'
    }
}

function ConvertTo-FolderIdentity {
    # Folder statistics use "/" as the separator and U+F8FF for a literal "/" in a folder name.
    param([string]$MailboxAddress, [string]$FolderPath)
    $path = ($FolderPath -replace '/', '\') -replace [char]0xF8FF, '/'
    return "${MailboxAddress}:$path"
}

function Get-DisplayPath {
    param([string]$FolderPath)
    return ($FolderPath -replace [char]0xF8FF, '/')
}

function Get-FolderDepth {
    param([string]$FolderPath)
    $trimmed = $FolderPath.Trim('/')
    if ($trimmed -eq '') { return 0 }
    return ($trimmed.Split('/')).Count
}

function Test-IsCalendarFolder {
    param($Folder)
    return ($Folder.FolderType -eq 'Calendar' -or "$($Folder.ContainerClass)" -like 'IPF.Appointment*')
}

function Select-MailboxFolder {
    param(
        [object[]]$AllFolders,
        [string]$InitialPath
    )

    $search = $InitialPath
    while ($true) {
        if ([string]::IsNullOrWhiteSpace($search)) {
            Write-Section 'Select folder'
            Write-Info 'Type a full path (e.g. /Inbox/My Archive) or part of a folder name to search.'
            $search = Read-Input -Prompt 'Folder path or search text:'
        }

        # Normalise a typed path: leading "/", no trailing "/"
        $normalized = '/' + $search.Trim().Trim('/')

        $exact = @($AllFolders | Where-Object { (Get-DisplayPath $_.FolderPath) -eq $normalized })
        if ($exact.Count -eq 1) {
            return $exact[0]
        }

        $found = @($AllFolders | Where-Object { (Get-DisplayPath $_.FolderPath) -like "*$($search.Trim())*" } |
            Sort-Object FolderPath)

        if ($found.Count -eq 0) {
            Write-Warn "No folders match '$search'. Try again."
            $search = $null
            continue
        }

        $maxShown = 30
        $shown = @($found | Select-Object -First $maxShown)
        if ($found.Count -gt $maxShown) {
            Write-Warn "$($found.Count) folders matched; showing the first $maxShown. Refine your search to narrow it down."
        }

        # Last menu entry lets the user search again
        $searchAgain = [pscustomobject]@{ FolderPath = '<< Search again >>'; FolderType = ''; ItemsInFolder = '' }
        $options = $shown + $searchAgain

        $index = Read-MenuChoice -Title "Matching folders ($($found.Count))" -Items $options `
            -LabelScript { param($f) Get-DisplayPath $f.FolderPath } `
            -DetailScript {
                param($f)
                if ($f.FolderType -eq '') { '' }
                else { "$($f.FolderType), $($f.ItemsInFolder) items" }
            }

        if ($index -eq $options.Count - 1) {
            $search = $null
            continue
        }
        return $options[$index]
    }
}

#endregion

#region ---------- Main ----------

Write-Banner 'Mailbox Folder Permission Manager'

# 1. Connection
Write-Section 'Connection'
Connect-ExchangeIfNeeded

# 2. Mailbox
Write-Section 'Mailbox'
while ($true) {
    if ([string]::IsNullOrWhiteSpace($Mailbox)) {
        $Mailbox = Read-Input -Prompt 'Mailbox to modify (e.g. shared@contoso.com):'
    }
    try {
        $mbx = Get-EXOMailbox -Identity $Mailbox -ErrorAction Stop
        $Mailbox = $mbx.PrimarySmtpAddress.ToString()
        Write-Ok "Mailbox found: $($mbx.DisplayName) <$Mailbox>"
        break
    }
    catch {
        Write-Fail "Mailbox '$Mailbox' was not found."
        $Mailbox = $null
    }
}

# 3. Target user
Write-Section 'User'
while ($true) {
    if ([string]::IsNullOrWhiteSpace($TargetUser)) {
        $TargetUser = Read-Input -Prompt 'User to grant/remove access for (email, or Default/Anonymous):'
    }
    if ($BuiltInPrincipals -contains $TargetUser) {
        $TargetUser = ($BuiltInPrincipals | Where-Object { $_ -eq $TargetUser })
        Write-Ok "Using built-in principal: $TargetUser"
        break
    }
    try {
        $recipient = Get-EXORecipient -Identity $TargetUser -ErrorAction Stop
        $TargetUser = $recipient.PrimarySmtpAddress.ToString()
        Write-Ok "User found: $($recipient.DisplayName) <$TargetUser>"
        break
    }
    catch {
        Write-Fail "User '$TargetUser' was not found."
        $TargetUser = $null
    }
}

# 4. Action
if (-not $Action) {
    $actions = @(
        [pscustomobject]@{ Name = 'Add';    Label = 'Grant / update permission'; Detail = 'Adds the role, or changes the existing role' }
        [pscustomobject]@{ Name = 'Remove'; Label = 'Remove permission';         Detail = 'Removes the user from the folder permissions' }
    )
    $i = Read-MenuChoice -Title 'Action' -Items $actions -LabelScript { param($a) $a.Label } -DetailScript { param($a) $a.Detail }
    $Action = $actions[$i].Name
}

# 5. Role
if ($Action -eq 'Add' -and -not $AccessRight) {
    $i = Read-MenuChoice -Title 'Permission role' -Items $Roles `
        -LabelScript { param($r) if ($r.CalendarOnly) { "$($r.Name) *" } else { $r.Name } } `
        -DetailScript { param($r) $r.Rights }
    Write-Info '* Calendar-only roles are skipped on non-calendar folders.'
    $AccessRight = $Roles[$i].Name
}
$selectedRole = $Roles | Where-Object { $_.Name -eq $AccessRight }

# 6. Folder
Write-Section 'Folders'
Write-Info "Loading folders for $Mailbox..."
$allFolders = @(Get-MailboxFolderStatistics -Identity $Mailbox -ErrorAction Stop |
    Where-Object { $_.FolderPath -notlike '/Recoverable Items*' })
Write-Ok "$($allFolders.Count) folders loaded"

$rootFolderObj = Select-MailboxFolder -AllFolders $allFolders -InitialPath $RootFolder
$rootPath = $rootFolderObj.FolderPath
Write-Ok "Selected folder: $(Get-DisplayPath $rootPath)"

# 7. Scope
if (-not $Scope) {
    $i = Read-MenuChoice -Title 'Apply to' -Items $Scopes -LabelScript { param($s) $s.Label }
    $Scope = $Scopes[$i].Name
}
$scopeLabel = ($Scopes | Where-Object { $_.Name -eq $Scope }).Label

# Build the list of target folders
$rootDepth = Get-FolderDepth $rootPath
$prefix    = if ($rootPath -eq '/') { '/' } else { "$rootPath/" }

$targets = @($allFolders | Where-Object {
    $path = $_.FolderPath
    if ($path -eq $rootPath) { return $true }
    if ($Scope -eq 'FolderOnly' -or -not $path.StartsWith($prefix)) { return $false }
    if ($Scope -eq 'FolderAndDirectSubfolders') { return ((Get-FolderDepth $path) -eq $rootDepth + 1) }
    return $true
} | Sort-Object FolderPath)

# 8. Review
Write-Banner 'Review'
$actionText = if ($Action -eq 'Add') { "Grant '$AccessRight'" } else { 'Remove permission' }
Write-Host ('  {0,-10} {1}' -f 'Mailbox:', $Mailbox)
Write-Host ('  {0,-10} {1}' -f 'User:',    $TargetUser)
Write-Host ('  {0,-10} {1}' -f 'Action:',  $actionText) -ForegroundColor Yellow
if ($selectedRole) {
    Write-Host ('  {0,-10} {1}' -f 'Rights:', $selectedRole.Rights) -ForegroundColor DarkGray
}
Write-Host ('  {0,-10} {1}' -f 'Folder:',  (Get-DisplayPath $rootPath))
Write-Host ('  {0,-10} {1}' -f 'Scope:',   $scopeLabel)
Write-Host ('  {0,-10} {1} folder(s)' -f 'Targets:', $targets.Count)

$previewCount = 15
Write-Host ''
$targets | Select-Object -First $previewCount | ForEach-Object {
    Write-Host "    - $(Get-DisplayPath $_.FolderPath)" -ForegroundColor DarkGray
}
if ($targets.Count -gt $previewCount) {
    Write-Host "    ... and $($targets.Count - $previewCount) more" -ForegroundColor DarkGray
}

if ($selectedRole -and $selectedRole.CalendarOnly) {
    $nonCalendar = @($targets | Where-Object { -not (Test-IsCalendarFolder $_) }).Count
    if ($nonCalendar -gt 0) {
        Write-Host ''
        Write-Warn "$AccessRight only applies to calendar folders; $nonCalendar non-calendar folder(s) will be skipped."
    }
}

Write-Host ''
if (-not $Force -and -not $WhatIfPreference) {
    if (-not (Read-YesNo -Prompt 'Proceed with these changes?')) {
        Write-Warn 'Cancelled. No changes were made.'
        return
    }
}

# 9. Apply
Write-Banner 'Applying changes'
$results = New-Object System.Collections.Generic.List[object]
$count = 0

foreach ($folder in $targets) {
    $count++
    $displayPath = Get-DisplayPath $folder.FolderPath
    $identity    = ConvertTo-FolderIdentity -MailboxAddress $Mailbox -FolderPath $folder.FolderPath
    Write-Progress -Activity 'Updating folder permissions' -Status $displayPath `
        -PercentComplete ([int](($count / $targets.Count) * 100))

    $status   = ''
    $previous = ''
    $new      = ''
    $detail   = ''

    try {
        # Throws when the user has no entry on the folder, so treat any error as "not present"
        $existing = $null
        try {
            $existing = Get-MailboxFolderPermission -Identity $identity -User $TargetUser -ErrorAction Stop
        }
        catch { }
        if ($existing) { $previous = ($existing.AccessRights -join ', ') }

        if ($Action -eq 'Add') {
            if ($selectedRole.CalendarOnly -and -not (Test-IsCalendarFolder $folder)) {
                $status = 'Skipped'
                $detail = 'Calendar-only role on a non-calendar folder'
            }
            elseif ($existing -and $previous -eq $AccessRight) {
                $status = 'Unchanged'
                $new    = $AccessRight
                $detail = 'Already has this role'
            }
            elseif ($PSCmdlet.ShouldProcess($identity, "Set $TargetUser to $AccessRight")) {
                if ($existing) {
                    Set-MailboxFolderPermission -Identity $identity -User $TargetUser -AccessRights $AccessRight -ErrorAction Stop | Out-Null
                    $status = 'Updated'
                }
                else {
                    Add-MailboxFolderPermission -Identity $identity -User $TargetUser -AccessRights $AccessRight -ErrorAction Stop | Out-Null
                    $status = 'Added'
                }
                $new = $AccessRight
            }
            else {
                $status = 'WhatIf'
            }
        }
        else {
            $isBuiltIn = $BuiltInPrincipals -contains $TargetUser
            if (-not $existing -or ($isBuiltIn -and $previous -eq 'None')) {
                $status = 'NotPresent'
                $detail = 'User had no permission on this folder'
            }
            elseif ($PSCmdlet.ShouldProcess($identity, "Remove $TargetUser")) {
                if ($isBuiltIn) {
                    # Default/Anonymous cannot be removed; reset to None instead
                    Set-MailboxFolderPermission -Identity $identity -User $TargetUser -AccessRights None -ErrorAction Stop | Out-Null
                    $new    = 'None'
                    $detail = 'Built-in principal reset to None'
                }
                else {
                    Remove-MailboxFolderPermission -Identity $identity -User $TargetUser -Confirm:$false -ErrorAction Stop | Out-Null
                }
                $status = 'Removed'
            }
            else {
                $status = 'WhatIf'
            }
        }
    }
    catch {
        $status = 'Failed'
        $detail = $_.Exception.Message
    }

    switch ($status) {
        { $_ -in 'Added', 'Updated', 'Removed' } { Write-Ok   "$status  $displayPath" }
        { $_ -in 'Unchanged', 'NotPresent' }     { Write-Info "$status  $displayPath" }
        'Skipped'                                { Write-Warn "$status  $displayPath ($detail)" }
        'WhatIf'                                 { Write-Info "WhatIf  $displayPath" }
        'Failed'                                 { Write-Fail "$status  $displayPath - $detail" }
    }

    $results.Add([pscustomobject]@{
        Folder   = $displayPath
        Status   = $status
        Previous = $previous
        New      = $new
        Detail   = $detail
    })
}
Write-Progress -Activity 'Updating folder permissions' -Completed

# 10. Summary
Write-Banner 'Summary'
$results | Group-Object Status | Sort-Object Name | ForEach-Object {
    Write-Host ('  {0,-12} {1}' -f $_.Name, $_.Count)
}
$results | Format-Table Folder, Status, Previous, New, Detail -AutoSize -Wrap | Out-Host

if (-not $ExportPath -and -not $Force) {
    if (Read-YesNo -Prompt 'Export results to CSV?') {
        $defaultPath = Join-Path (Get-Location) ("FolderPermissions_{0}.csv" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        $ExportPath = Read-Input -Prompt "CSV path (Enter for $defaultPath):" -AllowEmpty
        if ([string]::IsNullOrWhiteSpace($ExportPath)) { $ExportPath = $defaultPath }
    }
}
if ($ExportPath) {
    $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Ok "Results exported to $ExportPath"
}

Write-Host ''
Write-Ok 'Done.'

#endregion
