# Auto Install Dependencies for C/C++ Compiler
# Script PowerShell để chạy script Python cài đặt dependencies

param(
    [switch]$Force,
    [switch]$Help
)

if ($Help) {
    Write-Host "Auto Install Dependencies for C/C++ Compiler" -ForegroundColor Cyan
    Write-Host "Usage: .\run_installer.ps1 [-Force] [-Help]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Force    Force reinstall even if dependencies exist" -ForegroundColor White
    Write-Host "  -Help     Show this help message" -ForegroundColor White
    exit 0
}

# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Install Dependencies for C/C++ Compiler" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Python đã được cài đặt: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python not found"
    }
} catch {
    Write-Host "✗ Lỗi: Python chưa được cài đặt!" -ForegroundColor Red
    Write-Host "Vui lòng cài đặt Python 3.7+ từ https://python.org" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Nhấn Enter để thoát"
    exit 1
}

Write-Host ""

# Check if requirements are installed
Write-Host "Kiểm tra Python dependencies..." -ForegroundColor Blue
try {
    $null = pip show pathlib2 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Python dependencies đã được cài đặt" -ForegroundColor Green
    } else {
        throw "Dependencies not found"
    }
} catch {
    Write-Host "Cài đặt Python dependencies..." -ForegroundColor Yellow
    try {
        pip install -r requirements.txt
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Python dependencies đã được cài đặt thành công" -ForegroundColor Green
        } else {
            throw "Failed to install dependencies"
        }
    } catch {
        Write-Host "✗ Lỗi: Không thể cài đặt Python dependencies!" -ForegroundColor Red
        Read-Host "Nhấn Enter để thoát"
        exit 1
    }
}

Write-Host ""
Write-Host "Bắt đầu cài đặt dependencies..." -ForegroundColor Blue
Write-Host ""

# Run the Python installer script
try {
    python auto_install_deps.py
    $exitCode = $LASTEXITCODE
} catch {
    Write-Host "✗ Lỗi khi chạy script Python: $_" -ForegroundColor Red
    $exitCode = 1
}

Write-Host ""

if ($exitCode -eq 0) {
    Write-Host "✓ Cài đặt hoàn tất!" -ForegroundColor Green
    Write-Host "Chạy 'setup_env.bat' để thiết lập environment." -ForegroundColor Yellow
} else {
    Write-Host "✗ Cài đặt thất bại! Vui lòng kiểm tra lỗi ở trên." -ForegroundColor Red
}

Write-Host ""
Read-Host "Nhấn Enter để thoát"
