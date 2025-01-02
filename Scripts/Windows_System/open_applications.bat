:: Version 1.0.0
:: This batch file opens up applications on startup. 
    :: Keep file in Windows Startup folder. C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\
:: =================================

:: Opens Chrome on startup
cd "C:\Program Files\Google\Chrome\Application"
start Chrome.exe

:: Opens ConnectWise Manage on startup
cd "C:\Program Files (x86)\ConnectWise\PSA.net\"
start ConnectWiseManage.exe

:: Opens ConnectWise Automate on startup
cd "C:\Program Files (x86)\LabTech Client\"
Start LTClient.exe

exit