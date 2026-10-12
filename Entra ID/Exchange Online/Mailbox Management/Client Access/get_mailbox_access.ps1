<#
.SYNOPSIS
    Grants, reviews, or revokes FullAccess to a mailbox (no license required for the target mailbox).
.DESCRIPTION
    Interactive, menu-driven tool for delegating FullAccess on Exchange Online mailboxes.
    - Reuses an existing Exchange Online session if one is already open
    - Validates the mailbox and user exist before making changes
    - Delegate does NOT need a mailbox or license (unlicensed admin accounts work)
    - Shows current delegates before and after changes
    - Optional AutoMapping control (keep Outlook desktop clean)
    - Supports -WhatIf and fully non-interactive use via parameters
.PARAMETER Mailbox
    The mailbox to grant/revoke access on (UPN, alias, or primary SMTP).
.PARAMETER User
    The user receiving or losing access.
.PARAMETER Action
    Grant, Revoke, or View. If omitted, an interactive menu is shown.
.PARAMETER NoAutoMapping
    Do not auto-add the mailbox to the user's Outlook desktop profile.
.PARAMETER KeepConnection
    Leave the Exchange Online session open when the script exits.
.PARAMETER Ascii
    Use plain ASCII icons (for consoles/fonts that show '?' boxes).
.EXAMPLE
    .\Grant-MailboxAccess.ps1
    Launches the interactive menu.
.EXAMPLE
    .\Grant-MailboxAccess.ps1 -Mailbox former.employee@contoso.com -User manager@contoso.com -Action Grant -NoAutoMapping
.EXAMPLE
    .\Grant-MailboxAccess.ps1 -Mailbox shared@contoso.com -User jdoe@contoso.com -Action Revoke -WhatIf
.NOTES
    Author: Josh Block
    Date: 10.11.26
    Type: Public
    Version: 2.2.0
.LINK
    https://github.com/j0shbl0ck
    https://www.reddit.com/r/Office365/comments/1k5xu5b/office_365_global_admin_hacked_with_mfa_enabled
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$Mailbox,
    [string]$User,
    [ValidateSet('Grant', 'Revoke', 'View')]
    [string]$Action,
    [switch]$NoAutoMapping,
    [switch]$KeepConnection,
    [switch]$Ascii
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '2.2.0'
$AutoMapSpecified = $PSBoundParameters.ContainsKey('NoAutoMapping')

#region ── UI helpers ──────────────────────────────────────────────────────────

# Palette — green is reserved for success so it actually means something
$Theme = @{
    Text    = 'White'      # primary content
    Muted   = 'DarkGray'   # chrome, labels, hints
    Accent  = 'Cyan'       # prompts, menu numbers, links
    Ok      = 'Green'
    Warn    = 'Yellow'
    Fail    = 'Red'
    Info    = 'Blue'
    Item    = 'Magenta'    # list bullets (delegates)
}

# Glyphs chosen from what Consolas / Cascadia / Lucida Console actually ship.
# Use -Ascii (or a legacy console) to force plain characters.
$UseUnicode = -not $Ascii -and (($PSVersionTable.PSVersion.Major -ge 7) -or $env:WT_SESSION)
$Glyph = if ($UseUnicode) {
    @{ Ok = [char]0x2714; Fail = [char]0x00D7; Warn = '!'; Info = [char]0x2139; Arrow = [char]0x00BB; Bullet = [char]0x2022; Line = [char]0x2500 }
} else {
    @{ Ok = '+'; Fail = 'x'; Warn = '!'; Info = 'i'; Arrow = '>'; Bullet = '*'; Line = '-' }
}

function Write-Status {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Ok', 'Fail', 'Warn', 'Info', 'Step', 'Item')][string]$Type = 'Info'
    )
    $map = @{
        Ok   = @{ Icon = $Glyph.Ok;     Icon_C = $Theme.Ok;     Text_C = $Theme.Text  }
        Fail = @{ Icon = $Glyph.Fail;   Icon_C = $Theme.Fail;   Text_C = $Theme.Fail  }
        Warn = @{ Icon = $Glyph.Warn;   Icon_C = $Theme.Warn;   Text_C = $Theme.Warn  }
        Info = @{ Icon = $Glyph.Info;   Icon_C = $Theme.Info;   Text_C = 'Gray'       }
        Step = @{ Icon = $Glyph.Arrow;  Icon_C = $Theme.Muted;  Text_C = $Theme.Muted }
        Item = @{ Icon = $Glyph.Bullet; Icon_C = $Theme.Item;   Text_C = $Theme.Text  }
    }
    Write-Host "  $($map[$Type].Icon) " -ForegroundColor $map[$Type].Icon_C -NoNewline
    Write-Host $Message -ForegroundColor $map[$Type].Text_C
}

