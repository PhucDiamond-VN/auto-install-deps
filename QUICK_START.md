# 🚀 Hướng dẫn nhanh

## Bước 1: Cài đặt Python dependencies
```bash
pip install -r requirements.txt
```

## Bước 2: Chạy script cài đặt
```bash
# Sử dụng Python trực tiếp
python auto_install_deps.py

# Hoặc sử dụng script batch
run_installer.bat

# Hoặc sử dụng PowerShell
.\run_installer.ps1
```

## Bước 3: Thiết lập environment
```bash
setup_env.bat
```

## Bước 4: Test cài đặt
```bash
test_compilation.bat
```

## Bước 5: Compile project C++
```bash
# Sử dụng GCC
g++ -o program.exe source.cpp

# Sử dụng CMake
mkdir build && cd build
cmake ..
cmake --build .
```

## 📁 Files quan trọng

- `auto_install_deps.py` - Script Python chính
- `deps_config.json` - File cấu hình
- `run_installer.bat` - Script batch để chạy
- `run_installer.ps1` - Script PowerShell
- `setup_env.bat` - Thiết lập environment (được tạo tự động)
- `test_compilation.bat` - Test compilation

## ⚠️ Lưu ý

- Chạy với quyền Administrator để cập nhật PATH
- Cần kết nối internet để download tools
- Quá trình cài đặt có thể mất 10-30 phút tùy thuộc vào tốc độ mạng

## 🆘 Gặp vấn đề?

1. Kiểm tra Python đã được cài đặt
2. Chạy với quyền Administrator
3. Kiểm tra kết nối internet
4. Xem README.md để biết thêm chi tiết
