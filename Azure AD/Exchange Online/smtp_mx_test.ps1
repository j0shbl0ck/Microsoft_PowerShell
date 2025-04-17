## This script is made for 25 port testing

# Define SMTP server
$smtpserver = "exoip-com.mail.protection.outlook.com"

# Test connection to SMTP server on port 25
Test-NetConnection $smtpserver -Port 25

# Create and send email
$EmailMessage = @{
    To         = "exoip@gmail.com"
    From       = "scanner@exoip.com"
    Subject    = "Test email"
    Body       = "Test email sent using Office 365 SMTP relay"
    SmtpServer = $smtpserver
    Port       = 25
}

Send-MailMessage @EmailMessage
