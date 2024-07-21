@echo off
setlocal
cd /d %~dp0

if not exist identity\identity.key (
  echo Identity needed, missing 'identity\identity.key'
  pause
  exit /b
)

if exist config.yaml (
  echo Already configured, a 'config.yaml' already exists.
  pause
  exit /b
)

set /p server-port=server-port (28967): 
set /p console-port=console-port (14002): 
set /p external-address=external-address (example.com:28967): 
set /p operator-email=operator-email (my@emailaddress.com): 
set /p operator-wallet=operator-wallet (0xAaaBbbCccDddEeeFff): 
set /p disk-space=disk-space (1.0 TB): 
echo.
echo Are you sure? (Ctrl-C to cancel)
pause

if not exist storagenode.exe (
  curl -OL https://github.com/storj/storj/releases/latest/download/storagenode_windows_amd64.zip
  powershell Expand-Archive storagenode_windows_amd64.zip . -Force
  del storagenode_windows_amd64.zip
)

storagenode.exe setup ^
--console.address :%console-port% ^
--server.address :%server-port% ^
--contact.external-address %external-address% ^
--operator.email %operator-email% ^
--operator.wallet %operator-wallet% ^
--storage.allocated-disk-space "%disk-space%" ^
--config-dir "%cd%" ^
--identity-dir "%cd%\identity" ^
--storage.path "%cd%\storage" ^
--log.level warn ^
--log.output "%cd%\storagenode.log"
if %errorlevel% neq 0 (
  echo Error during 'storagenode.exe setup', see storagenode.log for details
  pause
  exit /b
)

pause
exit /b
