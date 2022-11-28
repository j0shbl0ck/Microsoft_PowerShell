:: This script stops and starts the service, ADSync for Azure AD Connect
:: This script is intended to be run as a scheduled task
:: 11.28.2022

net stop ADSync
net start ADSync