## This script is made for 587 port testing

$EmailFrom = "xlock@test.com"
$EmailTo = "2lock@test2.com"  
$Subject = "today date"
$Body = "TODAY SYSTEM DATE=01/04/2016  SYSTEM TIME=11:32:05.50"
$SMTPServer = "smtp.x.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)   
$SMTPClient.EnableSsl = $true    
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("user", "password")    
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)