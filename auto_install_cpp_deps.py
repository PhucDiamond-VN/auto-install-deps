#!/usr/bin/env python3
"""
Auto C/C++ Dependencies Installer
Tự động tải và cài đặt tất cả dependencies cần thiết cho C/C++ development
Hỗ trợ Windows, Linux, và macOS
"""

import os
import sys
import subprocess
import platform
import urllib.request
import zipfile
import tarfile
import json
import tempfile
import shutil
from pathlib import Path
import winreg
import logging

# Cấu hình logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class CppDepsInstaller:
    def __init__(self):
        self.system = platform.system().lower()
        self.architecture = platform.machine().lower()
        self.is_admin = self.check_admin_privileges()
        self.temp_dir = tempfile.mkdtemp()
        self.install_dir = self.get_install_directory()
        
        # URLs cho các công cụ
        self.tools_urls = {
            'cmake': {
                'windows': 'https://github.com/Kitware/CMake/releases/latest/download/cmake-3.28.1-windows-x86_64.zip',
                'linux': 'https://github.com/Kitware/CMake/releases/latest/download/cmake-3.28.1-linux-x86_64.tar.gz',
                'darwin': 'https://github.com/Kitware/CMake/releases/latest/download/cmake-3.28.1-macos-universal.tar.gz'
            },
            'ninja': {
                'windows': 'https://github.com/ninja-build/ninja/releases/latest/download/ninja-win.zip',
                'linux': 'https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip',
                'darwin': 'https://github.com/ninja-build/ninja/releases/latest/download/ninja-mac.zip'
            },
            'vcpkg': {
                'all': 'https://github.com/Microsoft/vcpkg.git'
            }
        }

    def check_admin_privileges(self):
        """Kiểm tra quyền admin/root"""
        try:
            if self.system == 'windows':
                import ctypes
                return ctypes.windll.shell32.IsUserAnAdmin()
            else:
                return os.geteuid() == 0
        except:
            return False

    def get_install_directory(self):
        """Lấy thư mục cài đặt phù hợp"""
        if self.system == 'windows':
            return Path(os.environ.get('PROGRAMFILES', 'C:\\Program Files')) / 'CppDeps'
        else:
            return Path('/usr/local') if self.is_admin else Path.home() / '.local'

    def run_command(self, command, shell=True, check=True):
        """Chạy command với error handling"""
        try:
            logger.info(f"Đang chạy: {command}")
            result = subprocess.run(command, shell=shell, check=check, 
                                  capture_output=True, text=True)
            if result.stdout:
                logger.info(result.stdout)
            return result
        except subprocess.CalledProcessError as e:
            logger.error(f"Lỗi khi chạy command: {e}")
            logger.error(f"Stderr: {e.stderr}")
            raise

    def download_file(self, url, dest_path):
        """Tải file từ URL"""
        logger.info(f"Đang tải xuống: {url}")
        try:
            urllib.request.urlretrieve(url, dest_path)
            logger.info(f"Đã tải xuống: {dest_path}")
            return True
        except Exception as e:
            logger.error(f"Lỗi khi tải xuống {url}: {e}")
            return False

    def extract_archive(self, archive_path, extract_to):
        """Giải nén file archive"""
        logger.info(f"Đang giải nén: {archive_path}")
        try:
            if archive_path.endswith('.zip'):
                with zipfile.ZipFile(archive_path, 'r') as zip_ref:
                    zip_ref.extractall(extract_to)
            elif archive_path.endswith(('.tar.gz', '.tgz')):
                with tarfile.open(archive_path, 'r:gz') as tar_ref:
                    tar_ref.extractall(extract_to)
            logger.info(f"Đã giải nén thành công")
            return True
        except Exception as e:
            logger.error(f"Lỗi khi giải nén: {e}")
            return False

    def install_compiler(self):
        """Cài đặt compiler phù hợp với hệ điều hành"""
        logger.info("Đang cài đặt compiler...")
        
        if self.system == 'windows':
            self.install_windows_compiler()
        elif self.system == 'linux':
            self.install_linux_compiler()
        elif self.system == 'darwin':
            self.install_macos_compiler()

    def install_windows_compiler(self):
        """Cài đặt compiler trên Windows"""
        logger.info("Cài đặt Visual Studio Build Tools, MSBuild và MSYS2...")

        # Tải và cài đặt Visual Studio Build Tools với MSBuild và MSYS2
        vs_installer_url = "https://aka.ms/vs/17/release/vs_buildtools.exe"
        vs_installer_path = Path(self.temp_dir) / "vs_buildtools.exe"

        if self.download_file(vs_installer_url, vs_installer_path):
            # Cài đặt với các component cần thiết bao gồm MSBuild, MSYS2 và Windows SDK
            install_cmd = f'"{vs_installer_path}" --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.MSBuild.Base --add Microsoft.Component.MSBuild --add MSYS2.MSYS2 --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.Windows11SDK.22621'
            try:
                self.run_command(install_cmd)
                logger.info("Đã cài đặt Visual Studio Build Tools với MSBuild và MSYS2")

                # Cấu hình MSBuild PATH
                self.setup_msbuild_path()

                # Cấu hình MSYS2 PATH
                self.setup_msys2_path()

                # Cấu hình Windows SDK PATH và environment
                self.setup_windows_sdk_path()

            except:
                logger.warning("Không thể cài đặt VS Build Tools tự động")
                # Thử cài đặt MSBuild standalone
                self.install_msbuild_standalone()

        # Cài đặt MSYS2 và MinGW nếu chưa có từ VS Build Tools
        if not self.detect_existing_msys2():
            logger.info("MSYS2 chưa được cài đặt, tiến hành cài đặt...")
            self.install_msys2()
        else:
            logger.info("MSYS2 đã được cài đặt, kiểm tra MinGW packages...")
            # Đảm bảo MinGW packages được cài đặt
            self.ensure_mingw_packages()

        # Đảm bảo Windows SDK được cài đặt (Windows only)
        if self.system == 'windows':
            if not self.setup_windows_sdk_path():
                logger.info("Cài đặt Windows SDK standalone...")
                self.install_windows_sdk_standalone()

    def install_msys2(self):
        """Cài đặt MSYS2"""
        logger.info("Cài đặt MSYS2...")
        msys2_url = "https://github.com/msys2/msys2-installer/releases/latest/download/msys2-x86_64-latest.exe"
        msys2_installer = Path(self.temp_dir) / "msys2-installer.exe"
        
        if self.download_file(msys2_url, msys2_installer):
            try:
                # Cài đặt MSYS2 silent
                self.run_command(f'"{msys2_installer}" --confirm-command --accept-messages --root C:\\msys64')
                
                # Cập nhật và cài đặt các package cần thiết
                msys2_cmd = 'C:\\msys64\\usr\\bin\\bash.exe -lc'
                commands = [
                    f'{msys2_cmd} "pacman -Syu --noconfirm"',
                    f'{msys2_cmd} "pacman -S --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-make"',
                    f'{msys2_cmd} "pacman -S --noconfirm mingw-w64-x86_64-cmake mingw-w64-x86_64-ninja"'
                ]
                
                for cmd in commands:
                    try:
                        self.run_command(cmd)
                    except:
                        logger.warning(f"Lỗi khi chạy: {cmd}")
                        
                logger.info("Đã cài đặt MSYS2 và GCC")
            except Exception as e:
                logger.error(f"Lỗi khi cài đặt MSYS2: {e}")

    def setup_msbuild_path(self):
        """Cấu hình MSBuild PATH sau khi cài đặt Visual Studio Build Tools"""
        logger.info("Cấu hình MSBuild PATH...")
        
        # Các đường dẫn có thể có của MSBuild
        possible_msbuild_paths = [
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin",
            "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin",
            "C:\\Program Files\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin",
            "C:\\Program Files (x86)\\MSBuild\\Current\\Bin",
            "C:\\Program Files\\MSBuild\\Current\\Bin"
        ]
        
        for msbuild_path in possible_msbuild_paths:
            msbuild_exe = Path(msbuild_path) / "MSBuild.exe"
            if msbuild_exe.exists():
                logger.info(f"Tìm thấy MSBuild tại: {msbuild_path}")
                self.add_to_path(msbuild_path)
                
                # Thiết lập biến môi trường MSBuildPath
                self.set_environment_variable('MSBuildPath', msbuild_path)
                
                # Kiểm tra phiên bản
                try:
                    result = self.run_command(f'"{msbuild_exe}" -version', check=False)
                    if result.returncode == 0:
                        logger.info("MSBuild đã được cấu hình thành công")
                        return True
                except:
                    pass
                break
        
        logger.warning("Không tìm thấy MSBuild sau khi cài đặt")
        return False

    def install_msbuild_standalone(self):
        """Cài đặt MSBuild standalone nếu Visual Studio Build Tools không khả dụng"""
        logger.info("Cài đặt MSBuild standalone...")
        
        try:
            # Tải MSBuild Tools
            msbuild_tools_url = "https://aka.ms/vs/17/release/vs_buildtools.exe"
            msbuild_installer = Path(self.temp_dir) / "msbuild_tools.exe"
            
            if self.download_file(msbuild_tools_url, msbuild_installer):
                # Cài đặt chỉ MSBuild components
                install_cmd = f'"{msbuild_installer}" --quiet --wait --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Web.Buildtools.ComponentGroup'
                
                try:
                    self.run_command(install_cmd)
                    logger.info("Đã cài đặt MSBuild Tools")
                    
                    # Cấu hình PATH
                    self.setup_msbuild_path()
                    
                except Exception as e:
                    logger.error(f"Lỗi khi cài đặt MSBuild Tools: {e}")
                    # Thử tải MSBuild từ NuGet
                    self.install_msbuild_nuget()
                    
        except Exception as e:
            logger.error(f"Lỗi khi tải MSBuild standalone: {e}")

    def install_msbuild_nuget(self):
        """Cài đặt MSBuild từ NuGet package"""
        logger.info("Cài đặt MSBuild từ NuGet...")
        
        try:
            # Tạo thư mục cho MSBuild
            msbuild_dir = self.install_dir / 'msbuild'
            msbuild_dir.mkdir(parents=True, exist_ok=True)
            
            # Tải NuGet.exe
            nuget_url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
            nuget_exe = msbuild_dir / "nuget.exe"
            
            if self.download_file(nuget_url, nuget_exe):
                # Cài đặt MSBuild package
                install_cmd = f'"{nuget_exe}" install Microsoft.Build -OutputDirectory "{msbuild_dir}" -NonInteractive'
                
                try:
                    self.run_command(install_cmd)
                    
                    # Tìm MSBuild.exe trong package
                    for root, dirs, files in os.walk(msbuild_dir):
                        if 'MSBuild.exe' in files:
                            msbuild_path = Path(root)
                            self.add_to_path(str(msbuild_path))
                            logger.info(f"Đã cài đặt MSBuild từ NuGet tại: {msbuild_path}")
                            return True
                            
                except Exception as e:
                    logger.error(f"Lỗi khi cài đặt MSBuild từ NuGet: {e}")
                    
        except Exception as e:
            logger.error(f"Lỗi khi tải NuGet: {e}")
        
        return False

    def detect_existing_msbuild(self):
        """Phát hiện MSBuild đã có sẵn trên hệ thống"""
        logger.info("Tìm kiếm MSBuild có sẵn...")
        
        # Kiểm tra trong PATH
        if shutil.which('msbuild'):
            logger.info("MSBuild đã có trong PATH")
            return True
        
        # Tìm kiếm trong các thư mục thông thường
        search_paths = [
            "C:\\Program Files (x86)\\Microsoft Visual Studio",
            "C:\\Program Files\\Microsoft Visual Studio",
            "C:\\Program Files (x86)\\MSBuild",
            "C:\\Program Files\\MSBuild",
            "C:\\Windows\\Microsoft.NET\\Framework64",
            "C:\\Windows\\Microsoft.NET\\Framework"
        ]
        
        for base_path in search_paths:
            if os.path.exists(base_path):
                for root, dirs, files in os.walk(base_path):
                    if 'MSBuild.exe' in files:
                        msbuild_path = Path(root)
                        logger.info(f"Tìm thấy MSBuild tại: {msbuild_path}")
                        self.add_to_path(str(msbuild_path))
                        return True
        
        return False

    def setup_msys2_path(self):
        """Cấu hình MSYS2 PATH sau khi cài đặt Visual Studio Build Tools"""
        logger.info("Cấu hình MSYS2 PATH...")

        # Các đường dẫn có thể có của MSYS2
        possible_msys2_paths = [
            "C:\\msys64",
            "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSYS2"
        ]

        msys2_path = None
        for path in possible_msys2_paths:
            if os.path.exists(path):
                msys2_path = path
                logger.info(f"Tìm thấy MSYS2 tại: {msys2_path}")
                break

        if msys2_path:
            # Thêm MSYS2 bin vào PATH
            msys2_bin = os.path.join(msys2_path, "usr", "bin")
            mingw64_bin = os.path.join(msys2_path, "mingw64", "bin")

            if os.path.exists(msys2_bin):
                self.add_to_path(msys2_bin)
                logger.info(f"Đã thêm MSYS2 bin vào PATH: {msys2_bin}")

            if os.path.exists(mingw64_bin):
                self.add_to_path(mingw64_bin)
                logger.info(f"Đã thêm MinGW64 bin vào PATH: {mingw64_bin}")

            # Thiết lập biến môi trường MSYS2
            self.set_environment_variable('MSYS2_ROOT', msys2_path)
            logger.info("Đã cấu hình MSYS2 PATH thành công")
            return True

        logger.warning("Không tìm thấy MSYS2 sau khi cài đặt")
        return False

    def setup_windows_sdk_path(self):
        """Cấu hình Windows SDK PATH và environment variables"""
        logger.info("Cấu hình Windows SDK PATH...")

        # Các đường dẫn có thể có của Windows SDK
        possible_sdk_paths = [
            "C:\\Program Files (x86)\\Windows Kits\\10",
            "C:\\Program Files\\Windows Kits\\10",
            "C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A",
            "C:\\Program Files\\Microsoft SDKs\\Windows\\v10.0A"
        ]

        sdk_base_path = None
        for path in possible_sdk_paths:
            if os.path.exists(path):
                sdk_base_path = path
                logger.info(f"Tìm thấy Windows SDK tại: {sdk_base_path}")
                break

        if sdk_base_path:
            # Tìm thư mục Include và Lib mới nhất
            include_base = os.path.join(sdk_base_path, "Include")
            lib_base = os.path.join(sdk_base_path, "Lib")

            if os.path.exists(include_base):
                # Tìm phiên bản SDK mới nhất
                include_versions = [d for d in os.listdir(include_base) if os.path.isdir(os.path.join(include_base, d))]
                if include_versions:
                    latest_version = sorted(include_versions, reverse=True)[0]
                    include_path = os.path.join(include_base, latest_version, "ucrt")
                    lib_path = os.path.join(lib_base, latest_version, "ucrt", "x64") if os.path.exists(lib_base) else None

                    # Thêm include path vào environment
                    current_include = os.environ.get('INCLUDE', '')
                    if include_path not in current_include:
                        if current_include:
                            new_include = f"{include_path};{current_include}"
                        else:
                            new_include = include_path
                        os.environ['INCLUDE'] = new_include
                        self.set_environment_variable('INCLUDE', new_include)
                        logger.info(f"Đã thêm Windows SDK Include path: {include_path}")

                    # Thêm lib path vào environment
                    if lib_path and os.path.exists(lib_path):
                        current_lib = os.environ.get('LIB', '')
                        if lib_path not in current_lib:
                            if current_lib:
                                new_lib = f"{lib_path};{current_lib}"
                            else:
                                new_lib = lib_path
                            os.environ['LIB'] = new_lib
                            self.set_environment_variable('LIB', new_lib)
                            logger.info(f"Đã thêm Windows SDK Lib path: {lib_path}")

                    # Thiết lập WindowsSDKDir
                    self.set_environment_variable('WindowsSDKDir', sdk_base_path)
                    self.set_environment_variable('WindowsSDKVersion', latest_version + "\\")

                    logger.info("Đã cấu hình Windows SDK environment thành công")
                    return True

        logger.warning("Không tìm thấy Windows SDK sau khi cài đặt")
        return False

    def detect_windows_headers(self):
        """Phát hiện các Windows header files quan trọng"""
        logger.info("Kiểm tra Windows header files...")

        # Các header files quan trọng cần kiểm tra
        important_headers = [
            'windows.h',
            'winuser.h',
            'wingdi.h',
            'winbase.h',
            'winnt.h',
            'winsock2.h',
            'ws2tcpip.h',
            'shlobj.h',
            'shellapi.h'
        ]

        # Tìm thư mục Include của Windows SDK
        sdk_include_paths = [
            "C:\\Program Files (x86)\\Windows Kits\\10\\Include",
            "C:\\Program Files\\Windows Kits\\10\\Include",
            "C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\Include",
            "C:\\Program Files\\Microsoft SDKs\\Windows\\v10.0A\\Include"
        ]

        found_headers = []
        missing_headers = []

        for include_base in sdk_include_paths:
            if os.path.exists(include_base):
                # Tìm thư mục phiên bản mới nhất
                try:
                    versions = [d for d in os.listdir(include_base) if os.path.isdir(os.path.join(include_base, d))]
                    if versions:
                        latest_version = sorted(versions, reverse=True)[0]
                        ucrt_path = os.path.join(include_base, latest_version, "ucrt")
                        um_path = os.path.join(include_base, latest_version, "um")

                        # Kiểm tra từng header
                        for header in important_headers:
                            header_found = False

                            # Tìm trong ucrt
                            if os.path.exists(os.path.join(ucrt_path, header)):
                                found_headers.append(f"{header} (ucrt)")
                                header_found = True

                            # Tìm trong um (User Mode)
                            elif os.path.exists(os.path.join(um_path, header)):
                                found_headers.append(f"{header} (um)")
                                header_found = True

                            if not header_found:
                                missing_headers.append(header)

                        break  # Thoát sau khi tìm thấy phiên bản SDK
                except Exception as e:
                    logger.warning(f"Lỗi khi kiểm tra headers: {e}")
                    continue

        logger.info(f"Tìm thấy {len(found_headers)} Windows headers")
        for header in found_headers:
            logger.info(f"  ✓ {header}")

        if missing_headers:
            logger.warning(f"Thiếu {len(missing_headers)} Windows headers:")
            for header in missing_headers:
                logger.warning(f"  ✗ {header}")

        return len(missing_headers) == 0

    def install_windows_sdk_standalone(self):
        """Cài đặt Windows SDK standalone nếu cần"""
        logger.info("Cài đặt Windows SDK standalone...")

        try:
            # Tải Windows SDK installer
            # Lưu ý: Windows SDK thường được cài đặt qua Visual Studio hoặc Windows Update
            # Đây là một cách tiếp cận khác

            logger.info("Gợi ý: Cài đặt Windows SDK qua Windows Update hoặc Visual Studio Installer")
            logger.info("Hoặc tải từ: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/")

            # Thử cài đặt qua winget (nếu có)
            try:
                self.run_command('winget install --id Microsoft.WindowsSDK.10.0.22621 --accept-package-agreements')
                logger.info("Đã cài đặt Windows SDK qua winget")
                return True
            except:
                logger.warning("Không thể cài đặt Windows SDK qua winget")

            # Thử cài đặt qua chocolatey (nếu có)
            try:
                self.run_command('choco install windows-sdk-10.1 -y')
                logger.info("Đã cài đặt Windows SDK qua chocolatey")
                return True
            except:
                logger.warning("Không thể cài đặt Windows SDK qua chocolatey")

        except Exception as e:
            logger.error(f"Lỗi khi cài đặt Windows SDK: {e}")

        return False

    def setup_vc_compiler_includes(self):
        """Thiết lập include paths cho Visual C++ compiler"""
        logger.info("Thiết lập VC compiler include paths...")

        # Tìm thư mục VC Tools
        vc_base_paths = [
            "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSVC",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSVC",
            "C:\\Program Files\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC"
        ]

        for vc_base in vc_base_paths:
            if os.path.exists(vc_base):
                # Tìm thư mục phiên bản mới nhất
                try:
                    versions = [d for d in os.listdir(vc_base) if os.path.isdir(os.path.join(vc_base, d))]
                    if versions:
                        latest_version = sorted(versions, reverse=True)[0]
                        vc_include = os.path.join(vc_base, latest_version, "include")

                        if os.path.exists(vc_include):
                            # Thêm VC include path
                            current_include = os.environ.get('INCLUDE', '')
                            if vc_include not in current_include:
                                if current_include:
                                    new_include = f"{vc_include};{current_include}"
                                else:
                                    new_include = vc_include
                                os.environ['INCLUDE'] = new_include
                                self.set_environment_variable('INCLUDE', new_include)
                                logger.info(f"Đã thêm VC include path: {vc_include}")
                                return True
                except Exception as e:
                    logger.warning(f"Lỗi khi thiết lập VC includes: {e}")

        logger.warning("Không tìm thấy VC Tools include path")
        return False

    def detect_existing_msys2(self):
        """Phát hiện MSYS2 đã có sẵn trên hệ thống"""
        logger.info("Tìm kiếm MSYS2 có sẵn...")

        # Kiểm tra trong PATH
        if shutil.which('pacman'):
            logger.info("MSYS2 đã có trong PATH")
            return True

        # Tìm kiếm trong các thư mục thông thường
        search_paths = [
            "C:\\msys64",
            "C:\\msys2",
            "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSYS2",
            "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSYS2"
        ]

        for base_path in search_paths:
            if os.path.exists(base_path):
                pacman_path = os.path.join(base_path, "usr", "bin", "pacman.exe")
                bash_path = os.path.join(base_path, "usr", "bin", "bash.exe")

                if os.path.exists(pacman_path) and os.path.exists(bash_path):
                    logger.info(f"Tìm thấy MSYS2 tại: {base_path}")

                    # Kiểm tra xem MSYS2 có hoạt động không
                    try:
                        test_cmd = f'"{pacman_path}" --version'
                        result = self.run_command(test_cmd, check=False)
                        if result.returncode == 0:
                            logger.info("MSYS2 hoạt động tốt")

                            # Thêm vào PATH
                            msys2_bin = os.path.join(base_path, "usr", "bin")
                            mingw64_bin = os.path.join(base_path, "mingw64", "bin")
                            mingw32_bin = os.path.join(base_path, "mingw32", "bin")

                            if os.path.exists(msys2_bin):
                                self.add_to_path(msys2_bin)
                                logger.info(f"Đã thêm MSYS2 bin vào PATH: {msys2_bin}")

                            if os.path.exists(mingw64_bin):
                                self.add_to_path(mingw64_bin)
                                logger.info(f"Đã thêm MinGW64 bin vào PATH: {mingw64_bin}")

                            if os.path.exists(mingw32_bin):
                                self.add_to_path(mingw32_bin)
                                logger.info(f"Đã thêm MinGW32 bin vào PATH: {mingw32_bin}")

                            self.set_environment_variable('MSYS2_ROOT', base_path)
                            return True
                        else:
                            logger.warning(f"MSYS2 tại {base_path} không hoạt động đúng")
                    except Exception as e:
                        logger.warning(f"Lỗi khi kiểm tra MSYS2: {e}")

        logger.info("Không tìm thấy MSYS2 có sẵn")
        return False

    def install_msys2(self):
        """Cài đặt MSYS2 và MinGW packages"""
        logger.info("Cài đặt MSYS2 và MinGW...")

        msys2_url = "https://github.com/msys2/msys2-installer/releases/latest/download/msys2-x86_64-latest.exe"
        msys2_installer = Path(self.temp_dir) / "msys2-installer.exe"

        if self.download_file(msys2_url, msys2_installer):
            try:
                # Cài đặt MSYS2 silent với đường dẫn tùy chỉnh
                msys2_install_path = "C:\\msys64"
                install_cmd = f'"{msys2_installer}" --confirm-command --accept-messages --root "{msys2_install_path}"'

                self.run_command(install_cmd)

                # Cập nhật package database và core packages
                self.update_msys2_packages(msys2_install_path)

                # Cài đặt MinGW packages
                self.install_mingw_packages(msys2_install_path)

                # Sửa chữa MSYS2 sau khi cài đặt
                self.fix_msys2_after_installation(msys2_install_path)

                logger.info("Đã cài đặt MSYS2 và MinGW thành công")

            except Exception as e:
                logger.error(f"Lỗi khi cài đặt MSYS2: {e}")

        else:
            logger.error("Không thể tải xuống MSYS2 installer")

    def initialize_msys2(self, msys2_path):
        """Khởi tạo MSYS2 environment"""
        logger.info("Khởi tạo MSYS2 environment...")

        try:
            bash_exe = os.path.join(msys2_path, "usr", "bin", "bash.exe")
            if not os.path.exists(bash_exe):
                logger.error(f"Không tìm thấy bash.exe tại {bash_exe}")
                return False

            # Khởi tạo keyring
            logger.info("Khởi tạo pacman keyring...")
            try:
                keyring_cmd = f'"{bash_exe}" -lc "pacman-key --init"'
                self.run_command(keyring_cmd, check=False)
            except:
                logger.warning("Không thể khởi tạo keyring, tiếp tục...")

            # Populate keyring
            try:
                populate_cmd = f'"{bash_exe}" -lc "pacman-key --populate msys2"'
                self.run_command(populate_cmd, check=False)
            except:
                logger.warning("Không thể populate keyring, tiếp tục...")

            # Refresh mirrors
            try:
                mirrors_cmd = f'"{bash_exe}" -lc "pacman -Syy"'
                self.run_command(mirrors_cmd, check=False)
            except:
                logger.warning("Không thể refresh mirrors, tiếp tục...")

            logger.info("Đã khởi tạo MSYS2 environment")
            return True

        except Exception as e:
            logger.error(f"Lỗi khi khởi tạo MSYS2: {e}")
            return False

    def update_msys2_packages(self, msys2_path):
        """Cập nhật MSYS2 packages"""
        logger.info("Cập nhật MSYS2 packages...")

        try:
            bash_exe = os.path.join(msys2_path, "usr", "bin", "bash.exe")

            if os.path.exists(bash_exe):
                # Khởi tạo MSYS2 trước
                if not self.initialize_msys2(msys2_path):
                    logger.warning("Khởi tạo MSYS2 thất bại, thử tiếp tục...")

                # Cập nhật package database với force
                logger.info("Cập nhật package database...")
                update_cmd = f'"{bash_exe}" -lc "pacman -Syy --noconfirm"'
                self.run_command(update_cmd, check=False)

                # Upgrade core packages
                logger.info("Nâng cấp core packages...")
                upgrade_cmd = f'"{bash_exe}" -lc "pacman -Syu --noconfirm"'
                self.run_command(upgrade_cmd, check=False)

                logger.info("Đã cập nhật MSYS2 packages")
            else:
                logger.error(f"Không tìm thấy bash.exe tại {bash_exe}")

        except Exception as e:
            logger.error(f"Lỗi khi cập nhật MSYS2 packages: {e}")

    def check_available_packages(self, msys2_path):
        """Kiểm tra packages có sẵn trong MSYS2"""
        logger.info("Kiểm tra packages có sẵn...")

        try:
            bash_exe = os.path.join(msys2_path, "usr", "bin", "bash.exe")
            if not os.path.exists(bash_exe):
                return []

            # Lấy danh sách packages có sẵn
            search_cmd = f'"{bash_exe}" -lc "pacman -Ss mingw-w64-x86_64-gcc | head -20"'
            result = self.run_command(search_cmd, check=False)

            if result.returncode == 0 and result.stdout:
                # Parse output để tìm package names
                lines = result.stdout.split('\n')
                available_packages = []
                for line in lines:
                    if line.startswith('mingw64/'):
                        # Extract package name from line like "mingw64/mingw-w64-x86_64-gcc ..."
                        parts = line.split('/')
                        if len(parts) > 1:
                            package_name = parts[1].split()[0]
                            available_packages.append(package_name)
                return available_packages

        except Exception as e:
            logger.warning(f"Lỗi khi kiểm tra packages: {e}")

        return []

    def install_mingw_packages(self, msys2_path):
        """Cài đặt MinGW packages từ MSYS2"""
        logger.info("Cài đặt MinGW packages...")

        try:
            bash_exe = os.path.join(msys2_path, "usr", "bin", "bash.exe")

            if os.path.exists(bash_exe):
                # Kiểm tra packages có sẵn trước
                available_packages = self.check_available_packages(msys2_path)
                logger.info(f"Tìm thấy {len(available_packages)} packages mẫu")

                # Danh sách MinGW packages cần thiết
                mingw_packages = [
                    "mingw-w64-x86_64-gcc",           # GCC compiler
                    "mingw-w64-x86_64-g++",           # G++ compiler
                    "mingw-w64-x86_64-gdb",           # GNU Debugger
                    "mingw-w64-x86_64-make",          # GNU Make
                    "mingw-w64-x86_64-cmake",         # CMake for MinGW
                    "mingw-w64-x86_64-ninja",         # Ninja build system
                    "mingw-w64-x86_64-pkg-config",    # pkg-config
                    "mingw-w64-x86_64-toolchain",     # Complete toolchain
                    "mingw-w64-x86_64-libtool",       # GNU libtool
                    "mingw-w64-x86_64-autotools",     # Autotools
                ]

                # Thử cài đặt từng package với error handling tốt hơn
                installed_count = 0
                for package in mingw_packages:
                    try:
                        logger.info(f"Cài đặt {package}...")
                        install_cmd = f'"{bash_exe}" -lc "pacman -S --noconfirm --needed {package}"'
                        result = self.run_command(install_cmd, check=False)

                        if result.returncode == 0:
                            logger.info(f"✅ Đã cài đặt {package}")
                            installed_count += 1
                        else:
                            logger.warning(f"⚠️ Không thể cài đặt {package} (exit code: {result.returncode})")
                            if result.stderr:
                                logger.warning(f"   Lỗi: {result.stderr.strip()[:100]}...")

                    except Exception as e:
                        logger.warning(f"Lỗi khi cài đặt {package}: {e}")
                        continue

                # Cài đặt các development libraries bổ sung
                dev_packages = [
                    "mingw-w64-x86_64-zlib",          # zlib library
                    "mingw-w64-x86_64-openssl",       # OpenSSL library
                    "mingw-w64-x86_64-libiconv",      # iconv library
                    "mingw-w64-x86_64-gettext",       # gettext library
                ]

                for package in dev_packages:
                    try:
                        logger.info(f"Cài đặt {package}...")
                        install_cmd = f'"{bash_exe}" -lc "pacman -S --noconfirm --needed {package}"'
                        result = self.run_command(install_cmd, check=False)

                        if result.returncode == 0:
                            logger.info(f"✅ Đã cài đặt {package}")
                            installed_count += 1
                        else:
                            logger.warning(f"⚠️ Không thể cài đặt {package}")

                    except Exception as e:
                        logger.warning(f"Lỗi khi cài đặt {package}: {e}")
                        continue

                logger.info(f"Đã hoàn thành cài đặt MinGW packages ({installed_count} packages)")

            else:
                logger.error(f"Không tìm thấy bash.exe tại {bash_exe}")

        except Exception as e:
            logger.error(f"Lỗi khi cài đặt MinGW packages: {e}")

    def fix_msys2_after_installation(self, msys2_path):
        """Sửa chữa MSYS2 sau khi cài đặt để đảm bảo hoạt động tốt"""
        logger.info("Sửa chữa MSYS2 environment...")

        try:
            bash_exe = os.path.join(msys2_path, "usr", "bin", "bash.exe")

            if os.path.exists(bash_exe):
                # Đảm bảo database được cập nhật
                logger.info("Cập nhật package database...")
                update_cmd = f'"{bash_exe}" -lc "pacman -Sy --noconfirm"'
                self.run_command(update_cmd, check=False)

                # Kiểm tra và sửa chữa nếu cần
                logger.info("Kiểm tra MSYS2 health...")
                check_cmd = f'"{bash_exe}" -lc "pacman -Q"'
                result = self.run_command(check_cmd, check=False)

                if result.returncode == 0:
                    logger.info("MSYS2 hoạt động tốt")
                else:
                    logger.warning("MSYS2 có thể cần sửa chữa")
                    # Thử repair
                    repair_cmd = f'"{bash_exe}" -lc "pacman -Scc --noconfirm"'
                    self.run_command(repair_cmd, check=False)

        except Exception as e:
            logger.error(f"Lỗi khi sửa chữa MSYS2: {e}")

    def ensure_mingw_packages(self):
        """Đảm bảo MinGW packages được cài đặt trong MSYS2 có sẵn"""
        logger.info("Đảm bảo MinGW packages được cài đặt...")

        # Tìm đường dẫn MSYS2
        msys2_paths = [
            'C:\\msys64',
            'C:\\msys2',
            'C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2',
            'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSYS2'
        ]

        msys2_path = None
        for path in msys2_paths:
            if os.path.exists(path) and os.path.exists(os.path.join(path, "usr", "bin", "bash.exe")):
                msys2_path = path
                logger.info(f"Tìm thấy MSYS2 tại: {msys2_path}")
                break

        if msys2_path:
            # Cập nhật MSYS2 packages trước
            self.update_msys2_packages(msys2_path)

            # Cài đặt MinGW packages
            self.install_mingw_packages(msys2_path)

            # Sửa chữa MSYS2
            self.fix_msys2_after_installation(msys2_path)

            # Đảm bảo PATH được cập nhật
            msys2_bin = os.path.join(msys2_path, "usr", "bin")
            mingw64_bin = os.path.join(msys2_path, "mingw64", "bin")

            if os.path.exists(msys2_bin):
                self.add_to_path(msys2_bin)
            if os.path.exists(mingw64_bin):
                self.add_to_path(mingw64_bin)

            self.set_environment_variable('MSYS2_ROOT', msys2_path)
        else:
            logger.warning("Không tìm thấy MSYS2 để cài đặt MinGW packages")

    def install_linux_compiler(self):
        """Cài đặt compiler trên Linux"""
        logger.info("Cài đặt GCC và các công cụ cần thiết trên Linux...")
        
        # Phát hiện package manager
        if shutil.which('apt'):
            # Ubuntu/Debian
            commands = [
                'apt update',
                'apt install -y build-essential gcc g++ gdb make',
                'apt install -y cmake ninja-build',
                'apt install -y git curl wget'
            ]
            for cmd in commands:
                try:
                    self.run_command(f'sudo {cmd}')
                except:
                    logger.warning(f"Lỗi khi chạy: {cmd}")
                    
        elif shutil.which('yum'):
            # CentOS/RHEL/Fedora
            commands = [
                'yum groupinstall -y "Development Tools"',
                'yum install -y gcc gcc-c++ gdb make cmake ninja-build',
                'yum install -y git curl wget'
            ]
            for cmd in commands:
                try:
                    self.run_command(f'sudo {cmd}')
                except:
                    logger.warning(f"Lỗi khi chạy: {cmd}")
                    
        elif shutil.which('pacman'):
            # Arch Linux
            commands = [
                'pacman -Syu --noconfirm',
                'pacman -S --noconfirm base-devel gcc gdb make cmake ninja',
                'pacman -S --noconfirm git curl wget'
            ]
            for cmd in commands:
                try:
                    self.run_command(f'sudo {cmd}')
                except:
                    logger.warning(f"Lỗi khi chạy: {cmd}")

    def install_macos_compiler(self):
        """Cài đặt compiler trên macOS"""
        logger.info("Cài đặt Xcode Command Line Tools và Homebrew...")
        
        # Cài đặt Xcode Command Line Tools
        try:
            self.run_command('xcode-select --install')
        except:
            logger.info("Xcode Command Line Tools có thể đã được cài đặt")
        
        # Cài đặt Homebrew
        if not shutil.which('brew'):
            homebrew_install_script = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            try:
                self.run_command(homebrew_install_script)
            except:
                logger.warning("Không thể cài đặt Homebrew tự động")
        
        # Cài đặt các package cần thiết
        if shutil.which('brew'):
            packages = ['cmake', 'ninja', 'llvm', 'gdb']
            for package in packages:
                try:
                    self.run_command(f'brew install {package}')
                except:
                    logger.warning(f"Không thể cài đặt {package}")

    def install_cmake(self):
        """Cài đặt CMake"""
        logger.info("Cài đặt CMake...")
        
        if self.system in self.tools_urls['cmake']:
            cmake_url = self.tools_urls['cmake'][self.system]
            cmake_archive = Path(self.temp_dir) / f"cmake.{'zip' if self.system == 'windows' else 'tar.gz'}"
            
            if self.download_file(cmake_url, cmake_archive):
                cmake_dir = self.install_dir / 'cmake'
                cmake_dir.mkdir(parents=True, exist_ok=True)
                
                if self.extract_archive(str(cmake_archive), str(cmake_dir)):
                    # Tìm thư mục cmake sau khi giải nén
                    for item in cmake_dir.iterdir():
                        if item.is_dir() and 'cmake' in item.name.lower():
                            cmake_bin = item / 'bin'
                            if cmake_bin.exists():
                                self.add_to_path(str(cmake_bin))
                                logger.info("Đã cài đặt CMake thành công")
                                return True
        
        logger.warning("Không thể cài đặt CMake")
        return False

    def install_ninja(self):
        """Cài đặt Ninja"""
        logger.info("Cài đặt Ninja...")
        
        if self.system in self.tools_urls['ninja']:
            ninja_url = self.tools_urls['ninja'][self.system]
            ninja_archive = Path(self.temp_dir) / "ninja.zip"
            
            if self.download_file(ninja_url, ninja_archive):
                ninja_dir = self.install_dir / 'ninja'
                ninja_dir.mkdir(parents=True, exist_ok=True)
                
                if self.extract_archive(str(ninja_archive), str(ninja_dir)):
                    self.add_to_path(str(ninja_dir))
                    logger.info("Đã cài đặt Ninja thành công")
                    return True
        
        logger.warning("Không thể cài đặt Ninja")
        return False

    def install_vcpkg(self):
        """Cài đặt vcpkg package manager"""
        logger.info("Cài đặt vcpkg...")
        
        vcpkg_dir = self.install_dir / 'vcpkg'
        
        try:
            # Clone vcpkg repository
            self.run_command(f'git clone {self.tools_urls["vcpkg"]["all"]} "{vcpkg_dir}"')
            
            # Build vcpkg
            if self.system == 'windows':
                bootstrap_script = vcpkg_dir / 'bootstrap-vcpkg.bat'
                self.run_command(f'"{bootstrap_script}"')
            else:
                bootstrap_script = vcpkg_dir / 'bootstrap-vcpkg.sh'
                self.run_command(f'chmod +x "{bootstrap_script}" && "{bootstrap_script}"')
            
            # Integrate vcpkg
            vcpkg_exe = vcpkg_dir / ('vcpkg.exe' if self.system == 'windows' else 'vcpkg')
            self.run_command(f'"{vcpkg_exe}" integrate install')
            
            # Add to PATH
            self.add_to_path(str(vcpkg_dir))
            
            # Set environment variable
            self.set_environment_variable('VCPKG_ROOT', str(vcpkg_dir))
            
            logger.info("Đã cài đặt vcpkg thành công")
            return True
            
        except Exception as e:
            logger.error(f"Lỗi khi cài đặt vcpkg: {e}")
            return False

    def install_conan(self):
        """Cài đặt Conan package manager"""
        logger.info("Cài đặt Conan...")
        
        try:
            # Cài đặt Conan qua pip
            self.run_command(f'{sys.executable} -m pip install conan')
            
            # Tạo profile mặc định
            self.run_command('conan profile detect --force')
            
            logger.info("Đã cài đặt Conan thành công")
            return True
            
        except Exception as e:
            logger.error(f"Lỗi khi cài đặt Conan: {e}")
            return False

    def add_to_path(self, path_to_add):
        """Thêm đường dẫn vào PATH environment variable"""
        logger.info(f"Thêm vào PATH: {path_to_add}")
        
        try:
            if self.system == 'windows':
                self.add_to_windows_path(path_to_add)
            else:
                self.add_to_unix_path(path_to_add)
        except Exception as e:
            logger.error(f"Lỗi khi thêm vào PATH: {e}")

    def add_to_windows_path(self, path_to_add):
        """Thêm đường dẫn vào PATH trên Windows"""
        try:
            # Thêm vào User PATH
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 
                               'Environment', 0, winreg.KEY_ALL_ACCESS)
            try:
                current_path, _ = winreg.QueryValueEx(key, 'PATH')
            except FileNotFoundError:
                current_path = ''
            
            if path_to_add not in current_path:
                new_path = f"{current_path};{path_to_add}" if current_path else path_to_add
                winreg.SetValueEx(key, 'PATH', 0, winreg.REG_EXPAND_SZ, new_path)
                logger.info(f"Đã thêm {path_to_add} vào User PATH")
            
            winreg.CloseKey(key)
            
            # Thông báo cho system về thay đổi environment
            import ctypes
            ctypes.windll.user32.SendMessageW(0xFFFF, 0x001A, 0, 'Environment')
            
        except Exception as e:
            logger.error(f"Lỗi khi cập nhật Windows PATH: {e}")

    def add_to_unix_path(self, path_to_add):
        """Thêm đường dẫn vào PATH trên Unix/Linux/macOS"""
        shell_config_files = [
            Path.home() / '.bashrc',
            Path.home() / '.bash_profile',
            Path.home() / '.zshrc',
            Path.home() / '.profile'
        ]
        
        path_export = f'export PATH="{path_to_add}:$PATH"'
        
        for config_file in shell_config_files:
            if config_file.exists():
                try:
                    with open(config_file, 'r') as f:
                        content = f.read()
                    
                    if path_to_add not in content:
                        with open(config_file, 'a') as f:
                            f.write(f'\n# Added by CppDepsInstaller\n{path_export}\n')
                        logger.info(f"Đã thêm PATH vào {config_file}")
                except Exception as e:
                    logger.error(f"Lỗi khi cập nhật {config_file}: {e}")

    def set_environment_variable(self, name, value):
        """Thiết lập environment variable"""
        logger.info(f"Thiết lập biến môi trường: {name}={value}")
        
        if self.system == 'windows':
            try:
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 
                                   'Environment', 0, winreg.KEY_ALL_ACCESS)
                winreg.SetValueEx(key, name, 0, winreg.REG_SZ, value)
                winreg.CloseKey(key)
                
                # Thông báo cho system
                import ctypes
                ctypes.windll.user32.SendMessageW(0xFFFF, 0x001A, 0, 'Environment')
                
            except Exception as e:
                logger.error(f"Lỗi khi thiết lập biến môi trường: {e}")
        else:
            # Unix/Linux/macOS
            shell_config_files = [
                Path.home() / '.bashrc',
                Path.home() / '.bash_profile',
                Path.home() / '.zshrc',
                Path.home() / '.profile'
            ]
            
            env_export = f'export {name}="{value}"'
            
            for config_file in shell_config_files:
                if config_file.exists():
                    try:
                        with open(config_file, 'r') as f:
                            content = f.read()
                        
                        if f'{name}=' not in content:
                            with open(config_file, 'a') as f:
                                f.write(f'\n# Added by CppDepsInstaller\n{env_export}\n')
                    except Exception as e:
                        logger.error(f"Lỗi khi cập nhật {config_file}: {e}")

    def install_additional_tools(self):
        """Cài đặt các công cụ bổ sung"""
        logger.info("Cài đặt các công cụ bổ sung...")
        
        # Cài đặt pkg-config
        if self.system == 'windows':
            # Tải pkg-config cho Windows
            pkgconfig_url = "https://download.gnome.org/binaries/win32/dependencies/pkg-config_0.26-1_win32.zip"
            pkgconfig_archive = Path(self.temp_dir) / "pkg-config.zip"
            
            if self.download_file(pkgconfig_url, pkgconfig_archive):
                pkgconfig_dir = self.install_dir / 'pkg-config'
                pkgconfig_dir.mkdir(parents=True, exist_ok=True)
                
                if self.extract_archive(str(pkgconfig_archive), str(pkgconfig_dir)):
                    self.add_to_path(str(pkgconfig_dir / 'bin'))
        
        # Cài đặt Git (nếu chưa có)
        if not shutil.which('git'):
            if self.system == 'windows':
                git_url = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.42.0.2-64-bit.exe"
                git_installer = Path(self.temp_dir) / "git-installer.exe"
                
                if self.download_file(git_url, git_installer):
                    try:
                        self.run_command(f'"{git_installer}" /VERYSILENT /NORESTART')
                        logger.info("Đã cài đặt Git")
                    except:
                        logger.warning("Không thể cài đặt Git tự động")

    def verify_installation(self):
        """Kiểm tra các công cụ đã được cài đặt"""
        logger.info("Kiểm tra cài đặt...")

        # Hiển thị thông tin debug về PATH
        self.debug_path_info()

        tools_to_check = ['gcc', 'g++', 'cmake', 'ninja', 'git']
        if self.system == 'windows':
            tools_to_check.extend(['cl', 'vcpkg', 'msbuild', 'mingw32-make'])
            logger.info("Kiểm tra Windows development environment...")

        installed_tools = []
        missing_tools = []

        for tool in tools_to_check:
            logger.info(f"Đang kiểm tra {tool}...")
            tool_path = shutil.which(tool)

            if tool_path:
                logger.info(f"  Tìm thấy {tool} tại: {tool_path}")
                try:
                    # Sử dụng command phù hợp cho từng tool
                    version_cmd = self.get_version_command(tool)
                    result = self.run_command(version_cmd, check=False)

                    if result.returncode == 0:
                        installed_tools.append(tool)
                        logger.info(f"✓ {tool} đã được cài đặt")
                        # Hiển thị version info (dòng đầu tiên)
                        version_lines = result.stdout.strip().split('\n')
                        if version_lines:
                            logger.info(f"  Version: {version_lines[0][:100]}...")
                    else:
                        logger.warning(f"  {tool} tồn tại nhưng không thể chạy (return code: {result.returncode})")
                        missing_tools.append(tool)
                except Exception as e:
                    logger.warning(f"  Lỗi khi kiểm tra {tool}: {e}")
                    missing_tools.append(tool)
            else:
                logger.warning(f"  Không tìm thấy {tool} trong PATH")
                # Thử tìm thủ công trong các thư mục thông thường
                manual_path = self.manual_tool_check(tool)
                if manual_path:
                    logger.info(f"  Đã thêm {tool} vào PATH từ: {manual_path}")
                    # Thử kiểm tra lại sau khi thêm vào PATH
                    tool_path = shutil.which(tool)
                    if tool_path:
                        logger.info(f"  Bây giờ tìm thấy {tool} tại: {tool_path}")
                        try:
                            version_cmd = self.get_version_command(tool)
                            result = self.run_command(version_cmd, check=False)
                            if result.returncode == 0:
                                installed_tools.append(tool)
                                logger.info(f"✓ {tool} đã được cài đặt")
                                continue
                        except:
                            pass

                missing_tools.append(tool)

        # Kiểm tra Windows headers và libraries (chỉ trên Windows)
        if self.system == 'windows':
            logger.info("Kiểm tra Windows SDK và headers...")
            headers_ok = self.detect_windows_headers()
            if headers_ok:
                logger.info("✓ Windows headers có sẵn")
            else:
                logger.warning("⚠️ Một số Windows headers có thể thiếu")
                logger.info("Gợi ý: Cài đặt Windows SDK mới nhất qua Visual Studio Installer")

            # Thiết lập VC compiler includes
            self.setup_vc_compiler_includes()

        logger.info(f"Đã cài đặt: {', '.join(installed_tools)}")
        if missing_tools:
            logger.warning(f"Chưa cài đặt hoặc không tìm thấy: {', '.join(missing_tools)}")
            logger.info("Gợi ý: Kiểm tra PATH environment variable và thử restart terminal")

        return len(missing_tools) == 0

    def debug_path_info(self):
        """Hiển thị thông tin debug về PATH và environment"""
        logger.info("=== DEBUG PATH INFORMATION ===")

        # Hiển thị PATH hiện tại
        current_path = os.environ.get('PATH', '')
        path_dirs = current_path.split(os.pathsep)
        logger.info(f"PATH có {len(path_dirs)} thư mục:")
        for i, path_dir in enumerate(path_dirs[:10]):  # Chỉ hiển thị 10 thư mục đầu
            logger.info(f"  [{i+1}] {path_dir}")

        if len(path_dirs) > 10:
            logger.info(f"  ... và {len(path_dirs) - 10} thư mục khác")

        # Kiểm tra các biến môi trường quan trọng
        env_vars = ['MSYS2_ROOT', 'MSBuildPath', 'VCPKG_ROOT']
        for var in env_vars:
            value = os.environ.get(var, 'NOT SET')
            logger.info(f"  {var}: {value}")

        # Kiểm tra các thư mục MSYS2/MinGW thông thường
        common_paths = [
            'C:\\msys64\\usr\\bin',
            'C:\\msys64\\mingw64\\bin',
            'C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSVC',
            'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSVC'
        ]

        logger.info("Kiểm tra các thư mục thông thường:")
        for path in common_paths:
            exists = os.path.exists(path)
            logger.info(f"  {'✓' if exists else '✗'} {path}")

        logger.info("=== END DEBUG INFO ===")

    def get_version_command(self, tool):
        """Trả về command phù hợp để kiểm tra version của tool"""
        version_commands = {
            'gcc': 'gcc --version',
            'g++': 'g++ --version',
            'cmake': 'cmake --version',
            'ninja': 'ninja --version',
            'git': 'git --version',
            'cl': 'cl 2>&1 | findstr "Microsoft"',  # MSVC compiler - kiểm tra output
            'vcpkg': 'vcpkg version',
            'msbuild': 'msbuild -version',
            'mingw32-make': 'mingw32-make --version'
        }

        return version_commands.get(tool, f'{tool} --version')

    def check_tool_with_special_handling(self, tool, tool_path):
        """Kiểm tra tool với xử lý đặc biệt cho từng loại"""
        try:
            if tool == 'cl':
                # MSVC compiler - thử compile một file trống để kiểm tra
                result = self.run_command(f'"{tool_path}" /?', check=False)
                return result.returncode == 0
            elif tool in ['gcc', 'g++', 'mingw32-make']:
                # MinGW tools - kiểm tra --version
                result = self.run_command(f'"{tool_path}" --version', check=False)
                return result.returncode == 0
            elif tool == 'cmake':
                # CMake - kiểm tra --version
                result = self.run_command(f'"{tool_path}" --version', check=False)
                return result.returncode == 0
            elif tool == 'msbuild':
                # MSBuild - kiểm tra -version
                result = self.run_command(f'"{tool_path}" -version', check=False)
                return result.returncode == 0
            elif tool == 'vcpkg':
                # vcpkg - kiểm tra version
                result = self.run_command(f'"{tool_path}" version', check=False)
                return result.returncode == 0
            else:
                # Default: thử --version
                result = self.run_command(f'"{tool_path}" --version', check=False)
                return result.returncode == 0
        except:
            return False

    def manual_tool_check(self, tool):
        """Kiểm tra thủ công tool bằng cách tìm trong các đường dẫn thông thường"""
        logger.info(f"Tìm kiếm {tool} thủ công...")

        # Các đường dẫn có thể có tool
        search_paths = []

        if self.system == 'windows':
            search_paths = [
                # MSYS2/MinGW paths
                'C:\\msys64\\usr\\bin',
                'C:\\msys64\\mingw64\\bin',
                'C:\\msys64\\mingw32\\bin',
                'C:\\msys64\\clang64\\bin',
                'C:\\msys64\\ucrt64\\bin',

                # Git for Windows (có MinGW)
                'C:\\Program Files\\Git\\bin',
                'C:\\Program Files\\Git\\mingw64\\bin',
                'C:\\Program Files\\Git\\usr\\bin',
                'C:\\Program Files (x86)\\Git\\bin',
                'C:\\Program Files (x86)\\Git\\mingw64\\bin',
                'C:\\Program Files (x86)\\Git\\usr\\bin',

                # CMake
                'C:\\Program Files\\CMake\\bin',
                'C:\\Program Files (x86)\\CMake\\bin',

                # Ninja
                'C:\\Program Files\\ninja',
                'C:\\ninja',

                # MSBuild
                'C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin',
                'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin',
                'C:\\Program Files\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin',
                'C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin',

                # MSVC Compiler
                'C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSVC',
                'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Tools\\MSVC',
                'C:\\Program Files\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC',
                'C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Tools\\MSVC',

                # vcpkg
                'C:\\vcpkg',
                'C:\\Program Files\\vcpkg',

                # LLVM/Clang
                'C:\\Program Files\\LLVM\\bin',
                'C:\\Program Files (x86)\\LLVM\\bin',
            ]

        for base_path in search_paths:
            if os.path.exists(base_path):
                # Một số tool có thể không có .exe extension
                possible_names = [f'{tool}.exe', f'{tool}.bat', f'{tool}.cmd', tool]

                for tool_name in possible_names:
                    tool_path = os.path.join(base_path, tool_name)
                    if os.path.exists(tool_path):
                        logger.info(f"Tìm thấy {tool} tại: {tool_path}")

                        # Kiểm tra xem tool có hoạt động không
                        if self.check_tool_with_special_handling(tool, tool_path):
                            logger.info(f"  {tool} hoạt động tốt")
                            # Thử thêm vào PATH tạm thời
                            self.add_to_path(base_path)
                            return tool_path
                        else:
                            logger.warning(f"  {tool} tồn tại nhưng không hoạt động")

        # Tìm kiếm đệ quy trong các thư mục con cho MSVC
        if tool == 'cl':
            logger.info("Tìm kiếm MSVC compiler (cl.exe) đệ quy...")
            msvc_base_paths = [
                'C:\\Program Files\\Microsoft Visual Studio',
                'C:\\Program Files (x86)\\Microsoft Visual Studio'
            ]

            for base_path in msvc_base_paths:
                if os.path.exists(base_path):
                    for root, dirs, files in os.walk(base_path):
                        if 'cl.exe' in files:
                            cl_path = os.path.join(root, 'cl.exe')
                            logger.info(f"Tìm thấy cl.exe tại: {cl_path}")
                            if self.check_tool_with_special_handling('cl', cl_path):
                                cl_dir = os.path.dirname(cl_path)
                                self.add_to_path(cl_dir)
                                return cl_path

        logger.warning(f"Không tìm thấy {tool} trong các đường dẫn thông thường")
        return None

    def detect_existing_cmake(self):
        """Phát hiện CMake có sẵn trên hệ thống"""
        logger.info("Tìm kiếm CMake có sẵn...")

        # Kiểm tra trong PATH
        if shutil.which('cmake'):
            logger.info("CMake đã có trong PATH")
            return True

        # Tìm kiếm trong các thư mục thông thường
        cmake_paths = [
            'C:\\Program Files\\CMake\\bin',
            'C:\\Program Files (x86)\\CMake\\bin',
            'C:\\CMake\\bin',
            'C:\\msys64\\mingw64\\bin',
            'C:\\msys64\\usr\\bin'
        ]

        for cmake_path in cmake_paths:
            cmake_exe = os.path.join(cmake_path, 'cmake.exe')
            if os.path.exists(cmake_exe):
                logger.info(f"Tìm thấy CMake tại: {cmake_exe}")
                self.add_to_path(cmake_path)
                return True

        return False

    def detect_existing_ninja(self):
        """Phát hiện Ninja có sẵn trên hệ thống"""
        logger.info("Tìm kiếm Ninja có sẵn...")

        # Kiểm tra trong PATH
        if shutil.which('ninja'):
            logger.info("Ninja đã có trong PATH")
            return True

        # Tìm kiếm trong các thư mục thông thường
        ninja_paths = [
            'C:\\Program Files\\ninja',
            'C:\\ninja',
            'C:\\msys64\\mingw64\\bin',
            'C:\\msys64\\usr\\bin'
        ]

        for ninja_path in ninja_paths:
            ninja_exe = os.path.join(ninja_path, 'ninja.exe')
            if os.path.exists(ninja_exe):
                logger.info(f"Tìm thấy Ninja tại: {ninja_exe}")
                self.add_to_path(ninja_path)
                return True

        return False

    def refresh_environment(self):
        """Refresh environment variables sau khi cài đặt"""
        logger.info("Đang refresh environment variables...")

        try:
            if self.system == 'windows':
                # Refresh Windows environment
                import ctypes
                # Send WM_SETTINGCHANGE message to all windows
                ctypes.windll.user32.SendMessageW(0xFFFF, 0x001A, 0, 'Environment')

                # Alternative: use setx to refresh environment
                try:
                    self.run_command('setx DUMMY_VAR "dummy" /M', check=False)
                    self.run_command('reg delete "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" /v DUMMY_VAR /f', check=False)
                except:
                    pass

                logger.info("Đã refresh Windows environment")
            else:
                # Unix/Linux/macOS
                # Source .bashrc or similar
                shell_files = ['~/.bashrc', '~/.bash_profile', '~/.zshrc', '~/.profile']
                for shell_file in shell_files:
                    try:
                        shell_file_path = os.path.expanduser(shell_file)
                        if os.path.exists(shell_file_path):
                            self.run_command(f'source {shell_file_path}', check=False)
                    except:
                        pass

                logger.info("Đã refresh Unix environment")

        except Exception as e:
            logger.warning(f"Không thể refresh environment: {e}")

    def force_path_refresh(self):
        """Buộc refresh PATH environment variable"""
        logger.info("Buộc refresh PATH...")

        # Đọc lại PATH từ registry (Windows) hoặc environment
        if self.system == 'windows':
            try:
                # Đọc PATH từ registry
                import winreg
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 'Environment', 0, winreg.KEY_READ)
                try:
                    current_path, _ = winreg.QueryValueEx(key, 'PATH')
                    os.environ['PATH'] = current_path
                    logger.info("Đã refresh PATH từ registry")
                except:
                    pass
                finally:
                    winreg.CloseKey(key)
            except Exception as e:
                logger.error(f"Lỗi khi refresh PATH: {e}")
        else:
            # Unix/Linux/macOS - reload PATH
            try:
                result = self.run_command('echo $PATH', check=False)
                if result.returncode == 0:
                    os.environ['PATH'] = result.stdout.strip()
                    logger.info("Đã refresh PATH từ shell")
            except:
                pass

    def cleanup(self):
        """Dọn dẹp các file tạm"""
        try:
            shutil.rmtree(self.temp_dir)
            logger.info("Đã dọn dẹp các file tạm")
        except Exception as e:
            logger.error(f"Lỗi khi dọn dẹp: {e}")

    def run_full_installation(self):
        """Chạy toàn bộ quá trình cài đặt"""
        logger.info("Bắt đầu cài đặt C/C++ dependencies...")
        logger.info(f"Hệ điều hành: {self.system}")
        logger.info(f"Kiến trúc: {self.architecture}")
        logger.info(f"Quyền admin: {self.is_admin}")
        logger.info(f"Thư mục cài đặt: {self.install_dir}")
        
        try:
            # Tạo thư mục cài đặt
            self.install_dir.mkdir(parents=True, exist_ok=True)
            
            # Cài đặt compiler
            self.install_compiler()
            
            # Kiểm tra và cài đặt MSBuild và MSYS2 (Windows only)
            if self.system == 'windows':
                if not self.detect_existing_msbuild():
                    logger.info("MSBuild chưa được cài đặt, tiến hành cài đặt...")
                    self.setup_msbuild_path()  # Thử tìm lại sau khi cài VS Build Tools
                    if not self.detect_existing_msbuild():
                        self.install_msbuild_standalone()

                # Kiểm tra và cài đặt MSYS2/MinGW
                if not self.detect_existing_msys2():
                    logger.info("MSYS2/MinGW chưa được cài đặt, tiến hành cài đặt...")
                    self.setup_msys2_path()  # Thử tìm lại sau khi cài VS Build Tools
                    if not self.detect_existing_msys2():
                        self.install_msys2()
            
            # Cài đặt CMake (đảm bảo được cài đặt)
            if not self.detect_existing_cmake():
                logger.info("CMake chưa được cài đặt, tiến hành cài đặt...")
                self.install_cmake()
            else:
                logger.info("CMake đã được cài đặt")

            # Cài đặt Ninja
            if not self.detect_existing_ninja():
                logger.info("Ninja chưa được cài đặt, tiến hành cài đặt...")
                self.install_ninja()
            else:
                logger.info("Ninja đã được cài đặt")

            # Cài đặt vcpkg
            self.install_vcpkg()

            # Cài đặt Conan
            self.install_conan()

            # Cài đặt các công cụ bổ sung
            self.install_additional_tools()
            
            # Refresh environment trước khi kiểm tra
            self.refresh_environment()
            self.force_path_refresh()

            # Kiểm tra cài đặt
            success = self.verify_installation()

            if success:
                logger.info("🎉 Cài đặt hoàn tất thành công!")
                logger.info("Tất cả công cụ đã được cài đặt và sẵn sàng sử dụng.")
            else:
                logger.warning("⚠️ Cài đặt hoàn tất nhưng một số công cụ có thể chưa sẵn sàng.")
                logger.info("Gợi ý:")
                logger.info("  1. Khởi động lại terminal/command prompt")
                logger.info("  2. Kiểm tra PATH environment variable")
                logger.info("  3. Chạy lại script với --verify-only để kiểm tra")
                logger.info("  4. Cài đặt thủ công các công cụ còn thiếu")
            
        except Exception as e:
            logger.error(f"Lỗi trong quá trình cài đặt: {e}")
        finally:
            self.cleanup()

