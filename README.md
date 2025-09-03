# Auto C/C++ Dependencies Installer

🔧 **Tự động cài đặt tất cả dependencies cần thiết cho C/C++ development**

Công cụ này sẽ tự động phát hiện hệ điều hành và cài đặt tất cả các công cụ cần thiết để phát triển C/C++, bao gồm compiler, build tools, và package managers.

## ✨ Tính năng

- 🖥️ **Hỗ trợ đa nền tảng**: Windows, Linux, macOS
- 🔨 **Cài đặt Compiler**: GCC, Clang, MSVC
- 🏗️ **Build Tools**: CMake, Ninja
- 📦 **Package Managers**: vcpkg, Conan
- 🛠️ **Công cụ bổ trợ**: Git, pkg-config
- 🔄 **Tự động cập nhật PATH**
- 📝 **Logging chi tiết**
- ✅ **Kiểm tra cài đặt**

## 🚀 Cách sử dụng

### Cài đặt dependencies

```bash
# Cài đặt dependencies cho Python script
pip install -r requirements.txt

# Chạy installer
python auto_install_cpp_deps.py
```

### Chạy với quyền Administrator (Windows)

```bash
# Mở Command Prompt/PowerShell với quyền Administrator
python auto_install_cpp_deps.py
```

### Các tùy chọn

```bash
# Xem trợ giúp
python auto_install_cpp_deps.py --help

# Chỉ kiểm tra các công cụ đã cài đặt
python auto_install_cpp_deps.py --verify-only

# Chạy mà không cần quyền admin (có thể hạn chế tính năng)
python auto_install_cpp_deps.py --no-admin
```

## 📋 Các công cụ được cài đặt

### Windows
- **Visual Studio Build Tools** (MSVC Compiler)
- **MSBuild** (Microsoft Build Engine từ Microsoft.VisualStudio.Workload.VCTools)
- **MSYS2** (từ MSYS2.MSYS2 workload với đầy đủ MinGW toolchain)
- **MinGW-w64 GCC/G++** (64-bit MinGW compiler suite)
- **Windows SDK** (Windows 10/11 SDK với tất cả header files: windows.h, winuser.h, etc.)
- **CMake** (Build system generator)
- **Ninja** (Build system)
- **vcpkg** (Package manager)
- **Conan** (Package manager)
- **Git** (Version control)
- **pkg-config** (Library configuration)

### Linux
- **GCC/G++** (Compiler)
- **GDB** (Debugger)
- **Make** (Build tool)
- **CMake** (Build system generator)
- **Ninja** (Build system)
- **vcpkg** (Package manager)
- **Conan** (Package manager)
- **Git** (Version control)

### macOS
- **Xcode Command Line Tools** (Clang compiler)
- **Homebrew** (Package manager)
- **CMake** (Build system generator)
- **Ninja** (Build system)
- **LLVM** (Compiler infrastructure)
- **vcpkg** (Package manager)
- **Conan** (Package manager)

## 🔧 Cấu hình môi trường

Script sẽ tự động:

1. **Cập nhật PATH environment variable** với các công cụ mới
2. **Thiết lập VCPKG_ROOT** environment variable
3. **Cấu hình shell profiles** (.bashrc, .zshrc, etc.)
4. **Integrate vcpkg** với Visual Studio (Windows)
5. **Tạo Conan profile** mặc định

## 📁 Thư mục cài đặt

- **Windows**: `C:\Program Files\CppDeps\`
- **Linux/macOS (với quyền root)**: `/usr/local/`
- **Linux/macOS (user)**: `~/.local/`

## ⚠️ Yêu cầu hệ thống

- **Python 3.6+**
- **Internet connection** để tải xuống các công cụ
- **Quyền Administrator/sudo** (khuyến nghị cho cài đặt đầy đủ)
- **Git** (sẽ được cài đặt tự động nếu chưa có)

## 🔍 Kiểm tra cài đặt

Sau khi cài đặt, script sẽ tự động kiểm tra:

```bash
# Kiểm tra compiler
gcc --version       # MinGW GCC
g++ --version       # MinGW G++
cl                  # MSVC compiler

# Kiểm tra build tools
cmake --version
ninja --version
msbuild -version    # MSBuild
mingw32-make --version  # MinGW Make

# Kiểm tra package managers
vcpkg version
conan --version

# Chạy verification với debug info
python auto_install_cpp_deps.py --verify-only

