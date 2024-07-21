@echo off
setlocal
cd /d %~dp0

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Administrator permissions needed
  pause
  exit /b
)

set /p id=Storage Node service id (1): 
echo.
echo Are you sure? (Ctrl-C to cancel)
pause

sc create storagenode%id% DisplayName= "Storage Node %id%" binPath= "\"%cd%\storagenode.exe\" run --config-dir \"%cd%\"" start= auto depend="Dnscache/LanmanServer"
if %errorlevel% neq 0 (
  pause
  exit /b
)
sc failure storagenode%id% actions= restart/60000 reset= 300
if %errorlevel% neq 0 (
  pause
  exit /b
)

echo Start service? (Ctrl-C to cancel)
pause
sc start storagenode%id%

pause
exit /b
