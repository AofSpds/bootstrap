@echo off
setlocal DisableDelayedExpansion
if not exist "%~dp0bootstrap.ps1" (
  echo [ERROR] Extract the complete ZIP before running bootstrap.bat.
  pause
  exit /b 2
)
if "%~1"=="" goto interactive
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap.ps1" %*
exit /b %errorlevel%
:interactive
echo This process runs the local reviewed script. Machine policy is not changed.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap.ps1" -Mode Install
set "BOOTSTRAP_EXIT=%errorlevel%"
echo Exit code: %BOOTSTRAP_EXIT%
pause
exit /b %BOOTSTRAP_EXIT%
