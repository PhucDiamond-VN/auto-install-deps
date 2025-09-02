# Auto Install Dependencies for C/C++ Compiler

Script Python tự động cài đặt các dependencies cần thiết cho việc compile C/C++ trên Windows.

## 🚀 Tính năng

- **Visual Studio Build Tools**: Cài đặt MSVC compiler và Windows SDK
- **MSBuild**: Microsoft build engine cho .NET và C++
- **MinGW-w64**: Cài đặt GCC compiler cho Windows
- **CMake**: Hệ thống build cross-platform
- **Ninja**: Build system nhanh
- **NuGet**: Package manager cho .NET và C++
- **Git**: Version control system
- **vcpkg**: C++ package manager
- **Make**: Build automation tool
- **Thư viện C++**: Boost, Eigen, OpenCV
- **Tự động cấu hình PATH**: Thêm tools vào system PATH
- **Kiểm tra cài đặt**: Verify tất cả tools hoạt động

## 📋 Yêu cầu hệ thống

- Windows 10/11 (64-bit)
- Python 3.7+
- Kết nối internet
- Quyền Administrator (khuyến nghị)

## 🛠️ Cài đặt

### 1. Cài đặt Python dependencies

```bash
pip install -r requirements.txt
```

### 2. Chạy script cài đặt

```bash
python auto_install_deps.py
```

**Lưu ý**: Khuyến nghị chạy với quyền Administrator để có thể cập nhật system PATH.

## ⚙️ Cấu hình

Bạn có thể tùy chỉnh việc cài đặt bằng cách chỉnh sửa file `deps_config.json`:

```json
{
    "visual_studio": {
        "enabled": true,
        "version": "2022",
        "components": [
            "Microsoft.VisualStudio.Workload.VCTools",
            "Microsoft.VisualStudio.Component.Windows10SDK.19041",
            "Microsoft.VisualStudio.Component.MSBuild",
            "Microsoft.VisualStudio.Component.TextTemplating",
            "Microsoft.VisualStudio.Component.Roslyn.Compiler"
        ]
    },
    "mingw": {
        "enabled": true,
        "version": "13.2.0",
        "architecture": "x86_64"
    },
    "cmake": {
        "enabled": true,
        "version": "3.28.0"
    },
    "ninja": {
        "enabled": true,
        "version": "1.11.1"
    },
    "msbuild": {
        "enabled": true,
        "version": "17.0",
        "auto_detect": true
    },
    "nuget": {
        "enabled": true,
        "version": "6.8.0"
    },
    "git": {
        "enabled": true,
        "version": "2.43.0"
    },
    "libraries": {
        "boost": true,
        "eigen": true,
        "opencv": true,
        "qt": false,
        "vcpkg": true
    },
    "build_tools": {
        "make": true,
        "autotools": false
    }
}
```

## 📁 Cấu trúc thư mục sau khi cài đặt

```
%USERPROFILE%\c++_deps\
├── mingw64\          # MinGW-w64 compiler
├── cmake\            # CMake build system
├── ninja\            # Ninja build system
├── msbuild\          # MSBuild engine
├── nuget\            # NuGet package manager
├── git\              # Git version control
├── vcpkg\            # vcpkg package manager
├── make\             # Make build tool
├── boost\            # Boost C++ libraries
├── eigen\            # Eigen linear algebra library
└── opencv\           # OpenCV computer vision library
```

## 🔧 Sử dụng sau khi cài đặt

### 1. Thiết lập environment

Chạy file `setup_env.bat` được tạo tự động:

```cmd
setup_env.bat
```

### 2. Kiểm tra cài đặt

```cmd
gcc --version
cmake --version
ninja --version
msbuild /version
nuget help
git --version
vcpkg version
make --version
```

### 3. Compile project C++

```cmd
# Sử dụng GCC
g++ -o program.exe source.cpp

# Sử dụng CMake
mkdir build && cd build
cmake ..
cmake --build .
```

## 🚨 Xử lý lỗi

### Lỗi quyền truy cập
- Chạy script với quyền Administrator
- Kiểm tra Windows Defender/antivirus

### Lỗi download
- Kiểm tra kết nối internet
- Tăng timeout trong config
- Tải thủ công và đặt vào thư mục temp

### Lỗi PATH
- Chạy `setup_env.bat` để thiết lập environment
- Restart Command Prompt/PowerShell
- Kiểm tra biến môi trường PATH

## 📝 Ghi chú

- Script sẽ tự động kiểm tra và bỏ qua các tools đã cài đặt
- File tạm sẽ được dọn dẹp tự động sau khi cài đặt
- Có thể chạy lại script để cài đặt thêm components

## 🤝 Đóng góp

Nếu bạn gặp vấn đề hoặc muốn cải thiện script, vui lòng:

1. Tạo issue trên GitHub
2. Fork và submit pull request
3. Báo cáo lỗi với thông tin chi tiết

## 📄 License

MIT License - Xem file LICENSE để biết thêm chi tiết.

## 🙏 Cảm ơn

- Visual Studio Team
- MinGW-w64 contributors
- CMake developers
- Ninja build system
- Các thư viện C++ open source
