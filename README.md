# Auto Install Dependencies for C/C++ Projects v2.0

Hệ thống tự động cài đặt tất cả dependencies cần thiết để build C/C++ projects trên Windows với nhiều công cụ mở rộng.

## 🚀 Tính năng

- **Tự động cài đặt** tất cả tools cần thiết
- **Kiểm tra dependencies** đã có sẵn
- **Cập nhật PATH** tự động
- **Kiểm tra sau cài đặt** để đảm bảo hoạt động
- **Hỗ trợ nhiều phương thức** cài đặt (Chocolatey, direct download, pip)

## 📋 Dependencies được cài đặt

### Core Tools
- **Chocolatey** - Package manager cho Windows
- **Git** - Version control system
- **Python** - Programming language
- **Node.js** - JavaScript runtime cho build tools

### Compilers
- **Visual Studio Build Tools** - Microsoft C++ compiler và build tools
- **MinGW-w64** - GNU Compiler Collection cho Windows
- **Clang/LLVM** - LLVM C/C++ compiler

### Build Tools
- **CMake** - Cross-platform build system
- **Ninja** - Fast build system
- **Make** - Build automation tool
- **MSBuild** - Microsoft build engine

### Package Managers
- **Conan** - C/C++ package manager
- **vcpkg** - C++ library manager

### Development Tools
- **Visual Studio Code** - Code editor với C/C++ support
- **Notepad++** - Text editor với syntax highlighting
- **7-Zip** - File archiver
- **WinMerge** - File comparison tool

### Debugging Tools
- **GDB** - GNU debugger
- **Valgrind** - Memory error detector

### Testing Tools
- **Google Test** - C++ testing framework
- **Catch2** - Modern C++ testing framework

### Documentation Tools
- **Doxygen** - Documentation generator
- **Graphviz** - Graph visualization software

### Profiling Tools
- **Performance Tools** - Visual Studio performance analysis
- **Intel VTune** - Performance profiler

## 🛠️ Cách sử dụng

### Phương pháp 1: Script Batch (Đơn giản nhất)

1. **Chuẩn bị:**
   - Đảm bảo PowerShell có sẵn trên hệ thống
   - Chạy với quyền Administrator (khuyến nghị)

2. **Chạy script:**
   ```cmd
   install-deps.bat
   ```

### Phương pháp 2: PowerShell Script (Đầy đủ tính năng)

1. **Chuẩn bị:**
   - PowerShell 5.0 trở lên
   - Quyền Administrator (khuyến nghị)

2. **Chạy script:**
   ```powershell
   .\install-deps.ps1
   ```

3. **Các tham số có sẵn:**
   ```powershell
   .\install-deps.ps1 -Force          # Bắt buộc cài đặt tất cả
   .\install-deps.ps1 -Verbose        # Hiển thị thông tin chi tiết
   .\install-deps.ps1 -InstallOptional # Cài đặt tools tùy chọn
   .\install-deps.ps1 -SkipTests      # Bỏ qua kiểm tra sau cài đặt
   .\install-deps.ps1 -ConfigFile "custom-config.json"
   ```

### Phương pháp 3: Quick Install (Cài đặt nhanh)

```powershell
.\quick-install.ps1
```

## ⚙️ Cấu hình

Bạn có thể tùy chỉnh file `deps-config.json` để:

- Thay đổi danh sách dependencies
- Cấu hình phương thức cài đặt
- Điều chỉnh tùy chọn cài đặt

## 🔧 Yêu cầu hệ thống

- **OS:** Windows 10/11 (x64)
- **RAM:** Tối thiểu 8GB
- **Disk:** Tối thiểu 20GB trống
- **PowerShell:** 5.0 trở lên
- **Internet:** Kết nối ổn định để download

## 📁 Cấu trúc thư mục

```
auto-install-deps/
├── install-deps.ps1      # Script PowerShell chính
├── install-deps.bat      # Script batch wrapper
├── quick-install.ps1     # Script cài đặt nhanh
├── deps-config.json      # File cấu hình dependencies
├── check-install.bat     # Script kiểm tra cài đặt
├── fix-execution-policy.ps1  # Script sửa Execution Policy
├── fix-execution-policy.bat  # Script batch sửa Execution Policy
├── simple-check.bat      # Script kiểm tra đơn giản
├── QUICK-START.md        # Hướng dẫn nhanh
└── README.md             # Hướng dẫn chi tiết
```

## 🚨 Lưu ý quan trọng

1. **Quyền Administrator:** Một số tools cần quyền admin để cài đặt
2. **Antivirus:** Có thể chặn một số downloads, hãy tạm thời tắt hoặc thêm exception
3. **Firewall:** Đảm bảo cho phép PowerShell và Chocolatey truy cập internet
4. **Restart Terminal:** Sau khi cài đặt xong, restart terminal để PATH có hiệu lực

## 🔍 Troubleshooting

### Lỗi thường gặp

1. **"Execution Policy" error:**
   
   **Cách 1: Sử dụng script fix tự động**
   ```cmd
   fix-execution-policy.bat
   ```
   
   **Cách 2: Sửa thủ công**
   ```powershell
   # Kiểm tra execution policy hiện tại
   Get-ExecutionPolicy -List
   
   # Thiết lập cho current user
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Hoặc sử dụng Bypass (tạm thời)
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
   ```
   
   **Cách 3: Chạy với execution policy khác**
   ```cmd
   powershell -ExecutionPolicy Bypass -File "install-deps.ps1"
   ```

2. **Chocolatey không cài được:**
   - Kiểm tra kết nối internet
   - Chạy với quyền Administrator
   - Tạm thời tắt antivirus

3. **Visual Studio Build Tools lỗi:**
   - Đảm bảo có đủ disk space
   - Kiểm tra Windows Update
   - Chạy với quyền Administrator

### Kiểm tra cài đặt

#### **Sử dụng script kiểm tra:**
```cmd
check-install.bat
```

#### **Kiểm tra thủ công:**
```cmd
# Kiểm tra các tools
git --version
python --version
cmake --version
ninja --version
conan --version
```

## 📞 Hỗ trợ

Nếu gặp vấn đề:

1. Kiểm tra log lỗi trong terminal
2. Đảm bảo đã chạy với quyền Administrator
3. Kiểm tra kết nối internet
4. Tạm thời tắt antivirus/firewall

## 📝 Changelog

### Version 2.0.0
- Thêm nhiều công cụ mới (Clang/LLVM, vcpkg, Make, Node.js)
- Hỗ trợ development tools (VS Code, Notepad++, 7-Zip, WinMerge)
- Hỗ trợ debugging tools (GDB, Valgrind)
- Hỗ trợ testing frameworks (Google Test, Catch2)
- Hỗ trợ documentation tools (Doxygen, Graphviz)
- Hỗ trợ profiling tools
- Cải thiện error handling và logging
- Thêm tham số -InstallOptional và -SkipTests

### Version 1.0.0
- Script cài đặt cơ bản
- Hỗ trợ Chocolatey, Visual Studio Build Tools, CMake
- Tự động cập nhật PATH
- Kiểm tra sau cài đặt

## 📄 License

MIT License - Sử dụng tự do cho mục đích cá nhân và thương mại.
