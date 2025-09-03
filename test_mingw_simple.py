#!/usr/bin/env python3
"""
Test script đơn giản để kiểm tra MinGW installation
"""

import os
import sys
import subprocess

def test_mingw():
    """Test MinGW installation"""
    print("🧪 MINWG TEST")
    print("=" * 20)

    if sys.platform != 'win32':
        print("❌ This script is for Windows only")
        return

    # Find MSYS2
    msys2_paths = ["C:\\msys64", "C:\\msys2"]

    msys2_path = None
    for path in msys2_paths:
        if os.path.exists(os.path.join(path, "usr", "bin", "bash.exe")):
            msys2_path = path
            break

    if not msys2_path:
        print("❌ MSYS2 not found")
        return

    print(f"Found MSYS2 at: {msys2_path}")

    # Test pacman
    bash_exe = os.path.join(msys2_path, "usr", "bin", "bash.exe")
    try:
        result = subprocess.run([bash_exe, "-lc", "pacman --version"], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ Pacman works")
        else:
            print("❌ Pacman has issues")
            return
    except:
        print("❌ Cannot run pacman")
        return

    # Check MinGW packages
    packages_to_check = ["mingw-w64-x86_64-gcc", "mingw-w64-x86_64-g++", "mingw-w64-x86_64-gdb", "mingw-w64-x86_64-make"]

    for package in packages_to_check:
        try:
            result = subprocess.run([bash_exe, "-lc", f"pacman -Q {package}"], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                print(f"✅ {package} is installed")
            else:
                print(f"❌ {package} is NOT installed")
        except:
            print(f"⚠️ Cannot check {package}")

    # Test PATH
    mingw_bin = os.path.join(msys2_path, "mingw64", "bin")
    current_path = os.environ.get('PATH', '')

    if mingw_bin in current_path:
        print("✅ MinGW bin is in PATH")
    else:
        print("❌ MinGW bin is NOT in PATH")

    # Test GCC binary
    gcc_path = os.path.join(mingw_bin, "gcc.exe")
    if os.path.exists(gcc_path):
        print("✅ GCC binary exists")

        # Test compilation
        test_code = '''
#include <stdio.h>
int main() { printf("Hello MinGW!\\n"); return 0; }
'''

        try:
            with open('test.c', 'w') as f:
                f.write(test_code)

            result = subprocess.run([gcc_path, 'test.c', '-o', 'test.exe'], capture_output=True, text=True, timeout=30)

            if result.returncode == 0:
                print("✅ GCC can compile")

                # Test execution
                result = subprocess.run(['test.exe'], capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print("✅ Compiled program runs")
                else:
                    print("⚠️ Program compiles but doesn't run")

            else:
                print("❌ GCC compilation failed")
                if result.stderr:
                    print(f"   Error: {result.stderr[:100]}...")

        except Exception as e:
            print(f"❌ Test failed: {e}")

        finally:
            # Cleanup
            for f in ['test.c', 'test.exe']:
                try:
                    if os.path.exists(f):
                        os.remove(f)
                except:
                    pass

    else:
        print("❌ GCC binary does not exist")

    print("\n" + "=" * 20)
    print("Test complete!")

def main():
    test_mingw()

if __name__ == "__main__":
    main()
