@echo off
REM Auto Install Dependencies for C/C++ Projects v2.0
REM Script batch để chạy PowerShell script tự động cài đặt dependencies
REM + MSBuild Build Fix functionality

echo =========================================
echo   Auto Install Dependencies for C/C++   
echo              Version 2.0               
echo        + MSBuild Build Fix             
echo =========================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell and try again.
    pause
    exit /b 1
)

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Not running as administrator.
    echo Some installations may fail. Consider running as administrator.
    echo.
    pause
)

echo Starting automatic dependency installation...
echo This may take several minutes depending on your internet connection.
echo.
echo Available options:
echo   -FixMSBuild     : Fix MSBuild build issues only
echo   -Force          : Force install all dependencies
echo   -InstallOptional: Install optional development tools
echo   -SkipTests      : Skip installation tests
echo   -Verbose        : Show detailed information
echo.
echo Quick actions:
echo   1. Fix MSBuild build issues only
echo   2. Install all dependencies
echo   3. Force reinstall everything
echo.

REM Check if user wants to run specific actions
set /p choice="Choose an action (1-3) or press Enter to continue with default: "

if "%choice%"=="1" (
    echo.
    echo =========================================
    echo   Fixing MSBuild Build Issues Only
    echo =========================================
    echo.
    echo This will fix the MSBuild build errors related to missing tools:
    echo - TlbExp.exe (Windows SDK tool)
    echo - resgen.exe (Windows SDK tool)
    echo - LocateVisualStudioTask failures
    echo.
    echo Starting MSBuild fix...
    echo.
    goto :run_fix_msbuild
) else if "%choice%"=="2" (
    echo.
    echo =========================================
    echo   Installing All Dependencies
    echo =========================================
    echo.
    echo Starting full dependency installation...
    echo.
    goto :run_install
) else if "%choice%"=="3" (
    echo.
    echo =========================================
    echo   Force Reinstall Everything
    echo =========================================
    echo.
    echo Starting force reinstall of all components...
    echo.
    goto :run_force_install
) else (
    echo.
    echo =========================================
    echo   Running Default Installation
    echo =========================================
    echo.
    echo Starting default dependency installation...
    echo.
    goto :run_install
)

:run_fix_msbuild
REM Run PowerShell script with MSBuild fix only
echo Attempting to run PowerShell script with MSBuild fix...
powershell -ExecutionPolicy Bypass -File "install-deps.ps1" -FixMSBuild -Verbose
goto :check_result

:run_install
REM Run PowerShell script with default parameters
echo Attempting to run PowerShell script with default parameters...
powershell -ExecutionPolicy Bypass -File "install-deps.ps1" %*
goto :check_result

:run_force_install
REM Run PowerShell script with force flag
echo Attempting to run PowerShell script with force reinstall...
powershell -ExecutionPolicy Bypass -File "install-deps.ps1" -Force -Verbose
goto :check_result

:check_result
REM Check if PowerShell execution was successful
if %errorlevel% neq 0 (
    echo.
    echo First attempt failed, trying with different execution policy...
    
    if "%choice%"=="1" (
        powershell -ExecutionPolicy Unrestricted -File "install-deps.ps1" -FixMSBuild -Verbose
    ) else if "%choice%"=="3" (
        powershell -ExecutionPolicy Unrestricted -File "install-deps.ps1" -Force -Verbose
    ) else (
        powershell -ExecutionPolicy Unrestricted -File "install-deps.ps1" %*
    )
    
    if %errorlevel% neq 0 (
        echo.
        echo Second attempt failed, trying with RemoteSigned...
        
        if "%choice%"=="1" (
            powershell -ExecutionPolicy RemoteSigned -File "install-deps.ps1" -FixMSBuild -Verbose
        ) else if "%choice%"=="3" (
            powershell -ExecutionPolicy RemoteSigned -File "install-deps.ps1" -Force -Verbose
        ) else (
            powershell -ExecutionPolicy RemoteSigned -File "install-deps.ps1" %*
        )
    )
)

if %errorlevel% equ 0 (
    echo.
    echo =========================================
    if "%choice%"=="1" (
        echo MSBuild Build Issues Fixed Successfully!
        echo =========================================
        echo.
        echo The following issues have been resolved:
        echo - TlbExp.exe and resgen.exe (Windows SDK tools) - AVAILABLE
        echo - MSBuild and build tools - AVAILABLE
        echo - .NET Framework SDKs - AVAILABLE
        echo - Windows SDKs for all versions - AVAILABLE
        echo - The LocateVisualStudioTask should now work properly
        echo.
        echo Next steps:
        echo 1. Restart your terminal to ensure PATH changes take effect
        echo 2. Navigate to your MSBuild source directory
        echo 3. Try building again with: build.cmd
        echo.
    ) else if "%choice%"=="3" (
        echo Force Reinstall Completed Successfully!
        echo =========================================
        echo.
        echo All components have been force reinstalled.
        echo.
    ) else (
        echo Installation Completed Successfully!
        echo =========================================
        echo.
        echo All dependencies have been installed.
        echo.
    )
    echo Please restart your terminal to ensure PATH changes take effect.
    echo.
) else (
    echo.
    echo =========================================
    if "%choice%"=="1" (
        echo MSBuild Build Issues Fix Failed!
        echo =========================================
        echo.
        echo Failed to fix MSBuild build issues.
        echo.
    ) else (
        echo Installation Failed with Errors!
        echo =========================================
        echo.
        echo Failed to install dependencies.
        echo.
    )
    echo Check the error messages above for details.
    echo.
    echo Troubleshooting tips:
    echo 1. Run as Administrator if not already
    echo 2. Check Windows Update for missing components
    echo 3. Try running with -Verbose flag for more details
    echo.
)

pause
