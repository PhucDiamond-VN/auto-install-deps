@echo off
echo Force Delete MSBuild Source Directory
echo ====================================
echo.
echo Script này sẽ xóa mạnh mẽ thư mục msbuild-source
echo Vui lòng chạy với quyền Administrator
echo.
pause

echo.
echo Đang chạy script xóa mạnh mẽ...
powershell -ExecutionPolicy Bypass -File "force-delete-msbuild.ps1"

echo.
echo Script xóa đã hoàn thành.
echo.
pause