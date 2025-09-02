# Quick Start Guide - C/C++ Dependencies v2.0

## 🚀 Cài đặt nhanh

### **Bước 1: Chuẩn bị**
- Chạy với quyền **Administrator** (khuyến nghị)
- Đảm bảo có kết nối internet ổn định
- Có ít nhất **8GB RAM** và **20GB disk trống**

### **Bước 2: Chạy cài đặt**

#### **Phương pháp đơn giản nhất:**
```cmd
install-deps.bat
```

#### **Cài đặt với tools tùy chọn:**
```cmd
install-deps.bat -InstallOptional
```

#### **Cài đặt nhanh (cơ bản):**
```cmd
quick-install.bat
```

### **Bước 3: Kiểm tra cài đặt**
```cmd
check-install.bat
```

### **Bước 4: Restart terminal**
Để PATH changes có hiệu lực

## 🛠️ Các công cụ được cài đặt

### **Core Tools (Bắt buộc)**
- Chocolatey, Git, Python, Node.js

### **Compilers**
- Visual Studio Build Tools (MSVC)
- MinGW-w64 (GCC)
- Clang/LLVM

### **Build Tools**
- CMake, Ninja, Make, MSBuild

### **Package Managers**
- Conan, vcpkg

### **Development Tools (Tùy chọn)**
- VS Code, Notepad++, 7-Zip, WinMerge

### **Debugging Tools (Tùy chọn)**
- GDB, Valgrind

### **Testing Frameworks (Tùy chọn)**
- Google Test, Catch2

### **Documentation Tools (Tùy chọn)**
- Doxygen, Graphviz

## ⚡ Tham số nhanh

```cmd
# Cài đặt cơ bản
install-deps.bat

# Cài đặt tất cả tools (bao gồm tùy chọn)
install-deps.bat -InstallOptional

# Bỏ qua kiểm tra sau cài đặt
install-deps.bat -SkipTests

# Hiển thị thông tin chi tiết
install-deps.bat -Verbose

# Bắt buộc cài đặt tất cả
install-deps.bat -Force
```

## 🔍 Troubleshooting nhanh

### **Lỗi thường gặp:**
1. **"Execution Policy" error** → Chạy `fix-execution-policy.bat` hoặc chạy với Administrator
2. **Chocolatey không cài được** → Kiểm tra internet, tắt antivirus tạm thời
3. **Visual Studio lỗi** → Đảm bảo đủ disk space, Windows Update

### **Kiểm tra nhanh:**
```cmd
# Kiểm tra các tools cơ bản
git --version
python --version
cmake --version

# Kiểm tra compilers
gcc --version
clang --version
```

## 📞 Hỗ trợ nhanh

- **Kiểm tra cài đặt:** `check-install.bat`
- **Xem log lỗi:** Chạy script và đọc output
- **Restart terminal:** Sau khi cài đặt xong
- **Kiểm tra PATH:** Đảm bảo các tools có thể chạy từ bất kỳ đâu

## 🎯 Mục tiêu

Sau khi cài đặt xong, bạn sẽ có:
- ✅ Môi trường C/C++ hoàn chỉnh
- ✅ Nhiều compilers (MSVC, GCC, Clang)
- ✅ Build systems (CMake, Ninja, Make)
- ✅ Package managers (Conan, vcpkg)
- ✅ Development tools (VS Code, debuggers)
- ✅ Testing frameworks
- ✅ Documentation tools

**Bạn có thể bắt đầu phát triển C/C++ ngay lập tức!** 🚀
