:: This script stops and starts the service, ADSync for Azure AD Connect
:: This script is intended to be run as a scheduled task
:: 06.19.2023 - Last Updated

@echo off
setlocal

set "ServiceName=ADSync"

REM Check if the service is running
sc query "%ServiceName%" | findstr /i "STATE.*RUNNING" >nul

if %errorlevel% equ 0 (
    echo The "%ServiceName%" service is already running.
) else (
    echo Starting the "%ServiceName%" service...
    net start "%ServiceName%"
)

endlocal