function Write-KeyValue {
    param([Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][AllowEmptyString()][string]$Value, [string]$Color = $Theme.Text)
    Write-Host "    $($Key.PadRight(12))" -ForegroundColor $Theme.Muted -NoNewline
    Write-Host $Value -ForegroundColor $Color
}

function Write-Rule {
    param([string]$Title)
    $width = [Math]::Min($Host.UI.RawUI.WindowSize.Width - 4, 70)
    if ($Title) {
        $pad = [Math]::Max($width - $Title.Length - 4, 2)
        Write-Host ""
        Write-Host "  $($Glyph.Line)$($Glyph.Line) " -ForegroundColor $Theme.Muted -NoNewline
        Write-Host $Title -ForegroundColor $Theme.Accent -NoNewline
        Write-Host " $([string]$Glyph.Line * $pad)" -ForegroundColor $Theme.Muted
    } else {
        Write-Host "  $([string]$Glyph.Line * $width)" -ForegroundColor $Theme.Muted
    }
}

function Show-Banner {
    Clear-Host
    $line = [string]$Glyph.Line * 48
    Write-Host ""
    Write-Host "   $line" -ForegroundColor $Theme.Muted
    Write-Host "     Mailbox Access Manager " -ForegroundColor $Theme.Text -NoNewline
    Write-Host "v$ScriptVersion" -ForegroundColor $Theme.Accent
    Write-Host "     Exchange Online $($Glyph.Bullet) FullAccess delegation" -ForegroundColor $Theme.Muted
    Write-Host "   $line" -ForegroundColor $Theme.Muted
    if ($WhatIfPreference) { Write-Status "WhatIf mode: no changes will be made." Warn }
}

function Read-Input {
    param([Parameter(Mandatory)][string]$Prompt, [string]$Default)
    $hint = if ($Default) { " [$Default]" } else { '' }
    Write-Host "  $($Glyph.Arrow) " -ForegroundColor $Theme.Accent -NoNewline
    Write-Host $Prompt -ForegroundColor $Theme.Text -NoNewline
    Write-Host "$hint`: " -ForegroundColor $Theme.Muted -NoNewline

    # Make typed input readable instead of inheriting the terminal default
    $prev = $Host.UI.RawUI.ForegroundColor
    try {
        $Host.UI.RawUI.ForegroundColor = $Theme.Accent
        $value = (Read-Host).Trim()
    } finally {
        $Host.UI.RawUI.ForegroundColor = $prev
    }
    if (-not $value -and $Default) { return $Default }
    return $value
}

function Read-YesNo {
    param([Parameter(Mandatory)][string]$Prompt, [bool]$Default = $true)
    $hint = if ($Default) { 'Y/n' } else { 'y/N' }
    while ($true) {
        $answer = Read-Input -Prompt "$Prompt ($hint)"
        if (-not $answer) { return $Default }
        switch -Regex ($answer) {
            '^(y|yes)$' { return $true }
            '^(n|no)$'  { return $false }
            default     { Write-Status "Please answer y or n." Warn }
        }
    }
}

function Show-Menu {
    param([Parameter(Mandatory)][string[]]$Options, [string]$Title = 'What would you like to do?')
    Write-Rule $Title
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "    " -NoNewline
        Write-Host ($i + 1) -ForegroundColor $Theme.Accent -NoNewline
        Write-Host "  $($Options[$i])" -ForegroundColor $Theme.Text
    }
    Write-Host ""
    while ($true) {
        $choice = Read-Input -Prompt "Select 1-$($Options.Count)"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
            return [int]$choice
        }
        Write-Status "Invalid selection." Warn
    }
}

#endregion

#region ── Exchange Online connection ──────────────────────────────────────────

