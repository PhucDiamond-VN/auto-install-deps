@echo off
REM Auto Install Dependencies for C/C++ Projects v2.0
REM Script batch để chạy PowerShell script tự động cài đặt dependencies

echo =========================================
echo   Auto Install Dependencies for C/C++   
echo              Version 2.0               
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
echo   -Force          : Force install all dependencies
echo   -InstallOptional: Install optional development tools
echo   -SkipTests      : Skip installation tests
echo   -Verbose        : Show detailed information
echo.

REM Run PowerShell script with all parameters
REM Try different execution policy approaches
echo Attempting to run PowerShell script...
powershell -ExecutionPolicy Bypass -File "install-deps.ps1" %*

if %errorlevel% neq 0 (
    echo.
    echo First attempt failed, trying with different execution policy...
    powershell -ExecutionPolicy Unrestricted -File "install-deps.ps1" %*
    
    if %errorlevel% neq 0 (
        echo.
        echo Second attempt failed, trying with RemoteSigned...
        powershell -ExecutionPolicy RemoteSigned -File "install-deps.ps1" %*
    )
)

if %errorlevel% equ 0 (
    echo.
    echo =========================================
    echo Installation completed successfully!
    echo =========================================
    echo.
    echo Please restart your terminal to ensure PATH changes take effect.
    echo.
) else (
    echo.
    echo =========================================
    echo Installation failed with errors!
    echo =========================================
    echo.
    echo Check the error messages above for details.
    echo.
)

pause
