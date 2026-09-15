@echo off
setlocal
cd /d "%~dp0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\OMH-Release.ps1" %*
set "OMH_EXIT=%ERRORLEVEL%"
if not "%OMH_EXIT%"=="0" if "%~1"=="" pause
exit /b %OMH_EXIT%
