@echo off
setlocal
pushd %~dp0

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Administrator permissions needed
  goto exit
)

set /p id=Storage Node service id (1): 
echo Are you sure? (Ctrl-C to cancel)
pause

sc create storagenode%id% DisplayName= "Storage Node %id%" binPath= "\"%cd%\storagenode.exe\" run --config-dir \"%cd%\"" start= auto depend="Dnscache/LanmanServer"
if %errorlevel% neq 0 goto exit
sc failure storagenode%id% actions= restart/60000 reset= 300
if %errorlevel% neq 0 goto exit
echo storagenode%id%> servicename.txt

echo Start service? (Ctrl-C to cancel)
pause
sc start storagenode%id%

:exit
pause
popd
exit /b
