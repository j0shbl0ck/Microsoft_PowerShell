## This script is made for 25 port testing

# Define SMTP server
$smtpserver = "exoip-com.mail.protection.outlook.com"

# Test SMTP port
Test-NetConnection $smtpserver -Port 25

# Simulated phishing email body
$htmlBody = @"
<html>
<body>
    <p>Jace,</p>
    <p>We noticed unusual activity on your account and need you to verify your credentials to avoid service disruption.</p>
    <p><a href='https://intranet.exoip-security.com/login'>Click here to verify your account</a></p>
    <p>Thank you,<br>IT Security Team</p>
</body>
</html>
"@

# Email parameters
$EmailMessage = @{
    To         = "user@domain.com"  # Replace with test target
    From       = "user@domain.com"
    Subject    = "Please update your ZoHo information"
    Body       = $htmlBody
    SmtpServer = $smtpserver
    Port       = 25
}

# Send the email with HTML formatting
Send-MailMessage @EmailMessage -BodyAsHtml
