#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Auto Install Dependencies for C/C++ Compiler
Tự động cài đặt các dependencies cần thiết cho việc compile C/C++
"""

import os
import sys
import subprocess
import json
import urllib.request
import zipfile
import tempfile
import shutil
from pathlib import Path
import winreg
import ctypes
from typing import Dict, List, Optional, Tuple
import time

class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class DependencyInstaller:
    """Main class for installing C/C++ development dependencies"""
    
    def __init__(self):
        self.install_dir = Path.home() / "c++_deps"
        self.temp_dir = Path(tempfile.gettempdir()) / "c++_deps_temp"
        self.config_file = Path("deps_config.json")
        self.is_admin = self._check_admin()
        
        # Create directories
        self.install_dir.mkdir(exist_ok=True)
        self.temp_dir.mkdir(exist_ok=True)
        
        # Load configuration
        self.config = self._load_config()
        
    def _check_admin(self) -> bool:
        """Check if running with administrator privileges"""
        try:
            return ctypes.windll.shell32.IsUserAnAdmin()
        except:
            return False
    
    def _load_config(self) -> Dict:
        """Load configuration from JSON file"""
        default_config = {
            "visual_studio": {
                "enabled": True,
                "version": "2022",
                "components": ["Microsoft.VisualStudio.Workload.VCTools"]
            },
            "mingw": {
                "enabled": True,
                "version": "13.2.0",
                "architecture": "x86_64",
                "threads": "posix",
                "exceptions": "seh"
            },
            "cmake": {
                "enabled": True,
                "version": "3.28.0"
            },
            "ninja": {
                "enabled": True,
                "version": "1.11.1"
            },
            "msbuild": {
                "enabled": True,
                "version": "17.0",
                "auto_detect": True
            },
            "nuget": {
                "enabled": True,
                "version": "6.8.0"
            },
            "git": {
                "enabled": True,
                "version": "2.43.0"
            },
            "python_dev": {
                "enabled": True,
                "version": "3.11"
            },
            "nodejs": {
                "enabled": False,
                "version": "20.10.0"
            },
            "libraries": {
                "boost": True,
                "eigen": True,
                "opencv": True,
                "qt": False,
                "vcpkg": True,
                "conan": False
            },
            "build_tools": {
                "make": True,
                "autotools": False,
                "bazel": False,
                "gradle": False
            }
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    # Merge user config with default
                    self._merge_configs(default_config, user_config)
            except Exception as e:
                self.print_warning(f"Không thể đọc file config: {e}")
        
        return default_config
    
    def _merge_configs(self, default: Dict, user: Dict):
        """Merge user configuration with default configuration"""
        for key, value in user.items():
            if key in default:
                if isinstance(value, dict) and isinstance(default[key], dict):
                    self._merge_configs(default[key], value)
                else:
                    default[key] = value
    
    def print_header(self, message: str):
        """Print header message"""
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{message:^60}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    
    def print_success(self, message: str):
        """Print success message"""
        print(f"{Colors.OKGREEN}✓ {message}{Colors.ENDC}")
    
    def print_warning(self, message: str):
        """Print warning message"""
        print(f"{Colors.WARNING}⚠ {message}{Colors.ENDC}")
    
    def print_error(self, message: str):
        """Print error message"""
        print(f"{Colors.FAIL}✗ {message}{Colors.ENDC}")
    
    def print_info(self, message: str):
        """Print info message"""
        print(f"{Colors.OKBLUE}ℹ {message}{Colors.ENDC}")
    
    def run_command(self, command: List[str], cwd: Optional[Path] = None) -> Tuple[bool, str]:
        """Run a command and return success status and output"""
        try:
            result = subprocess.run(
                command,
                cwd=cwd,
                capture_output=True,
                text=True,
                encoding='utf-8',
                timeout=300
            )
            return result.returncode == 0, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return False, "Command timed out"
        except Exception as e:
            return False, str(e)
    
    def check_command_exists(self, command: str) -> bool:
        """Check if a command exists in PATH"""
        try:
            subprocess.run([command, '--version'], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def download_file(self, url: str, filename: str) -> Optional[Path]:
        """Download a file from URL"""
        try:
            file_path = self.temp_dir / filename
            self.print_info(f"Đang tải {filename}...")
            
            urllib.request.urlretrieve(url, file_path)
            return file_path
        except Exception as e:
            self.print_error(f"Không thể tải {filename}: {e}")
            return None
    
    def extract_zip(self, zip_path: Path, extract_to: Path) -> bool:
        """Extract ZIP file"""
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(extract_to)
            return True
        except Exception as e:
            self.print_error(f"Không thể giải nén {zip_path}: {e}")
            return False
    
    def install_visual_studio(self) -> bool:
        """Install Visual Studio Build Tools"""
        if not self.config["visual_studio"]["enabled"]:
            self.print_info("Visual Studio Build Tools bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Visual Studio Build Tools")
        
        # Check if already installed
        if self._check_vs_installed():
            self.print_success("Visual Studio Build Tools đã được cài đặt")
            return True
        
        # Download and install Visual Studio Installer
        vs_installer_url = "https://aka.ms/vs/17/release/vs_community.exe"
        installer_path = self.download_file(vs_installer_url, "vs_community.exe")
        
        if not installer_path:
            return False
        
        # Install with required components
        components = self.config["visual_studio"]["components"]
        install_args = [
            str(installer_path),
            "--quiet",
            "--norestart",
            "--wait",
            "--add", ",".join(components)
        ]
        
        self.print_info("Đang cài đặt Visual Studio Build Tools...")
        success, output = self.run_command(install_args)
        
        if success:
            self.print_success("Visual Studio Build Tools đã được cài đặt thành công")
        else:
            self.print_error(f"Không thể cài đặt Visual Studio Build Tools: {output}")
        
        return success
    
    def install_msbuild(self) -> bool:
        """Install MSBuild"""
        if not self.config["msbuild"]["enabled"]:
            self.print_info("MSBuild bị tắt trong config")
            return True
        
        self.print_header("Cài đặt MSBuild")
        
        # Check if already installed
        if self.check_command_exists("msbuild"):
            self.print_success("MSBuild đã được cài đặt")
            return True
        
        # Try to find MSBuild in Visual Studio installation
        if self.config["msbuild"]["auto_detect"]:
            msbuild_path = self._find_msbuild_in_vs()
            if msbuild_path:
                self._add_to_path(str(msbuild_path))
                self.print_success("MSBuild đã được tìm thấy và thêm vào PATH")
                return True
        
        # Download standalone MSBuild if not found
        version = self.config["msbuild"]["version"]
        msbuild_url = f"https://aka.ms/vs/{version}/release/msbuild.zip"
        
        msbuild_zip = self.download_file(msbuild_url, "msbuild.zip")
        if not msbuild_zip:
            return False
        
        # Extract to install directory
        msbuild_dir = self.install_dir / "msbuild"
        if self.extract_zip(msbuild_zip, msbuild_dir):
            self.print_success("MSBuild đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(msbuild_dir))
            return True
        
        return False
    
    def _find_msbuild_in_vs(self) -> Optional[Path]:
        """Find MSBuild in Visual Studio installation"""
        possible_paths = [
            r"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin",
            r"C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin",
            r"C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin"
        ]
        
        for path in possible_paths:
            msbuild_path = Path(path) / "MSBuild.exe"
            if msbuild_path.exists():
                return Path(path)
        
        return None
    
    def _check_vs_installed(self) -> bool:
        """Check if Visual Studio is installed"""
        try:
            # Check registry for Visual Studio installation
            key_path = r"SOFTWARE\Microsoft\VisualStudio\Setup\Community"
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, key_path) as key:
                return True
        except FileNotFoundError:
            return False
    
    def install_msbuild(self) -> bool:
        """Install MSBuild"""
        if not self.config["msbuild"]["enabled"]:
            self.print_info("MSBuild bị tắt trong config")
            return True
        
        self.print_header("Cài đặt MSBuild")
        
        # Check if already installed
        if self.check_command_exists("msbuild"):
            self.print_success("MSBuild đã được cài đặt")
            return True
        
        # Try to find MSBuild in Visual Studio installation
        if self.config["msbuild"]["auto_detect"]:
            msbuild_path = self._find_msbuild_in_vs()
            if msbuild_path:
                self._add_to_path(str(msbuild_path))
                self.print_success("MSBuild đã được tìm thấy và thêm vào PATH")
                return True
        
        # Download standalone MSBuild if not found
        version = self.config["msbuild"]["version"]
        msbuild_url = f"https://aka.ms/vs/{version}/release/msbuild.zip"
        
        msbuild_zip = self.download_file(msbuild_url, "msbuild.zip")
        if not msbuild_zip:
            return False
        
        # Extract to install directory
        msbuild_dir = self.install_dir / "msbuild"
        if self.extract_zip(msbuild_zip, msbuild_dir):
            self.print_success("MSBuild đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(msbuild_dir))
            return True
        
        return False
    
    def _find_msbuild_in_vs(self) -> Optional[Path]:
        """Find MSBuild in Visual Studio installation"""
        possible_paths = [
            r"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin",
            r"C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin",
            r"C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin"
        ]
        
        for path in possible_paths:
            msbuild_path = Path(path) / "MSBuild.exe"
            if msbuild_path.exists():
                return Path(path)
        
        return None
    
    def install_nuget(self) -> bool:
        """Install NuGet package manager"""
        if not self.config["nuget"]["enabled"]:
            self.print_info("NuGet bị tắt trong config")
            return True
        
        self.print_header("Cài đặt NuGet")
        
        # Check if already installed
        if self.check_command_exists("nuget"):
            self.print_success("NuGet đã được cài đặt")
            return True
        
        # Download NuGet
        version = self.config["nuget"]["version"]
        nuget_url = f"https://dist.nuget.org/win-x86-commandline/v{version}/nuget.exe"
        
        nuget_exe = self.download_file(nuget_url, "nuget.exe")
        if not nuget_exe:
            return False
        
        # Copy to install directory
        nuget_dir = self.install_dir / "nuget"
        nuget_dir.mkdir(exist_ok=True)
        
        try:
            shutil.copy2(nuget_exe, nuget_dir / "nuget.exe")
            self.print_success("NuGet đã được cài đặt")
            
            # Add to PATH
            self._add_to_path(str(nuget_dir))
            return True
        except Exception as e:
            self.print_error(f"Không thể cài đặt NuGet: {e}")
            return False
    
    def install_git(self) -> bool:
        """Install Git"""
        if not self.config["git"]["enabled"]:
            self.print_info("Git bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Git")
        
        # Check if already installed
        if self.check_command_exists("git"):
            self.print_success("Git đã được cài đặt")
            return True
        
        # Download Git for Windows
        version = self.config["git"]["version"]
        git_url = f"https://github.com/git-for-windows/git/releases/download/v{version}.windows.1/Git-{version}-64-bit.exe"
        
        git_exe = self.download_file(git_url, "git-installer.exe")
        if not git_exe:
            return False
        
        # Install Git silently
        install_args = [
            str(git_exe),
            "/VERYSILENT",
            "/NORESTART",
            "/COMPONENTS=icons,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh"
        ]
        
        self.print_info("Đang cài đặt Git...")
        success, output = self.run_command(install_args)
        
        if success:
            self.print_success("Git đã được cài đặt thành công")
            return True
        else:
            self.print_error(f"Không thể cài đặt Git: {output}")
            return False
    
    def install_python_dev(self) -> bool:
        """Install Python development tools"""
        if not self.config["python_dev"]["enabled"]:
            self.print_info("Python development tools bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Python Development Tools")
        
        # Check if Python is already installed
        if self.check_command_exists("python"):
            self.print_info("Python đã được cài đặt, kiểm tra development tools...")
            
            # Install development tools via pip
            dev_packages = [
                "setuptools",
                "wheel",
                "pip",
                "build",
                "twine"
            ]
            
            for package in dev_packages:
                try:
                    subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", package], 
                                 capture_output=True, check=True)
                    self.print_success(f"Đã cài đặt {package}")
                except subprocess.CalledProcessError:
                    self.print_warning(f"Không thể cài đặt {package}")
            
            return True
        
        # Download Python if not installed
        version = self.config["python_dev"]["version"]
        python_url = f"https://www.python.org/ftp/python/{version}/python-{version}-amd64.exe"
        
        python_exe = self.download_file(python_url, "python-installer.exe")
        if not python_exe:
            return False
        
        # Install Python with development tools
        install_args = [
            str(python_exe),
            "/quiet",
            "InstallAllUsers=1",
            "PrependPath=1",
            "Include_test=0",
            "Include_pip=1",
            "Include_dev=1"
        ]
        
        self.print_info("Đang cài đặt Python...")
        success, output = self.run_command(install_args)
        
        if success:
            self.print_success("Python đã được cài đặt thành công")
            return True
        else:
            self.print_error(f"Không thể cài đặt Python: {output}")
            return False
    
    def install_vcpkg(self) -> bool:
        """Install vcpkg package manager"""
        if not self.config["libraries"]["vcpkg"]:
            self.print_info("vcpkg bị tắt trong config")
            return True
        
        self.print_header("Cài đặt vcpkg")
        
        # Check if already installed
        vcpkg_dir = self.install_dir / "vcpkg"
        if vcpkg_dir.exists() and (vcpkg_dir / "vcpkg.exe").exists():
            self.print_success("vcpkg đã được cài đặt")
            self._add_to_path(str(vcpkg_dir))
            return True
        
        # Clone vcpkg repository
        if self.check_command_exists("git"):
            self.print_info("Đang clone vcpkg repository...")
            
            try:
                subprocess.run([
                    "git", "clone", "https://github.com/Microsoft/vcpkg.git", 
                    str(vcpkg_dir)
                ], check=True, capture_output=True)
                
                # Bootstrap vcpkg
                bootstrap_script = vcpkg_dir / "bootstrap-vcpkg.bat"
                if bootstrap_script.exists():
                    self.print_info("Đang bootstrap vcpkg...")
                    success, output = self.run_command([str(bootstrap_script)])
                    
                    if success:
                        self.print_success("vcpkg đã được cài đặt thành công")
                        self._add_to_path(str(vcpkg_dir))
                        return True
                    else:
                        self.print_error(f"Không thể bootstrap vcpkg: {output}")
                        return False
                else:
                    self.print_error("Không tìm thấy bootstrap script")
                    return False
                    
            except subprocess.CalledProcessError as e:
                self.print_error(f"Không thể clone vcpkg: {e}")
                return False
        else:
            self.print_error("Git chưa được cài đặt, không thể clone vcpkg")
            return False
    
    def install_make(self) -> bool:
        """Install Make for Windows"""
        if not self.config["build_tools"]["make"]:
            self.print_info("Make bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Make for Windows")
        
        # Check if already installed
        if self.check_command_exists("make"):
            self.print_success("Make đã được cài đặt")
            return True
        
        # Download Make for Windows
        make_url = "https://github.com/jgm/pandoc/releases/download/3.1.6/make-4.4.1-windows.zip"
        make_zip = self.download_file(make_url, "make-windows.zip")
        
        if not make_zip:
            return False
        
        # Extract to install directory
        make_dir = self.install_dir / "make"
        if self.extract_zip(make_zip, make_dir):
            self.print_success("Make đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(make_dir))
            return True
        
        return False
    
    def install_nuget(self) -> bool:
        """Install NuGet package manager"""
        if not self.config["nuget"]["enabled"]:
            self.print_info("NuGet bị tắt trong config")
            return True
        
        self.print_header("Cài đặt NuGet")
        
        # Check if already installed
        if self.check_command_exists("nuget"):
            self.print_success("NuGet đã được cài đặt")
            return True
        
        # Download NuGet
        version = self.config["nuget"]["version"]
        nuget_url = f"https://dist.nuget.org/win-x86-commandline/v{version}/nuget.exe"
        
        nuget_exe = self.download_file(nuget_url, "nuget.exe")
        if not nuget_exe:
            return False
        
        # Copy to install directory
        nuget_dir = self.install_dir / "nuget"
        nuget_dir.mkdir(exist_ok=True)
        
        try:
            shutil.copy2(nuget_exe, nuget_dir / "nuget.exe")
            self.print_success("NuGet đã được cài đặt")
            
            # Add to PATH
            self._add_to_path(str(nuget_dir))
            return True
        except Exception as e:
            self.print_error(f"Không thể cài đặt NuGet: {e}")
            return False
    
    def install_git(self) -> bool:
        """Install Git"""
        if not self.config["git"]["enabled"]:
            self.print_info("Git bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Git")
        
        # Check if already installed
        if self.check_command_exists("git"):
            self.print_success("Git đã được cài đặt")
            return True
        
        # Download Git for Windows
        version = self.config["git"]["version"]
        git_url = f"https://github.com/git-for-windows/git/releases/download/v{version}.windows.1/Git-{version}-64-bit.exe"
        
        git_exe = self.download_file(git_url, "git-installer.exe")
        if not git_exe:
            return False
        
        # Install Git silently
        install_args = [
            str(git_exe),
            "/VERYSILENT",
            "/NORESTART",
            "/COMPONENTS=icons,ext\\reg\\shellhere,ext\\reg\\guihere,assoc,assoc_sh"
        ]
        
        self.print_info("Đang cài đặt Git...")
        success, output = self.run_command(install_args)
        
        if success:
            self.print_success("Git đã được cài đặt thành công")
            return True
        else:
            self.print_error(f"Không thể cài đặt Git: {output}")
            return False
    
    def install_mingw(self) -> bool:
        """Install MinGW-w64"""
        if not self.config["mingw"]["enabled"]:
            self.print_info("MinGW-w64 bị tắt trong config")
            return True
        
        self.print_header("Cài đặt MinGW-w64")
        
        # Check if already installed
        if self.check_command_exists("gcc"):
            self.print_success("MinGW-w64 đã được cài đặt")
            return True
        
        # Download MinGW-w64
        config = self.config["mingw"]
        mingw_url = f"https://github.com/niXman/mingw-builds-binaries/releases/download/{config['version']}-rt_v11-rev1/winlibs-{config['architecture']}-posix-{config['threads']}-{config['exceptions']}-{config['version']}-rt_v11-rev1-msvcrt-runtime.zip"
        
        mingw_zip = self.download_file(mingw_url, "mingw-w64.zip")
        if not mingw_zip:
            return False
        
        # Extract to install directory
        mingw_dir = self.install_dir / "mingw64"
        if self.extract_zip(mingw_zip, self.install_dir):
            self.print_success("MinGW-w64 đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(mingw_dir / "bin"))
            return True
        
        return False
    
    def install_cmake(self) -> bool:
        """Install CMake"""
        if not self.config["cmake"]["enabled"]:
            self.print_info("CMake bị tắt trong config")
            return True
        
        self.print_header("Cài đặt CMake")
        
        # Check if already installed
        if self.check_command_exists("cmake"):
            self.print_success("CMake đã được cài đặt")
            return True
        
        # Download CMake
        version = self.config["cmake"]["version"]
        cmake_url = f"https://github.com/Kitware/CMake/releases/download/v{version}/cmake-{version}-windows-x86_64.zip"
        
        cmake_zip = self.download_file(cmake_url, "cmake.zip")
        if not cmake_zip:
            return False
        
        # Extract to install directory
        cmake_dir = self.install_dir / "cmake"
        if self.extract_zip(cmake_zip, self.install_dir):
            self.print_success("CMake đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(cmake_dir / "bin"))
            return True
        
        return False
    
    def install_ninja(self) -> bool:
        """Install Ninja build system"""
        if not self.config["ninja"]["enabled"]:
            self.print_info("Ninja bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Ninja")
        
        # Check if already installed
        if self.check_command_exists("ninja"):
            self.print_success("Ninja đã được cài đặt")
            return True
        
        # Download Ninja
        version = self.config["ninja"]["version"]
        ninja_url = f"https://github.com/ninja-build/ninja/releases/download/v{version}/ninja-win.zip"
        
        ninja_zip = self.download_file(ninja_url, "ninja.zip")
        if not ninja_zip:
            return False
        
        # Extract to install directory
        ninja_dir = self.install_dir / "ninja"
        ninja_dir.mkdir(exist_ok=True)
        
        if self.extract_zip(ninja_zip, ninja_dir):
            self.print_success("Ninja đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(ninja_dir))
            return True
        
        return False
    
    def install_vcpkg(self) -> bool:
        """Install vcpkg package manager"""
        if not self.config["libraries"]["vcpkg"]:
            self.print_info("vcpkg bị tắt trong config")
            return True
        
        self.print_header("Cài đặt vcpkg")
        
        # Check if already installed
        vcpkg_dir = self.install_dir / "vcpkg"
        if vcpkg_dir.exists() and (vcpkg_dir / "vcpkg.exe").exists():
            self.print_success("vcpkg đã được cài đặt")
            self._add_to_path(str(vcpkg_dir))
            return True
        
        # Clone vcpkg repository
        if self.check_command_exists("git"):
            self.print_info("Đang clone vcpkg repository...")
            
            try:
                subprocess.run([
                    "git", "clone", "https://github.com/Microsoft/vcpkg.git", 
                    str(vcpkg_dir)
                ], check=True, capture_output=True)
                
                # Bootstrap vcpkg
                bootstrap_script = vcpkg_dir / "bootstrap-vcpkg.bat"
                if bootstrap_script.exists():
                    self.print_info("Đang bootstrap vcpkg...")
                    success, output = self.run_command([str(bootstrap_script)])
                    
                    if success:
                        self.print_success("vcpkg đã được cài đặt thành công")
                        self._add_to_path(str(vcpkg_dir))
                        return True
                    else:
                        self.print_error(f"Không thể bootstrap vcpkg: {output}")
                        return False
                else:
                    self.print_error("Không tìm thấy bootstrap script")
                    return False
                    
            except subprocess.CalledProcessError as e:
                self.print_error(f"Không thể clone vcpkg: {e}")
                return False
        else:
            self.print_error("Git chưa được cài đặt, không thể clone vcpkg")
            return False
    
    def install_make(self) -> bool:
        """Install Make for Windows"""
        if not self.config["build_tools"]["make"]:
            self.print_info("Make bị tắt trong config")
            return True
        
        self.print_header("Cài đặt Make for Windows")
        
        # Check if already installed
        if self.check_command_exists("make"):
            self.print_success("Make đã được cài đặt")
            return True
        
        # Download Make for Windows
        make_url = "https://github.com/jgm/pandoc/releases/download/3.1.6/make-4.4.1-windows.zip"
        make_zip = self.download_file(make_url, "make-windows.zip")
        
        if not make_zip:
            return False
        
        # Extract to install directory
        make_dir = self.install_dir / "make"
        if self.extract_zip(make_zip, make_dir):
            self.print_success("Make đã được giải nén")
            
            # Add to PATH
            self._add_to_path(str(make_dir))
            return True
        
        return False
    
    def install_libraries(self) -> bool:
        """Install additional C++ libraries"""
        if not any(self.config["libraries"].values()):
            self.print_info("Không có thư viện nào được bật trong config")
            return True
        
        self.print_header("Cài đặt các thư viện C++")
        
        success = True
        
        # Install vcpkg first
        if self.config["libraries"]["vcpkg"]:
            if not self.install_vcpkg():
                success = False
        
        # Install Boost
        if self.config["libraries"]["boost"]:
            if not self._install_boost():
                success = False
        
        # Install Eigen
        if self.config["libraries"]["eigen"]:
            if not self._install_eigen():
                success = False
        
        # Install OpenCV
        if self.config["libraries"]["opencv"]:
            if not self._install_opencv():
                success = False
        
        return success
    
    def _install_boost(self) -> bool:
        """Install Boost library"""
        self.print_info("Đang cài đặt Boost...")
        
        # Download Boost
        boost_url = "https://boostorg.jfrog.io/artifactory/main/release/1.84.0/source/boost_1_84_0.zip"
        boost_zip = self.download_file(boost_url, "boost.zip")
        
        if not boost_zip:
            return False
        
        # Extract to install directory
        boost_dir = self.install_dir / "boost"
        if self.extract_zip(boost_zip, self.install_dir):
            self.print_success("Boost đã được cài đặt")
            return True
        
        return False
    
    def _install_eigen(self) -> bool:
        """Install Eigen library"""
        self.print_info("Đang cài đặt Eigen...")
        
        # Download Eigen
        eigen_url = "https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip"
        eigen_zip = self.download_file(eigen_url, "eigen.zip")
        
        if not eigen_zip:
            return False
        
        # Extract to install directory
        eigen_dir = self.install_dir / "eigen"
        if self.extract_zip(eigen_zip, self.install_dir):
            self.print_success("Eigen đã được cài đặt")
            return True
        
        return False
    
    def _install_opencv(self) -> bool:
        """Install OpenCV library"""
        self.print_info("Đang cài đặt OpenCV...")
        
        # Download OpenCV
        opencv_url = "https://github.com/opencv/opencv/releases/download/4.8.1/opencv-4.8.1-windows.exe"
        opencv_exe = self.download_file(opencv_url, "opencv.exe")
        
        if not opencv_exe:
            return False
        
        # Run installer
        success, output = self.run_command([str(opencv_exe), "/S"])
        
        if success:
            self.print_success("OpenCV đã được cài đặt")
            return True
        else:
            self.print_error(f"Không thể cài đặt OpenCV: {output}")
            return False
    
    def _add_to_path(self, path: str):
        """Add directory to system PATH"""
        try:
            # Get current PATH
            current_path = os.environ.get('PATH', '')
            
            if path not in current_path:
                new_path = f"{current_path};{path}"
                os.environ['PATH'] = new_path
                
                # Try to update system PATH (requires admin privileges)
                if self.is_admin:
                    self._update_system_path(path)
                
                self.print_info(f"Đã thêm {path} vào PATH")
        except Exception as e:
            self.print_warning(f"Không thể cập nhật PATH: {e}")
    
    def _update_system_path(self, path: str):
        """Update system PATH in registry (requires admin privileges)"""
        try:
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, 
                                r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment", 
                                0, winreg.KEY_READ | winreg.KEY_WRITE)
            
            current_path, _ = winreg.QueryValueEx(key, "Path")
            if path not in current_path:
                new_path = f"{current_path};{path}"
                winreg.SetValueEx(key, "Path", 0, winreg.REG_EXPAND_SZ, new_path)
            
            winreg.CloseKey(key)
        except Exception as e:
            self.print_warning(f"Không thể cập nhật registry PATH: {e}")
    
    def create_environment_script(self):
        """Create batch script to set environment variables"""
        script_content = f"""@echo off
