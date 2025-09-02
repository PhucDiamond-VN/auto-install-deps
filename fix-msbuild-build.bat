@echo off
echo =========================================
echo   Fix MSBuild Build Issues Script
echo =========================================
echo.
echo This script will fix the MSBuild build errors related to missing tools:
echo - TlbExp.exe (Windows SDK tool)
echo - resgen.exe (Windows SDK tool)
echo - LocateVisualStudioTask failures
echo.
echo Running integrated install-deps.bat script with MSBuild fix...
echo.

REM Run the integrated batch file with MSBuild fix
call "install-deps.bat"

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
