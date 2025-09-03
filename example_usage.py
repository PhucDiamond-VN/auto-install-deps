#!/usr/bin/env python3
"""
Ví dụ sử dụng Auto C/C++ Dependencies Installer
"""

import sys
import os
from pathlib import Path

# Thêm thư mục hiện tại vào Python path
sys.path.insert(0, str(Path(__file__).parent))

from auto_install_cpp_deps import CppDepsInstaller

def example_basic_usage():
    """Ví dụ sử dụng cơ bản"""
    print("=== VÍ DỤ SỬ DỤNG CƠ BẢN ===")
    
    # Tạo instance installer
    installer = CppDepsInstaller()
    
    # Chạy cài đặt đầy đủ
    installer.run_full_installation()

def example_custom_installation():
    """Ví dụ cài đặt tùy chỉnh"""
    print("=== VÍ DỤ CÀI ĐẶT TỰY CHỈNH ===")
    
    installer = CppDepsInstaller()
    
    try:
        # Tạo thư mục cài đặt
        installer.install_dir.mkdir(parents=True, exist_ok=True)
        
        print("1. Cài đặt compiler...")
        installer.install_compiler()
        
        print("2. Cài đặt CMake...")
        installer.install_cmake()
        
        print("3. Cài đặt Ninja...")
        installer.install_ninja()
        
        print("4. Cài đặt vcpkg...")
        installer.install_vcpkg()
        
        print("5. Kiểm tra cài đặt...")
        success = installer.verify_installation()
        
        if success:
            print("✅ Cài đặt thành công!")
        else:
            print("⚠️ Một số công cụ chưa được cài đặt đầy đủ")
            
    except Exception as e:
        print(f"❌ Lỗi: {e}")
    finally:
        installer.cleanup()

def example_verification_only():
    """Ví dụ chỉ kiểm tra cài đặt"""
    print("=== VÍ DỤ KIỂM TRA CÀI ĐẶT ===")
    
    installer = CppDepsInstaller()
    
    # Chỉ kiểm tra các công cụ đã cài đặt
    success = installer.verify_installation()
    
    if success:
        print("✅ Tất cả công cụ đã được cài đặt và sẵn sàng sử dụng!")
    else:
        print("⚠️ Một số công cụ chưa được cài đặt hoặc không tìm thấy")
        print("Chạy cài đặt đầy đủ bằng: python auto_install_cpp_deps.py")

def example_specific_tools():
    """Ví dụ cài đặt công cụ cụ thể"""
    print("=== VÍ DỤ CÀI ĐẶT CÔNG CỤ CỤ THỂ ===")
    
    installer = CppDepsInstaller()
    
    try:
        installer.install_dir.mkdir(parents=True, exist_ok=True)
        
        # Menu lựa chọn
        print("Chọn công cụ muốn cài đặt:")
        print("1. Chỉ cài đặt CMake")
        print("2. Chỉ cài đặt Ninja")
        print("3. Chỉ cài đặt vcpkg")
        print("4. Chỉ cài đặt Conan")
        print("5. Cài đặt tất cả")
        
        choice = input("Nhập lựa chọn (1-5): ").strip()
        
        if choice == '1':
            print("Cài đặt CMake...")
            installer.install_cmake()
        elif choice == '2':
            print("Cài đặt Ninja...")
            installer.install_ninja()
        elif choice == '3':
            print("Cài đặt vcpkg...")
            installer.install_vcpkg()
        elif choice == '4':
            print("Cài đặt Conan...")
            installer.install_conan()
        elif choice == '5':
            print("Cài đặt tất cả...")
            installer.run_full_installation()
        else:
            print("Lựa chọn không hợp lệ!")
            return
        
        # Kiểm tra kết quả
        installer.verify_installation()
        
    except Exception as e:
        print(f"❌ Lỗi: {e}")
    finally:
        installer.cleanup()

def show_system_info():
    """Hiển thị thông tin hệ thống"""
    print("=== THÔNG TIN HỆ THỐNG ===")
    
    installer = CppDepsInstaller()
    
    print(f"Hệ điều hành: {installer.system}")
    print(f"Kiến trúc: {installer.architecture}")
    print(f"Quyền admin: {installer.is_admin}")
    print(f"Thư mục cài đặt: {installer.install_dir}")
    print(f"Thư mục tạm: {installer.temp_dir}")
    
    # Kiểm tra các công cụ có sẵn
    print("\nCác công cụ có sẵn:")
    tools = ['python', 'pip', 'git', 'gcc', 'g++', 'cmake', 'ninja', 'vcpkg', 'conan']
    if installer.system == 'windows':
        tools.extend(['cl', 'msbuild', 'mingw32-make', 'gdb'])
    
    for tool in tools:
        if installer.run_command(f'which {tool}' if installer.system != 'windows' else f'where {tool}', check=False).returncode == 0:
            print(f"✅ {tool}")
        else:
            print(f"❌ {tool}")

def interactive_menu():
    """Menu tương tác"""
    while True:
        print("\n" + "="*50)
        print("🔧 AUTO C/C++ DEPENDENCIES INSTALLER 🔧")
        print("="*50)
        print("1. Cài đặt đầy đủ tất cả dependencies")
        print("2. Cài đặt tùy chỉnh")
        print("3. Chỉ kiểm tra cài đặt")
        print("4. Cài đặt công cụ cụ thể")
        print("5. Hiển thị thông tin hệ thống")
        print("6. Thoát")
        print("="*50)
        
        choice = input("Nhập lựa chọn (1-6): ").strip()
        
        if choice == '1':
            example_basic_usage()
        elif choice == '2':
            example_custom_installation()
        elif choice == '3':
            example_verification_only()
        elif choice == '4':
            example_specific_tools()
        elif choice == '5':
            show_system_info()
        elif choice == '6':
            print("👋 Tạm biệt!")
            break
        else:
            print("❌ Lựa chọn không hợp lệ!")
        
        input("\nNhấn Enter để tiếp tục...")

def main():
    """Hàm chính"""
    if len(sys.argv) > 1:
        if sys.argv[1] in ['-h', '--help']:
            print("""
Ví dụ sử dụng Auto C/C++ Dependencies Installer

Cách sử dụng:
    python example_usage.py [option]

Options:
    -h, --help      Hiển thị trợ giúp này
    --basic         Chạy ví dụ cài đặt cơ bản
    --custom        Chạy ví dụ cài đặt tùy chỉnh
    --verify        Chỉ kiểm tra cài đặt
    --specific      Cài đặt công cụ cụ thể
    --info          Hiển thị thông tin hệ thống
    --interactive   Chạy menu tương tác (mặc định)

Ví dụ:
    python example_usage.py --basic
    python example_usage.py --verify
    python example_usage.py --interactive
            """)
            return
        elif sys.argv[1] == '--basic':
            example_basic_usage()
            return
        elif sys.argv[1] == '--custom':
            example_custom_installation()
            return
        elif sys.argv[1] == '--verify':
            example_verification_only()
            return
        elif sys.argv[1] == '--specific':
            example_specific_tools()
            return
        elif sys.argv[1] == '--info':
            show_system_info()
            return
    
    # Mặc định chạy menu tương tác
    interactive_menu()

if __name__ == "__main__":
    main()
