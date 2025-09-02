@echo off
REM Fix Execution Policy Script
REM Script batch để sửa Execution Policy cho PowerShell

echo =========================================
echo   Fix Execution Policy for PowerShell   
echo =========================================
echo.

echo This script will help fix PowerShell execution policy issues.
echo.
echo Available options:
echo 1. Run as current user
echo 2. Run as Administrator (recommended)
echo.

set /p choice="Choose option (1 or 2): "

if "%choice%"=="1" (
    echo Running as current user...
    powershell -ExecutionPolicy Bypass -File "fix-execution-policy.ps1"
) else if "%choice%"=="2" (
    echo Running as Administrator...
    powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"fix-execution-policy.ps1\"' -Verb RunAs"
) else (
    echo Invalid choice. Running as current user...
    powershell -ExecutionPolicy Bypass -File "fix-execution-policy.ps1"
)

echo.
echo Execution policy fix completed!
pause