def main():
    """Hàm chính"""
    print("=" * 60)
    print("🔧 AUTO C/C++ DEPENDENCIES INSTALLER 🔧")
    print("Tự động cài đặt tất cả dependencies cần thiết cho C/C++")
    print("=" * 60)

    if len(sys.argv) > 1 and sys.argv[1] in ['-h', '--help']:
        print("""
Cách sử dụng:
    python auto_install_cpp_deps.py [options]

Options:
    -h, --help         Hiển thị trợ giúp này
    --no-admin         Chạy mà không cần quyền admin (có thể hạn chế một số tính năng)
    --verify-only      Chỉ kiểm tra các công cụ đã cài đặt
    --debug            Chạy với chế độ debug (thông tin chi tiết hơn)
    --force-install    Buộc cài đặt lại tất cả (bỏ qua detection)

Công cụ sẽ được cài đặt:
    - Compiler (GCC/Clang/MSVC)
    - CMake, Ninja
    - MSBuild từ Microsoft.VisualStudio.Workload.VCTools
    - MSYS2.MSYS2 với MinGW toolchain đầy đủ
    - vcpkg, Conan
    - Git (nếu chưa có)
    - pkg-config
        """)
        return

    if '--verify-only' in sys.argv:
        installer = CppDepsInstaller()
        installer.verify_installation()
        return

    # Kiểm tra quyền admin trên Windows
    installer = CppDepsInstaller()
    if installer.system == 'windows' and not installer.is_admin and '--no-admin' not in sys.argv:
        logger.warning("⚠️ Khuyến nghị chạy với quyền Administrator để cài đặt đầy đủ.")
        response = input("Bạn có muốn tiếp tục không? (y/N): ")
        if response.lower() not in ['y', 'yes']:
            logger.info("Đã hủy cài đặt.")
            return

    # Chạy cài đặt
    installer.run_full_installation()

if __name__ == "__main__":
    main()
