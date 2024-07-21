@echo off
setlocal
cd /d %~dp0

if exist identity\identity.key (
  echo Identity 'identity\identity.key' already exists.
  pause
  exit /b
)

if not exist identity.exe (
  curl -OL https://github.com/storj/storj/releases/latest/download/identity_windows_amd64.zip
  powershell Expand-Archive identity_windows_amd64.zip . -Force
  del identity_windows_amd64.zip
)

echo Go to https://storj.dev/node/get-started/auth-token to get an authorization token.
set /p auth-token=Authorization token (email:characterstring): 
echo.
echo Are you sure? (Ctrl-C to cancel)
pause

set identity=identity%random%%random%
identity.exe create %identity%
identity.exe authorize %identity% %auth-token%
move "%appdata%\Storj\Identity\%identity%" .\identity

pause
exit /b
