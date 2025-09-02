@echo off
echo =========================================
echo   Fix MSBuild Build Issues Script
echo =========================================
echo.
echo This script will fix the MSBuild build errors related to missing tools:
echo - TlbExp.exe (Windows SDK tool)
echo - resgen.exe (Windows SDK tool)
echo.
echo Running PowerShell script with appropriate parameters...
echo.

powershell -ExecutionPolicy Bypass -File "install-deps.ps1" -Force -Verbose

echo.
echo =========================================
echo   Fix completed!
echo =========================================
echo.
echo If you still have issues, please:
echo 1. Restart your terminal
echo 2. Try building MSBuild again
echo 3. Check if the required tools are now available
echo.
pause
