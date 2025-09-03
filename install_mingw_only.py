#!/usr/bin/env python3
"""
Script đơn giản để cài đặt MinGW packages trong MSYS2
Giải quyết vấn đề "target not found"
"""

import os
import sys
import subprocess
import time

class MinGWInstaller:
    def __init__(self):
        self.msys2_path = self.find_msys2()

    def run_command(self, command, shell=True, check=True):
        """Chạy command với error handling"""
        try:
            print(f"Đang chạy: {command}")
            result = subprocess.run(command, shell=shell, check=check,
                                  capture_output=True, text=True)
            if result.stdout:
                print(result.stdout)
            return result
        except subprocess.CalledProcessError as e:
            print(f"Lỗi khi chạy command: {e}")
            print(f"Stderr: {e.stderr}")
            raise

    def find_msys2(self):
        """Tìm MSYS2 installation"""
        msys2_paths = [
            "C:\\msys64",
            "C:\\msys2",
            "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2"
        ]

        for path in msys2_paths:
            bash_exe = os.path.join(path, "usr", "bin", "bash.exe")
            if os.path.exists(bash_exe):
                print(f"✅ Tìm thấy MSYS2 tại: {path}")
                return path

        print("❌ Không tìm thấy MSYS2")
        return None

    def initialize_msys2(self):
        """Khởi tạo MSYS2 hoàn toàn"""
        if not self.msys2_path:
            return False

        print("=== KHỞI TẠO MSYS2 ===")
        bash_exe = os.path.join(self.msys2_path, "usr", "bin", "bash.exe")

        try:
            # 1. Initialize pacman keyring
            print("1. Khởi tạo pacman keyring...")
            key_init_cmd = f'"{bash_exe}" -lc "pacman-key --init"'
            result = self.run_command(key_init_cmd, check=False)
            if result.returncode != 0:
                print("⚠️ Keyring init failed, trying alternative...")

            # 2. Populate keyring
            print("2. Populate keyring...")
            key_populate_cmd = f'"{bash_exe}" -lc "pacman-key --populate msys2"'
            result = self.run_command(key_populate_cmd, check=False)
            if result.returncode != 0:
                print("⚠️ Keyring populate failed")

            # 3. Update package database
            print("3. Cập nhật package database...")
            for _ in range(3):  # Try up to 3 times
                update_cmd = f'"{bash_exe}" -lc "pacman -Syy --noconfirm"'
                result = self.run_command(update_cmd, check=False)
                if result.returncode == 0:
                    print("✅ Database updated successfully")
                    break
                else:
                    print(f"⚠️ Database update attempt failed, retrying...")
                    time.sleep(2)

            # 4. Upgrade core packages
            print("4. Upgrade core packages...")
            upgrade_cmd = f'"{bash_exe}" -lc "pacman -Suu --noconfirm"'
            result = self.run_command(upgrade_cmd, check=False)
            if result.returncode != 0:
                print("⚠️ Core upgrade failed, continuing...")

            # 5. Test pacman
            print("5. Test pacman...")
            test_cmd = f'"{bash_exe}" -lc "pacman --version"'
            result = self.run_command(test_cmd, check=False)
            if result.returncode == 0:
                print("✅ Pacman hoạt động tốt")
                return True
            else:
                print("❌ Pacman vẫn có vấn đề")
                return False

        except Exception as e:
            print(f"❌ Lỗi khi khởi tạo MSYS2: {e}")
            return False

    def list_available_packages(self):
        """List available MinGW packages"""
        if not self.msys2_path:
            return []

        print("=== LIST AVAILABLE PACKAGES ===")
        bash_exe = os.path.join(self.msys2_path, "usr", "bin", "bash.exe")

        try:
            search_cmd = f'"{bash_exe}" -lc "pacman -Ss mingw-w64-x86_64-gcc | head -10"'
            result = self.run_command(search_cmd, check=False)

            if result.returncode == 0 and result.stdout:
                print("Available packages:")
                print(result.stdout)
                return True
            else:
                print("❌ Không thể list packages")
                return False

        except Exception as e:
            print(f"❌ Lỗi khi list packages: {e}")
            return False

    def install_basic_packages(self):
        """Cài đặt basic MinGW packages từng cái một"""
        if not self.msys2_path:
            return False

        print("=== CÀI ĐẶT BASIC MINGW PACKAGES ===")
        bash_exe = os.path.join(self.msys2_path, "usr", "bin", "bash.exe")

        basic_packages = [
            "mingw-w64-x86_64-gcc",
            "mingw-w64-x86_64-g++",
            "mingw-w64-x86_64-gdb",
            "mingw-w64-x86_64-make"
        ]

        installed = 0
        for package in basic_packages:
            print(f"Cài đặt {package}...")

            # Try multiple times with different approaches
            success = False

            # Method 1: Standard install
            try:
                install_cmd = f'"{bash_exe}" -lc "pacman -S --noconfirm --needed {package}"'
                result = self.run_command(install_cmd, check=False, timeout=300)

                if result.returncode == 0:
                    print(f"✅ {package} installed successfully")
                    installed += 1
                    success = True
                else:
                    print(f"⚠️ Method 1 failed for {package}")

            except Exception as e:
                print(f"⚠️ Method 1 error for {package}: {e}")

            # Method 2: Force install if method 1 failed
            if not success:
                try:
                    print(f"Thử method 2 cho {package}...")
                    force_cmd = f'"{bash_exe}" -lc "pacman -S --noconfirm --overwrite \\* {package}"'
                    result = self.run_command(force_cmd, check=False, timeout=300)

                    if result.returncode == 0:
                        print(f"✅ {package} installed with method 2")
                        installed += 1
                        success = True
                    else:
                        print(f"⚠️ Method 2 also failed for {package}")

                except Exception as e:
                    print(f"⚠️ Method 2 error for {package}: {e}")

            if not success:
                print(f"❌ Không thể cài đặt {package}")

        print(f"Đã cài đặt thành công {installed}/{len(basic_packages)} packages")
        return installed > 0

    def setup_path(self):
        """Setup PATH environment"""
        if not self.msys2_path:
            return

        print("=== SETUP PATH ===")

        msys2_bin = os.path.join(self.msys2_path, "usr", "bin")
        mingw64_bin = os.path.join(self.msys2_path, "mingw64", "bin")

        current_path = os.environ.get('PATH', '')

        if os.path.exists(msys2_bin) and msys2_bin not in current_path:
            current_path = f"{msys2_bin};{current_path}"
            print(f"✅ Added MSYS2 bin to PATH: {msys2_bin}")

        if os.path.exists(mingw64_bin) and mingw64_bin not in current_path:
            current_path = f"{mingw64_bin};{current_path}"
            print(f"✅ Added MinGW64 bin to PATH: {mingw64_bin}")

        os.environ['PATH'] = current_path

    def test_installation(self):
        """Test MinGW installation"""
        print("=== TEST INSTALLATION ===")

        # Test GCC
        try:
            result = subprocess.run(['gcc', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                version = result.stdout.split('\n')[0][:50]
                print(f"✅ GCC: {version}")
            else:
                print("❌ GCC test failed")
        except:
            print("❌ GCC not found in PATH")

        # Test G++
        try:
            result = subprocess.run(['g++', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                version = result.stdout.split('\n')[0][:50]
                print(f"✅ G++: {version}")
            else:
                print("❌ G++ test failed")
        except:
            print("❌ G++ not found in PATH")

        # Test Make
        try:
            result = subprocess.run(['mingw32-make', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                version = result.stdout.split('\n')[0][:30]
                print(f"✅ Make: {version}")
            else:
                print("❌ Make test failed")
        except:
            print("❌ Make not found in PATH")

    def create_test_program(self):
        """Create and compile a test program"""
        print("=== CREATE TEST PROGRAM ===")

        test_code = '''
#include <stdio.h>
#include <windows.h>

int main() {
    printf("Hello from MinGW GCC!\\n");
    printf("Windows version: %d.%d\\n", LOBYTE(GetVersion()), HIBYTE(GetVersion()));
    return 0;
}
'''

        try:
            # Write test file
            with open('mingw_test.c', 'w') as f:
                f.write(test_code)
            print("✅ Created test program: mingw_test.c")

            # Compile
            result = subprocess.run(['gcc', 'mingw_test.c', '-o', 'mingw_test.exe'],
                                  capture_output=True, text=True)

            if result.returncode == 0:
                print("✅ Compilation successful")

                # Run
                result = subprocess.run(['mingw_test.exe'], capture_output=True, text=True)
                if result.returncode == 0:
                    print("✅ Program runs successfully!")
                    print("MinGW installation is working!")
                else:
                    print("⚠️ Compilation successful but execution failed")
            else:
                print("❌ Compilation failed")
                if result.stderr:
                    print(f"   Error: {result.stderr[:200]}...")

        except Exception as e:
            print(f"❌ Test failed: {e}")

        finally:
            # Cleanup
            try:
                if os.path.exists('mingw_test.c'):
                    os.remove('mingw_test.c')
                if os.path.exists('mingw_test.exe'):
                    os.remove('mingw_test.exe')
            except:
                pass

    def run_installation(self):
        """Run the complete installation"""
        print("🔧 MINGW INSTALLER")
        print("=" * 30)

        if not self.msys2_path:
            print("❌ MSYS2 not found. Please install MSYS2 first.")
            print("Download from: https://www.msys2.org/")
            return False

        # Initialize MSYS2
        if not self.initialize_msys2():
            print("❌ Failed to initialize MSYS2")
            return False

        # List available packages
        self.list_available_packages()

        # Install basic packages
        if not self.install_basic_packages():
            print("❌ Failed to install basic MinGW packages")
            return False

        # Setup PATH
        self.setup_path()

        # Test installation
        self.test_installation()

        # Create test program
        self.create_test_program()

        print("\n🎉 INSTALLATION COMPLETE!")
        print("Please restart your terminal/command prompt for PATH changes to take effect.")

        return True

def main():
    if sys.platform != 'win32':
        print("❌ This script is for Windows only")
        return

    installer = MinGWInstaller()
    success = installer.run_installation()

    if not success:
        print("\n❌ Installation failed. Try running as Administrator.")
        print("Or manually install MSYS2 and run:")
        print("pacman -Syu")
        print("pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-g++ mingw-w64-x86_64-gdb mingw-w64-x86_64-make")

if __name__ == "__main__":
    main()
