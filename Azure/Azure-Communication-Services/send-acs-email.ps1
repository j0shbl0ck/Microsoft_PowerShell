<#
.SYNOPSIS
    Sends an email via Azure Communication Services (ACS) using SMTP AUTH.

.DESCRIPTION
    Demonstrates authenticating to an Azure Communication Services Email
    resource over SMTP (port 587, STARTTLS) using an Entra ID app registration
    as the credential, and sending a test message via Send-MailMessage.

    This script is a TEMPLATE. Replace all placeholder values below before running.

.NOTES
    Author:   Josh Block
    GitHub:   https://github.com/j0shbl0ck
    Version:  1.0.0

    ------------------------------------------------------------------
    HOW THE SMTP USERNAME IS BUILT
    ------------------------------------------------------------------
    ACS SMTP AUTH does not use a plain email address as the username.
    The default username is a dot-delimited string made of three parts:

        <ACS-resource-name>.<Entra-App-(client)-ID>.<Entra-Tenant-ID>

    Example:
        acs-mycompany-prod.11111111-2222-3333-4444-555555555555.66666666-7777-8888-9999-000000000000

    Where to find each part:
      - ACS resource name  : Azure Portal > your Communication Services
                              resource > Overview (the resource's Name,
                              NOT the Email Communication Service/domain
                              resource name).
      - Entra App (client) ID : Azure Portal > Entra ID > App registrations
                              > your app > Overview > "Application (client) ID".
      - Entra Tenant ID    : Same App registration Overview page,
                              "Directory (tenant) ID".

    This default username string is long (~90+ characters) and some SMTP
    clients — notably older embedded devices/printer firmware — will
    silently truncate it, which causes authentication failures that look
    identical to a wrong password. If you hit that, ACS supports creating
    a short CUSTOM SMTP USERNAME mapped to the same Entra app:

        Azure Portal > your Communication Services resource >
        Settings > SMTP Usernames > + Add SMTP Username

    Once created, that short alias (e.g. "myapp01") can be used in place
    of the long dotted string anywhere — including this script.

    The password in both cases is the Entra app's CLIENT SECRET VALUE
    (Entra ID > App registrations > your app > Certificates & secrets >
    "Value" column — not the Secret ID).

    ------------------------------------------------------------------
    THE "FROM" ADDRESS MUST ALREADY BE PROVISIONED IN ACS
    ------------------------------------------------------------------
    You cannot send FROM an arbitrary address on your verified domain.
    ACS requires the exact local-part (the part before the @) to be
    explicitly configured as a MailFrom address on the domain resource:

        Azure Portal > your Email Communication Service resource >
        Provision domains > select your domain > MailFrom addresses

    Every ACS Email domain has "DoNotReply" available by default
    (e.g. DoNotReply@yourdomain.com) with no extra setup. Any other
    sender (e.g. "noreply", "alerts", "printer") must be added here
    first — including having its own domain verification status show
    as verified — or every send will fail with an error resembling
    "Email sender's username is invalid," even though authentication
    itself succeeded.

    $FromEmail below MUST exactly match (case-insensitive) one of the
    addresses configured in that list.

    ------------------------------------------------------------------
    REQUIRED RBAC ROLE
    ------------------------------------------------------------------
    The Entra app's service principal also needs a role assignment
    directly on the Communication Services resource itself (not just
    the domain/email resource):

        Communication Services resource > Access control (IAM) >
        Add role assignment > "Communication and Email Service Owner"
        (or Contributor) > assign to your app's service principal,
        scoped to "This resource"

    Role assignment can take a few minutes to propagate.
#>

# ---------------------------------------------------------------------
# 1. SMTP server settings — these are fixed for all ACS Email resources
# ---------------------------------------------------------------------
$SmtpServer = "smtp.azurecomm.net"
$Port       = 587

# ---------------------------------------------------------------------
# 2. Authentication credentials — REPLACE THESE
# ---------------------------------------------------------------------
# Client secret VALUE from your Entra app registration.
$AppSecret  = "YOUR_ENTRA_CLIENT_SECRET_VALUE"

# Either the long default username:
#   "<acs-resource-name>.<entra-app-id>.<entra-tenant-id>"
# or a short custom SMTP username you created under
# Communication Services resource > Settings > SMTP Usernames.
$SmtpUser   = "YOUR_SMTP_USERNAME"

# ---------------------------------------------------------------------
# 3. Email envelope — REPLACE THESE
# ---------------------------------------------------------------------
# $FromEmail MUST already exist as a MailFrom address on your ACS
# domain resource. See the .NOTES section above — this is the #1
# cause of send failures for first-time setups.
$FromEmail  = "DoNotReply@yourverifieddomain.com"
$ToEmail    = "recipient@example.com"
$Subject    = "Azure Communication Services SMTP Test"
$Body       = "This is a test email sent via Azure Communication Services SMTP relay using PowerShell."

# ---------------------------------------------------------------------
# 4. Build credential object
# ---------------------------------------------------------------------
$SecurePassword = ConvertTo-SecureString $AppSecret -AsPlainText -Force
$Credential     = New-Object System.Management.Automation.PSCredential ($SmtpUser, $SecurePassword)

# ---------------------------------------------------------------------
# 5. Send
# ---------------------------------------------------------------------
try {
    Send-MailMessage -SmtpServer $SmtpServer `
                      -Port $Port `
                      -UseSsl `
                      -Credential $Credential `
                      -From $FromEmail `
                      -To $ToEmail `
                      -Subject $Subject `
                      -Body $Body `
                      -Encoding ([System.Text.Encoding]::UTF8)

    Write-Host "Email sent successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to send email: $($_.Exception.Message)" -ForegroundColor Red

    Write-Host ""
    Write-Host "Common causes:" -ForegroundColor Yellow
    Write-Host "  - 535 5.7.3 Authentication unsuccessful:" -ForegroundColor Yellow
    Write-Host "      Wrong ACS resource name / App ID / Tenant ID in `$SmtpUser," -ForegroundColor Yellow
    Write-Host "      wrong/expired client secret, or missing RBAC role assignment" -ForegroundColor Yellow
    Write-Host "      on the Communication Services resource." -ForegroundColor Yellow
    Write-Host "  - 'Email sender's username is invalid':" -ForegroundColor Yellow
    Write-Host "      `$FromEmail is not a configured MailFrom address on the domain." -ForegroundColor Yellow
}