REM Environment setup script for C++ development
REM Generated by auto_install_deps.py

echo Setting up C++ development environment...

REM Add MinGW-w64 to PATH
set "PATH={self.install_dir}\\mingw64\\bin;%PATH%"

REM Add CMake to PATH
set "PATH={self.install_dir}\\cmake\\bin;%PATH%"

REM Add Ninja to PATH
set "PATH={self.install_dir}\\ninja;%PATH%"

REM Add MSBuild to PATH
set "PATH={self.install_dir}\\msbuild;%PATH%"

REM Add NuGet to PATH
set "PATH={self.install_dir}\\nuget;%PATH%"

REM Add vcpkg to PATH
set "PATH={self.install_dir}\\vcpkg;%PATH%"

REM Add Make to PATH
set "PATH={self.install_dir}\\make;%PATH%"

REM Set environment variables
set "BOOST_ROOT={self.install_dir}\\boost"
set "EIGEN3_ROOT={self.install_dir}\\eigen"
set "OpenCV_DIR={self.install_dir}\\opencv"
set "VCPKG_ROOT={self.install_dir}\\vcpkg"

echo Environment variables set successfully!
echo.
echo Available tools:
gcc --version
cmake --version
ninja --version
msbuild /version
nuget help
git --version

echo.
echo Environment setup complete!
pause
"""
        
        script_path = Path("setup_env.bat")
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(script_content)
        
        self.print_success(f"Đã tạo script setup environment: {script_path}")
    
    def verify_installation(self) -> bool:
        """Verify that all installed tools work correctly"""
        self.print_header("Kiểm tra cài đặt")
        
        success = True
        
        # Check GCC
        if self.config["mingw"]["enabled"]:
            if self.check_command_exists("gcc"):
                self.print_success("GCC compiler hoạt động")
            else:
                self.print_error("GCC compiler không hoạt động")
                success = False
        
        # Check CMake
        if self.config["cmake"]["enabled"]:
            if self.check_command_exists("cmake"):
                self.print_success("CMake hoạt động")
            else:
                self.print_error("CMake không hoạt động")
                success = False
        
        # Check Ninja
        if self.config["ninja"]["enabled"]:
            if self.check_command_exists("ninja"):
                self.print_success("Ninja hoạt động")
            else:
                self.print_error("Ninja không hoạt động")
                success = False
        
        # Check MSBuild
        if self.config["msbuild"]["enabled"]:
            if self.check_command_exists("msbuild"):
                self.print_success("MSBuild hoạt động")
            else:
                self.print_error("MSBuild không hoạt động")
                success = False
        
        # Check NuGet
        if self.config["nuget"]["enabled"]:
            if self.check_command_exists("nuget"):
                self.print_success("NuGet hoạt động")
            else:
                self.print_error("NuGet không hoạt động")
                success = False
        
        # Check Git
        if self.config["git"]["enabled"]:
            if self.check_command_exists("git"):
                self.print_success("Git hoạt động")
            else:
                self.print_error("Git không hoạt động")
                success = False
        
        return success
    
    def cleanup(self):
        """Clean up temporary files"""
        try:
            if self.temp_dir.exists():
                shutil.rmtree(self.temp_dir)
            self.print_info("Đã dọn dẹp file tạm")
        except Exception as e:
            self.print_warning(f"Không thể dọn dẹp file tạm: {e}")
    
    def run(self):
        """Main installation process"""
        self.print_header("Auto Install Dependencies for C/C++ Compiler")
        
        if not self.is_admin:
            self.print_warning("Khuyến nghị chạy script với quyền Administrator")
        
        try:
            # Install Visual Studio Build Tools
            if not self.install_visual_studio():
                self.print_error("Không thể cài đặt Visual Studio Build Tools")
                return False
            
            # Install MSBuild
            if not self.install_msbuild():
                self.print_error("Không thể cài đặt MSBuild")
                return False
            
            # Install NuGet
            if not self.install_nuget():
                self.print_error("Không thể cài đặt NuGet")
                return False
            
            # Install Git
            if not self.install_git():
                self.print_error("Không thể cài đặt Git")
                return False
            
            # Install Python development tools
            if not self.install_python_dev():
                self.print_error("Không thể cài đặt Python development tools")
                return False
            
            # Install MinGW-w64
            if not self.install_mingw():
                self.print_error("Không thể cài đặt MinGW-w64")
                return False
            
            # Install CMake
            if not self.install_cmake():
                self.print_error("Không thể cài đặt CMake")
                return False
            
            # Install Ninja
            if not self.install_ninja():
                self.print_error("Không thể cài đặt Ninja")
                return False
            
            # Install Make
            if not self.install_make():
                self.print_warning("Không thể cài đặt Make")
            
            # Install additional libraries
            if not self.install_libraries():
                self.print_warning("Một số thư viện không thể cài đặt")
            
            # Create environment setup script
            self.create_environment_script()
            
            # Verify installation
            if self.verify_installation():
                self.print_success("Cài đặt hoàn tất thành công!")
            else:
                self.print_warning("Cài đặt hoàn tất nhưng có một số vấn đề")
            
            return True
            
        except Exception as e:
            self.print_error(f"Lỗi trong quá trình cài đặt: {e}")
            return False
        finally:
            self.cleanup()

def main():
    """Main function"""
    try:
        installer = DependencyInstaller()
        success = installer.run()
        
        if success:
            print(f"\n{Colors.OKGREEN}{Colors.BOLD}Cài đặt hoàn tất!{Colors.ENDC}")
            print(f"{Colors.OKGREEN}Chạy file 'setup_env.bat' để thiết lập environment{Colors.ENDC}")
        else:
            print(f"\n{Colors.FAIL}{Colors.BOLD}Cài đặt thất bại!{Colors.ENDC}")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print(f"\n{Colors.WARNING}Cài đặt bị hủy bởi người dùng{Colors.ENDC}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.FAIL}Lỗi không mong muốn: {e}{Colors.ENDC}")
        sys.exit(1)

if __name__ == "__main__":
    main()
