# MSBuild Test Script
# Script kiểm tra cài đặt MSBuild với diagnostics chi tiết

Write-Host "=========================================" -ForegroundColor Blue
Write-Host "  MSBuild Installation Test Script      " -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue
Write-Host ""

# Test if MSBuild is available in PATH
Write-Host "Testing MSBuild availability in PATH..." -ForegroundColor Yellow
try {
    $msbuildVersion = msbuild /version 2>$null
    if ($msbuildVersion) {
        Write-Host "✓ MSBuild is available in PATH (version: $msbuildVersion)" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "✗ MSBuild command exists but version check failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ MSBuild is not available in PATH" -ForegroundColor Red
}

Write-Host ""
Write-Host "Running detailed MSBuild diagnostics..." -ForegroundColor Yellow
Write-Host ""

# Search for MSBuild in common locations
$msbuildSearchPaths = @(
    # Visual Studio 2022
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
    
    # Visual Studio 2019
    "${env:ProgramFiles}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
    
    # Visual Studio 2017
    "${env:ProgramFiles}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe",
    
    # Standalone MSBuild
    "${env:ProgramFiles}\MSBuild\*\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\MSBuild\*\Bin\MSBuild.exe",
    
    # Additional paths
    "${env:ProgramFiles}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe",
    
    # MSBuild from source
    "$env:USERPROFILE\msbuild-source\artifacts\bin\bootstrap\net472\MSBuild\Current\Bin\MSBuild.exe",
    "$env:USERPROFILE\msbuild-source\artifacts\bin\MSBuild\net472\MSBuild.exe"
)

Write-Host "Searching for MSBuild in common installation paths..." -ForegroundColor Cyan
$foundMSBuild = $null

foreach ($path in $msbuildSearchPaths) {
    $foundPath = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundPath) {
        $foundMSBuild = $foundPath
        Write-Host "Found MSBuild at: $($foundPath.FullName)" -ForegroundColor Green
        
        # Test if this MSBuild works
        try {
            $version = & $foundPath.FullName /version 2>$null
            if ($version) {
                Write-Host "✓ MSBuild at this location works (version: $version)" -ForegroundColor Green
                Write-Host "Directory: $((Split-Path -Parent $foundPath.FullName))" -ForegroundColor Cyan
                
                # Check if this directory is in PATH
                $msbuildDir = Split-Path -Parent $foundPath.FullName
                $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                if ($currentPath -like "*$msbuildDir*") {
                    Write-Host "✓ This directory is already in PATH" -ForegroundColor Green
                } else {
                    Write-Host "✗ This directory is NOT in PATH" -ForegroundColor Red
                    Write-Host "You can add it manually or run install-deps.bat again" -ForegroundColor Yellow
                }
                break
            } else {
                Write-Host "✗ MSBuild at this location exists but doesn't work" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ MSBuild at this location exists but throws error" -ForegroundColor Red
        }
    }
}

if (-not $foundMSBuild) {
    Write-Host ""
    Write-Host "No MSBuild found in common locations!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Yellow
    Write-Host "1. Run install-deps.bat again with -Force flag" -ForegroundColor White
    Write-Host "2. Check if Visual Studio Build Tools installation completed successfully" -ForegroundColor White
    Write-Host "3. Manually install MSBuild from Microsoft website" -ForegroundColor White
    Write-Host "4. Check Windows Event Viewer for installation errors" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "MSBuild found but not in PATH. To fix this:" -ForegroundColor Yellow
    Write-Host "1. Restart your terminal after running install-deps.bat" -ForegroundColor White
    Write-Host "2. Or manually add the MSBuild directory to your PATH" -ForegroundColor White
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "Diagnostics completed" -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue
