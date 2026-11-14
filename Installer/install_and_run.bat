@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_and_run.ps1"
if %ERRORLEVEL% neq 0 (
    echo.
    echo An error occurred during installation.
    pause
)
