$EmailMessage = @{
    To         = "exoip@gmail.com"
    From       = "scanner@exoip.com"
    Subject    = "Test email"
    Body       = "Test email sent using Office 365 SMTP relay"
    SmtpServer = "exoip-com.mail.protection.outlook.com"
    Port       = "25"
}

Send-MailMessage @EmailMessage