@echo off
chcp 65001 >nul
title Auto Install Dependencies for C/C++ Compiler

echo ========================================
echo Auto Install Dependencies for C/C++ Compiler
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Lỗi: Python chưa được cài đặt!
    echo Vui lòng cài đặt Python 3.7+ từ https://python.org
    echo.
    pause
    exit /b 1
)

echo Python đã được cài đặt.
echo.

REM Check if requirements are installed
echo Kiểm tra Python dependencies...
pip show pathlib2 >nul 2>&1
if errorlevel 1 (
    echo Cài đặt Python dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo Lỗi: Không thể cài đặt Python dependencies!
        pause
        exit /b 1
    )
)

echo.
echo Bắt đầu cài đặt dependencies...
echo.

REM Run the Python installer script
python auto_install_deps.py

echo.
if errorlevel 1 (
    echo Cài đặt thất bại! Vui lòng kiểm tra lỗi ở trên.
) else (
    echo Cài đặt hoàn tất! Chạy 'setup_env.bat' để thiết lập environment.
)

echo.
pause
