@echo off
echo Checking C/C++ Dependencies Installation v2.0
echo ==============================================
echo.

echo Checking Core Tools...
echo ---------------------
echo Checking Git...
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Git is installed
) else (
    echo ✗ Git is not found
)

echo.
echo Checking Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Python is installed
) else (
    echo ✗ Python is not found
)

echo.
echo Checking Node.js...
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Node.js is installed
) else (
    echo ✗ Node.js is not found
)

echo.
echo Checking Chocolatey...
choco --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Chocolatey is installed
) else (
    echo ✗ Chocolatey is not found
)

echo.
echo Checking Compilers...
echo --------------------
echo Checking GCC/MinGW...
gcc --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ GCC/MinGW is installed
) else (
    echo ✗ GCC/MinGW is not found
)

echo.
echo Checking Clang...
clang --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Clang is installed
) else (
    echo ✗ Clang is not found
)

echo.
echo Checking Build Tools...
echo ----------------------
echo Checking CMake...
cmake --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ CMake is installed
) else (
    echo ✗ CMake is not found
)

echo.
echo Checking Ninja...
ninja --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Ninja is installed
) else (
    echo ✗ Ninja is not found
)

echo.
echo Checking Make...
make --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Make is installed
) else (
    echo ✗ Make is not found
)

echo.
echo Checking Package Managers...
echo ---------------------------
echo Checking Conan...
conan --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Conan is installed
) else (
    echo ✗ Conan is not found
)

echo.
echo Checking vcpkg...
if exist "%USERPROFILE%\vcpkg\vcpkg.exe" (
    echo ✓ vcpkg is installed
) else (
    echo ✗ vcpkg is not found
)

echo.
echo Check completed!
pause
