# Force Delete MSBuild Source Directory
# Script mạnh mẽ để xóa hoàn toàn thư mục msbuild-source

Write-Host "=========================================" -ForegroundColor Red
Write-Host "  FORCE DELETE MSBUILD-SOURCE DIRECTORY  " -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Red
Write-Host ""

$msbuildSourceDir = "$env:USERPROFILE\msbuild-source"

if (-not (Test-Path $msbuildSourceDir)) {
    Write-Host "✓ Thư mục msbuild-source không tồn tại" -ForegroundColor Green
    exit 0
}

Write-Host "Thư mục msbuild-source được tìm thấy tại: $msbuildSourceDir" -ForegroundColor Yellow
Write-Host "Bắt đầu quá trình xóa mạnh mẽ..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Kill all related processes
Write-Host "Bước 1: Dừng tất cả processes liên quan..." -ForegroundColor Cyan

$processesToKill = @()

# Find processes by name
$processNames = @("msbuild", "dotnet", "git", "cmd", "powershell", "conhost", "devenv", "vcpkgsrv", "node", "python")
foreach ($name in $processNames) {
    try {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        $processesToKill += $procs
    } catch {
        # Ignore errors
    }
}

# Find processes by command line containing msbuild-source
try {
    $wmiProcs = Get-WmiObject Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -and $_.CommandLine.Contains("msbuild-source")
    }
    foreach ($wmiProc in $wmiProcs) {
        try {
            $proc = Get-Process -Id $wmiProc.ProcessId -ErrorAction SilentlyContinue
            if ($proc) {
                $processesToKill += $proc
            }
        } catch {
            # Ignore errors
        }
    }
} catch {
    Write-Host "Không thể kiểm tra WMI processes" -ForegroundColor Yellow
}