function Connect-Exo {
    Write-Rule 'Connection'

    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Status "ExchangeOnlineManagement module not found. Install with:" Fail
        Write-Host "      Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor $Theme.Accent
        exit 1
    }

    # Reuse an existing session if there is one
    $existing = Get-ConnectionInformation -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Connected' } | Select-Object -First 1
    if ($existing) {
        Write-Status "Connected as $($existing.UserPrincipalName)" Ok
        Write-KeyValue 'Tenant' "$($existing.TenantID)" $Theme.Muted
        $script:ConnectedByScript = $false
        return
    }

    try {
        Write-Status "Connecting to Exchange Online (sign-in window may open)..." Step
        Connect-ExchangeOnline -ShowBanner:$false
        $info = Get-ConnectionInformation | Select-Object -First 1
        Write-Status "Connected as $($info.UserPrincipalName)" Ok
        $script:ConnectedByScript = $true
    } catch {
        Write-Status "Failed to connect: $($_.Exception.Message)" Fail
        exit 1
    }
}

function Disconnect-Exo {
    if ($KeepConnection -or -not $script:ConnectedByScript) {
        Write-Status "Leaving Exchange Online session open." Info
        return
    }
    try {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
        Write-Status "Disconnected from Exchange Online." Ok
    } catch {
        Write-Status "Failed to disconnect cleanly: $($_.Exception.Message)" Warn
    }
}

#endregion

#region ── Lookups & validation ────────────────────────────────────────────────

function Resolve-Recipient {
    <# Prompts until a valid recipient is found (or uses the supplied value). #>
    param(
        [Parameter(Mandatory)][string]$Label,
        [string]$Value,
        [switch]$MailboxOnly,
        [switch]$FailFast
    )
    while ($true) {
        if (-not $Value) { $Value = Read-Input -Prompt $Label }
        if (-not $Value) { continue }

        try {
            Write-Status "Looking up '$Value'..." Step
            if ($MailboxOnly) {
                $r    = Get-EXOMailbox -Identity $Value -Properties DisplayName, RecipientTypeDetails
                $addr = [string]$r.PrimarySmtpAddress
            } else {
                # Get-User returns ANY directory user, including unlicensed accounts with no mailbox
                $r    = Get-User -Identity $Value
                $addr = [string]$r.UserPrincipalName
            }
            $r | Add-Member -NotePropertyName Address    -NotePropertyValue $addr -Force
            $r | Add-Member -NotePropertyName HasMailbox -NotePropertyValue ($r.RecipientTypeDetails -ne 'User') -Force

            Write-Status "$($r.DisplayName) " Ok
            Write-KeyValue 'Address' $addr
            Write-KeyValue 'Type' "$($r.RecipientTypeDetails)" $Theme.Muted
            if (-not $r.HasMailbox) {
                Write-Status "No mailbox on this account. Permissions still apply; open the target via the OWA URL." Info
            }
            return $r
        } catch {
            Write-Status "Couldn't find '$Value'. Check the address and try again." Fail
            if ($FailFast) { exit 1 }
            $Value = $null
        }
    }
}

function Get-Delegates {
    param([Parameter(Mandatory)][string]$Identity)
    Get-EXOMailboxPermission -Identity $Identity |
        Where-Object { $_.User -notlike 'NT AUTHORITY\*' -and $_.User -notlike 'S-1-5-*' -and -not $_.IsInherited -and $_.AccessRights -contains 'FullAccess' }
}

function Show-Delegates {
    param([Parameter(Mandatory)]$MailboxObj)
    Write-Rule "FullAccess on $($MailboxObj.PrimarySmtpAddress)"
    $delegates = @(Get-Delegates -Identity $MailboxObj.PrimarySmtpAddress)
    if ($delegates.Count -eq 0) {
        Write-Status "No delegates." Info
    } else {
        foreach ($d in $delegates) { Write-Status $d.User Item }
    }
    return $delegates
}

#endregion

#region ── Actions ─────────────────────────────────────────────────────────────