# Cài đặt riêng từng component
python install_msys2_only.py      # Cài đặt MSYS2 + MinGW
python install_mingw_only.py      # Cài đặt MinGW packages trong MSYS2 có sẵn
python install_cmake_only.py      # Cài đặt CMake
python install_windows_sdk_only.py # Cài đặt Windows SDK + Headers
python fix_msys2.py              # Sửa chữa MSYS2 khi gặp lỗi pacman
python test_debug.py             # Test debug features
python test_windows_sdk.py       # Test Windows SDK & headers
python test_mingw.py             # Test MinGW packages & compilation
python test_mingw_simple.py      # Test MinGW nhanh (recommended)
```

## 🛠️ Xử lý sự cố

### Windows

1. **Chạy với quyền Administrator**
2. **Tắt Windows Defender** tạm thời nếu bị chặn download
3. **Kiểm tra Windows Update** để đảm bảo hệ thống mới nhất
4. **Chạy verification mode**: `python auto_install_cpp_deps.py --verify-only`
5. **Khởi động lại terminal/command prompt** sau khi cài đặt
6. **Kiểm tra PATH environment variable** thủ công

### Debug và Troubleshooting

Script cung cấp thông tin debug chi tiết:

```bash
# Chạy với debug info
python auto_install_cpp_deps.py --verify-only
```

**Thông tin debug bao gồm:**
- PATH environment hiện tại
- Các biến môi trường quan trọng (MSYS2_ROOT, MSBuildPath, VCPKG_ROOT)
- Kiểm tra các thư mục cài đặt thông thường
- Tìm kiếm thủ công các công cụ
- Version information của từng tool

### Các vấn đề thường gặp:

1. **"Command not found" sau khi cài đặt**
   - Khởi động lại terminal/command prompt
   - Kiểm tra PATH có chứa thư mục cài đặt không
   - Chạy `python auto_install_cpp_deps.py --verify-only` để debug

2. **MSVC compiler không tìm thấy**
   - Đảm bảo Visual Studio Build Tools đã được cài đặt
   - Kiểm tra PATH có chứa thư mục MSVC không
   - Chạy script với quyền Administrator

3. **MinGW tools không hoạt động / "target not found"**
   - **Cài đặt MinGW packages riêng**: `python install_mingw_only.py`
   - Chạy `python install_msys2_only.py` để cài đặt MSYS2 riêng
   - **Sửa chữa MSYS2**: `python fix_msys2.py`
   - Kiểm tra MSYS2 đã được cài đặt đầy đủ
   - Chạy `pacman -Syu` để cập nhật MSYS2
   - Kiểm tra PATH có chứa `C:\msys64\mingw64\bin` không
   - **Thử cài đặt thủ công**:
     ```bash
     pacman -Syu
     pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-g++ mingw-w64-x86_64-gdb mingw-w64-x86_64-make
     ```

**4. MSYS2/Pacman errors ("target not found")**
   - Chạy `python fix_msys2.py` để sửa chữa MSYS2
   - Script sẽ reset pacman databases và keyring
   - Khởi động lại MSYS2 environment
   - Cài đặt lại MSYS2 từ đầu nếu cần

5. **CMake không tìm thấy**
   - Chạy `python install_cmake_only.py` để cài đặt CMake riêng
   - Kiểm tra các thư mục cài đặt thông thường
   - Thử cài đặt thủ công từ website chính thức

6. **Windows header files (windows.h, etc.) không tìm thấy**
   - Chạy `python install_windows_sdk_only.py` để cài đặt Windows SDK
   - Mở Visual Studio Installer và cài đặt Windows SDK component
   - Kiểm tra biến môi trường INCLUDE và LIB
   - Tải Windows SDK từ Microsoft website

7. **Script không chạy được**
   - Đảm bảo có Python 3.6+ được cài đặt
   - Cài đặt dependencies: `pip install -r requirements.txt`
   - Chạy với quyền Administrator trên Windows

### Linux

1. **Cập nhật package manager**: `sudo apt update` hoặc `sudo yum update`
2. **Cài đặt curl/wget**: `sudo apt install curl wget`
3. **Kiểm tra internet connection**

### macOS

1. **Cài đặt Xcode từ App Store** trước khi chạy
2. **Chấp nhận Xcode license**: `sudo xcodebuild -license accept`
3. **Cài đặt Homebrew thủ công** nếu cần

## 📝 Log files

Script tạo log chi tiết về quá trình cài đặt. Nếu có lỗi, kiểm tra:

- Console output
- System logs
- Package manager logs

## 🤝 Đóng góp

Nếu bạn gặp vấn đề hoặc muốn thêm tính năng:

1. Tạo issue mô tả chi tiết vấn đề
2. Fork repository và tạo pull request
3. Test trên nhiều platform khác nhau

## 📄 License

MIT License - Xem file LICENSE để biết thêm chi tiết.

## 🆘 Hỗ trợ

Nếu cần hỗ trợ:

1. **Kiểm tra log output** để xác định lỗi
2. **Chạy với `--verify-only`** để kiểm tra trạng thái hiện tại
3. **Thử cài đặt thủ công** các công cụ bị lỗi
4. **Tạo issue** với thông tin chi tiết về hệ thống và lỗi

---

🎉 **Chúc bạn coding vui vẻ với C/C++!**
