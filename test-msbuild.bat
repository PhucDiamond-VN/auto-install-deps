@echo off
echo Testing MSBuild Installation
echo ============================
echo.

echo Checking if MSBuild is available in PATH...
msbuild /version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ MSBuild is available in PATH
    echo.
    echo MSBuild version:
    msbuild /version
) else (
    echo ✗ MSBuild is not available in PATH
    echo.
    echo Searching for MSBuild in common locations...
    
    if exist "%ProgramFiles%\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe" (
        echo Found MSBuild in Visual Studio 2022
        "%ProgramFiles%\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe" /version
    ) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe" (
        echo Found MSBuild in Visual Studio 2022 (x86)
        "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe" /version
    ) else if exist "%ProgramFiles%\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe" (
        echo Found MSBuild in Visual Studio 2019
        "%ProgramFiles%\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe" /version
    ) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe" (
        echo Found MSBuild in Visual Studio 2019 (x86)
        "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe" /version
    ) else if exist "%ProgramFiles%\MSBuild\*\Bin\MSBuild.exe" (
        echo Found standalone MSBuild
        "%ProgramFiles%\MSBuild\*\Bin\MSBuild.exe" /version
    ) else if exist "%ProgramFiles(x86)%\MSBuild\*\Bin\MSBuild.exe" (
        echo Found standalone MSBuild (x86)
        "%ProgramFiles(x86)%\MSBuild\*\Bin\MSBuild.exe" /version
    ) else if exist "%USERPROFILE%\msbuild-source\artifacts\bin\bootstrap\net472\MSBuild\Current\Bin\MSBuild.exe" (
        echo Found MSBuild built from source (bootstrap)
        "%USERPROFILE%\msbuild-source\artifacts\bin\bootstrap\net472\MSBuild\Current\Bin\MSBuild.exe" /version
    ) else if exist "%USERPROFILE%\msbuild-source\artifacts\bin\MSBuild\net472\MSBuild.exe" (
        echo Found MSBuild built from source (dotnet build)
        "%USERPROFILE%\msbuild-source\artifacts\bin\MSBuild\net472\MSBuild.exe" /version
    ) else (
        echo ✗ MSBuild not found in any common location
        echo.
        echo Please run install-deps.bat to install MSBuild
    )
)

echo.
echo Testing MSBuild functionality...
echo Creating test project...

echo ^<?xml version="1.0" encoding="utf-8"?^> > test-project.csproj
echo ^<Project Sdk="Microsoft.NET.Sdk"^> >> test-project.csproj
echo   ^<PropertyGroup^> >> test-project.csproj
echo     ^<OutputType^>Exe^</OutputType^> >> test-project.csproj
echo     ^<TargetFramework^>net6.0^</TargetFramework^> >> test-project.csproj
echo   ^</PropertyGroup^> >> test-project.csproj
echo   ^<Target Name="Test"^> >> test-project.csproj
echo     ^<Message Text="MSBuild is working correctly!" /^> >> test-project.csproj
echo   ^</Target^> >> test-project.csproj
echo ^</Project^> >> test-project.csproj

echo.
echo Attempting to build test project...
msbuild test-project.csproj /t:Test /verbosity:minimal

if %errorlevel% equ 0 (
    echo ✓ MSBuild test successful!
) else (
    echo ✗ MSBuild test failed
)

echo.
echo Cleaning up test files...
del test-project.csproj >nul 2>&1

echo.
echo =========================================
echo MSBuild Test Summary
echo =========================================
echo.

echo Checking PATH for MSBuild...
echo Current PATH entries containing MSBuild:
echo %PATH% | findstr /i msbuild

echo.
echo =========================================
echo MSBuild test completed.
echo =========================================
echo.
echo If MSBuild is not working, try:
echo 1. Run install-deps.bat again
echo 2. Restart your terminal
echo 3. Check if Visual Studio Build Tools is installed
echo.
pause