function Grant-Access {
    param($MailboxObj, $UserObj)

    $mbx  = $MailboxObj.Address
    $usr  = $UserObj.Address

    if (Get-Delegates -Identity $mbx | Where-Object { $_.User -eq $usr }) {
        Write-Status "$usr already has FullAccess to $mbx." Warn
        return
    }

    $autoMap = if (-not $UserObj.HasMailbox) { $false }   # nothing to map into
               elseif ($AutoMapSpecified) { -not $NoAutoMapping }
               elseif ($Action) { $true }
               else { Read-YesNo -Prompt "Auto-add mailbox to $($UserObj.DisplayName)'s Outlook desktop" -Default $false }

    Write-Rule 'Summary'
    Write-KeyValue 'Mailbox'     "$($MailboxObj.DisplayName) <$mbx>"
    Write-KeyValue 'Grant to'    "$($UserObj.DisplayName) <$usr>"
    Write-KeyValue 'Rights'      'FullAccess' $Theme.Warn
    Write-KeyValue 'AutoMapping' "$autoMap" $(if ($autoMap) { $Theme.Ok } else { $Theme.Muted })
    Write-Host ""

    if (-not $Action -and -not $WhatIfPreference -and -not (Read-YesNo -Prompt 'Proceed')) {
        Write-Status "Cancelled." Warn
        return
    }

    if ($PSCmdlet.ShouldProcess($mbx, "Grant FullAccess to $usr")) {
        try {
            Add-MailboxPermission -Identity $mbx -User $usr -AccessRights FullAccess `
                -InheritanceType All -AutoMapping $autoMap -Confirm:$false | Out-Null
            Write-Status "Granted FullAccess to $usr." Ok
            Write-Host ""
            Write-Status "Open in OWA:" Info
            Write-Host "      https://outlook.office.com/mail/$mbx/" -ForegroundColor $Theme.Accent
            Write-Status "Permissions can take up to 60 minutes to fully propagate." Info
        } catch {
            Write-Status "Failed to grant access: $($_.Exception.Message)" Fail
        }
    }
}

function Revoke-Access {
    param($MailboxObj, $UserObj)

    $mbx = $MailboxObj.Address

    # Let the operator pick from existing delegates if no user was supplied
    if (-not $UserObj) {
        $delegates = @(Get-Delegates -Identity $mbx)
        if ($delegates.Count -eq 0) {
            Write-Status "No delegates to remove on $mbx." Info
            return
        }
        $pick = Show-Menu -Title 'Remove which delegate?' -Options (@($delegates.User) + 'Cancel')
        if ($pick -gt $delegates.Count) { Write-Status "Cancelled." Warn; return }
        $usr = $delegates[$pick - 1].User
    } else {
        $usr = $UserObj.Address
    }

    if (-not $Action -and -not $WhatIfPreference -and -not (Read-YesNo -Prompt "Remove $usr from $mbx" -Default $false)) {
        Write-Status "Cancelled." Warn
        return
    }

    if ($PSCmdlet.ShouldProcess($mbx, "Revoke FullAccess from $usr")) {
        try {
            Remove-MailboxPermission -Identity $mbx -User $usr -AccessRights FullAccess `
                -InheritanceType All -Confirm:$false | Out-Null
            Write-Status "Removed $usr from $mbx." Ok
        } catch {
            Write-Status "Failed to remove access: $($_.Exception.Message)" Fail
        }
    }
}

#endregion

#region ── Main ────────────────────────────────────────────────────────────────

$script:ConnectedByScript = $false
Show-Banner
Connect-Exo

try {
    # ── Non-interactive mode ──
    if ($Action) {
        $mbxObj = Resolve-Recipient -Label 'Mailbox' -Value $Mailbox -MailboxOnly -FailFast
        switch ($Action) {
            'View'   { Show-Delegates -MailboxObj $mbxObj | Out-Null }
            'Grant'  { Grant-Access  -MailboxObj $mbxObj -UserObj (Resolve-Recipient -Label 'User' -Value $User -FailFast) }
            'Revoke' { Revoke-Access -MailboxObj $mbxObj -UserObj (Resolve-Recipient -Label 'User' -Value $User -FailFast) }
        }
        return
    }

    # ── Interactive loop ──
    $mbxObj = $null
    while ($true) {
        if (-not $mbxObj) {
            Write-Rule 'Target mailbox'
            $mbxObj = Resolve-Recipient -Label 'Mailbox to manage' -Value $Mailbox -MailboxOnly
            $Mailbox = $null
            Show-Delegates -MailboxObj $mbxObj | Out-Null
        }

        $choice = Show-Menu -Options @(
            'Grant FullAccess to a user'
            'Revoke a user''s FullAccess'
            'Refresh current delegates'
            'Switch to a different mailbox'
            'Exit'
        )

        switch ($choice) {
            1 {
                $userObj = Resolve-Recipient -Label 'User to grant access' -Value $User
                $User = $null
                Grant-Access -MailboxObj $mbxObj -UserObj $userObj
            }
            2 { Revoke-Access -MailboxObj $mbxObj -UserObj $null }
            3 { Show-Delegates -MailboxObj $mbxObj | Out-Null }
            4 { $mbxObj = $null }
            5 { return }
        }
    }
}
finally {
    Write-Rule
    Disconnect-Exo
    Write-Host ""
}

#endregion