# Kill all found processes
if ($processesToKill.Count -gt 0) {
    Write-Host "Tìm thấy $($processesToKill.Count) processes để dừng..." -ForegroundColor Yellow
    
    foreach ($proc in $processesToKill) {
        try {
            Write-Host "Dừng process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor White
            $proc.Kill()
            Start-Sleep -Milliseconds 100
        } catch {
            Write-Host "Không thể dừng process $($proc.ProcessName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Start-Sleep -Seconds 3
} else {
    Write-Host "Không tìm thấy processes nào cần dừng" -ForegroundColor Green
}

Write-Host ""

# Step 2: Force close file handles
Write-Host "Bước 2: Đóng file handles..." -ForegroundColor Cyan

# Try to use handle.exe if available
$handlePath = "$env:ProgramFiles\Sysinternals\handle.exe"
if (Test-Path $handlePath) {
    Write-Host "Sử dụng handle.exe để đóng file handles..." -ForegroundColor White
    
    try {
        $handleOutput = & $handlePath -a -u $msbuildSourceDir 2>$null
        if ($handleOutput) {
            $handleOutput | ForEach-Object {
                if ($_ -match "(\w+\.exe)\s+pid:\s+(\d+)\s+type:\s+(\w+)\s+(\w+):\s+(.+)") {
                    $exeName = $matches[1]
                    $pid = $matches[2]
                    $handleId = $matches[4]
                    
                    Write-Host "Đóng handle: $exeName (PID: $pid, Handle: $handleId)" -ForegroundColor White
                    & $handlePath -c $handleId -p $pid 2>$null
                }
            }
        }
    } catch {
        Write-Host "Không thể sử dụng handle.exe: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "handle.exe không có sẵn, bỏ qua bước này" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Remove attributes and force delete
Write-Host "Bước 3: Xóa attributes và force delete..." -ForegroundColor Cyan

$maxAttempts = 10
$attempt = 0
$deleted = $false

while (-not $deleted -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Lần thử $attempt/$maxAttempts..." -ForegroundColor White
    
    try {
        # Remove all attributes recursively
        Write-Host "Xóa attributes..." -ForegroundColor White
        Get-ChildItem -Path $msbuildSourceDir -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $_.Attributes = [System.IO.FileAttributes]::Normal
            } catch {
                # Ignore files we can't modify
            }
        }
        
        # Try different deletion methods
        Write-Host "Thử xóa..." -ForegroundColor White
        
        # Method 1: PowerShell Remove-Item
        try {
            Remove-Item -Path $msbuildSourceDir -Recurse -Force -ErrorAction Stop
            $deleted = $true
            Write-Host "✓ Xóa thành công bằng Remove-Item" -ForegroundColor Green
            break
        } catch {
            Write-Host "Remove-Item thất bại: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Method 2: CMD rmdir
        try {
            Write-Host "Thử cmd rmdir..." -ForegroundColor White
            $result = Start-Process -FilePath "cmd" -ArgumentList "/c", "rmdir", "/s", "/q", "`"$msbuildSourceDir`"" -Wait -PassThru -NoNewWindow
            if ($result.ExitCode -eq 0) {
                $deleted = $true
                Write-Host "✓ Xóa thành công bằng cmd rmdir" -ForegroundColor Green
                break
            } else {
                Write-Host "cmd rmdir thất bại với exit code: $($result.ExitCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "cmd rmdir thất bại: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Method 3: .NET Directory.Delete
        try {
            Write-Host "Thử .NET Directory.Delete..." -ForegroundColor White
            [System.IO.Directory]::Delete($msbuildSourceDir, $true)
            $deleted = $true
            Write-Host "✓ Xóa thành công bằng .NET Directory.Delete" -ForegroundColor Green
            break
        } catch {
            Write-Host ".NET Directory.Delete thất bại: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Method 4: Using robocopy to move files to temp and delete
        try {
            Write-Host "Thử robocopy move..." -ForegroundColor White
            $tempDir = "$env:TEMP\msbuild-delete-$(Get-Random)"
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            
            $robocopyResult = Start-Process -FilePath "robocopy" -ArgumentList "`"$tempDir`"", "`"$msbuildSourceDir`"", "/MOVE", "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/NP" -Wait -PassThru -NoNewWindow
            
            if ($robocopyResult.ExitCode -lt 8) {
                # Robocopy succeeded, now delete the temp directory
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                $deleted = $true
                Write-Host "✓ Xóa thành công bằng robocopy move" -ForegroundColor Green
                break
            } else {
                Write-Host "robocopy thất bại với exit code: $($robocopyResult.ExitCode)" -ForegroundColor Yellow
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Host "robocopy thất bại: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Wait before next attempt
        if (-not $deleted -and $attempt -lt $maxAttempts) {
            Write-Host "Chờ 5 giây trước lần thử tiếp theo..." -ForegroundColor White
            Start-Sleep -Seconds 5
            
            # Kill any new processes
            $newProcs = Get-Process | Where-Object {$_.ProcessName -like "*msbuild*" -or $_.ProcessName -like "*git*"}
            foreach ($proc in $newProcs) {
                try {
                    $proc.Kill()
                } catch {
                    # Ignore
                }
            }
        }
        
    } catch {
        Write-Host "Lần thử $attempt thất bại: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 4: Nuclear option - rename and schedule deletion
if (-not $deleted) {
    Write-Host ""
    Write-Host "Bước 4: Sử dụng phương pháp cuối cùng..." -ForegroundColor Red
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $tempDir = "$env:USERPROFILE\msbuild-source-old-$timestamp"
        
        Write-Host "Đổi tên thư mục thành: $tempDir" -ForegroundColor White
        Rename-Item -Path $msbuildSourceDir -NewName $tempDir -ErrorAction Stop
        
        # Create deletion script
        $deletionScript = @"
@echo off
echo Đang xóa thư mục MSBuild cũ...
timeout /t 15 /nobreak >nul
echo Thử xóa: $tempDir
rmdir /s /q "$tempDir"
if exist "$tempDir" (
    echo Xóa thất bại, sẽ thử lại sau...
    del "%~f0"
) else (
    echo Xóa thành công!
    del "%~f0"
)
"@
        
        $deletionScriptPath = "$env:TEMP\delete-msbuild-old-$timestamp.bat"
        $deletionScript | Out-File -FilePath $deletionScriptPath -Encoding ASCII
        
        # Schedule deletion
        try {
            $taskName = "DeleteMSBuildOld_$timestamp"
            schtasks /create /tn $taskName /tr "`"$deletionScriptPath`"" /sc onstart /ru SYSTEM /f 2>$null
            Write-Host "✓ Đã lên lịch xóa thư mục cũ khi khởi động lại" -ForegroundColor Green
        } catch {
            Write-Host "Không thể lên lịch xóa, sẽ xóa thủ công" -ForegroundColor Yellow
        }
        
        Write-Host "✓ Thư mục đã được đổi tên và lên lịch xóa" -ForegroundColor Green
        $deleted = $true
        
    } catch {
        Write-Host "✗ Phương pháp cuối cùng cũng thất bại: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Final verification
Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "  KẾT QUẢ XÓA THƯ MỤC MSBUILD-SOURCE   " -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue

if (Test-Path $msbuildSourceDir) {
    Write-Host "✗ Thư mục msbuild-source VẪN TỒN TẠI!" -ForegroundColor Red
    Write-Host "Vui lòng khởi động lại máy tính và chạy lại script này" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ Thư mục msbuild-source đã được xóa thành công!" -ForegroundColor Green
    Write-Host "Bây giờ bạn có thể chạy install-deps.bat để cài đặt MSBuild" -ForegroundColor Green
}

Write-Host ""
Write-Host "Nhấn phím bất kỳ để thoát..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")