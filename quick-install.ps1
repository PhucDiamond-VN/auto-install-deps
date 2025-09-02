# Quick Install Dependencies for C/C++ Projects v2.0
# Script đơn giản để cài đặt nhanh dependencies cơ bản

Write-Host "=========================================" -ForegroundColor Blue
Write-Host "  Quick Install Dependencies for C/C++   " -ForegroundColor Blue
Write-Host "              Version 2.0               " -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue
Write-Host ""

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install Chocolatey if not present
if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
} else {
    Write-Host "Chocolatey is already installed" -ForegroundColor Green
}

# Install essential tools
$tools = @("git", "python", "nodejs", "cmake", "ninja", "make")

foreach ($tool in $tools) {
    Write-Host "Installing $tool..." -ForegroundColor Yellow
    choco install $tool -y
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$tool installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to install $tool" -ForegroundColor Red
    }
}

# Install Visual Studio Build Tools
Write-Host "Installing Visual Studio Build Tools..." -ForegroundColor Yellow
$vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
$vsInstaller = "$env:TEMP\vs_buildtools.exe"

Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller
Start-Process -FilePath $vsInstaller -ArgumentList "--quiet", "--wait", "--add", "Microsoft.VisualStudio.Workload.VCTools", "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041", "--add", "Microsoft.VisualStudio.Component.Windows11SDK.22621" -Wait

# Install vcpkg
Write-Host "Installing vcpkg..." -ForegroundColor Yellow
$vcpkgPath = "$env:USERPROFILE\vcpkg"
if (-not (Test-Path $vcpkgPath)) {
    New-Item -ItemType Directory -Path $vcpkgPath -Force | Out-Null
}
Set-Location $vcpkgPath
git clone https://github.com/Microsoft/vcpkg.git .

Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "Installation completed!" -ForegroundColor Green
Write-Host "Please restart your terminal." -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Blue
