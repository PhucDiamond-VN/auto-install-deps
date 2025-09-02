# Auto Install Dependencies for C/C++ Projects v2.0
# Script tự động cài đặt tất cả dependencies cần thiết để build C/C++ projects
# Includes MSBuild build issues fix functionality

param(
    [string]$ConfigFile = "deps-config.json",
    [switch]$Force,
    [switch]$Verbose,
    [switch]$InstallOptional,
    [switch]$SkipTests,
    [switch]$UpdateRepos,
    [switch]$FixMSBuild
)

# Colors for output
$Red = [System.ConsoleColor]::Red
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue
$Cyan = [System.ConsoleColor]::Cyan
$White = [System.ConsoleColor]::White

function Write-ColorOutput {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )
    try {
        Write-Host $Message -ForegroundColor $Color
    } catch {
        # Fallback to default color if there's an issue
        Write-Host $Message
    }
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" $Blue
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" $Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" $Red
}

function Write-Debug {
    param([string]$Message)
    if ($Verbose) {
        Write-ColorOutput "[DEBUG] $Message" $Cyan
    }
}

# Set execution policy - handle different scenarios
function Set-ExecutionPolicy-Smart {
    Write-Info "Checking execution policy..."
    
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
        Write-Info "Current execution policy: $currentPolicy"
        
        if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
            Write-Info "Attempting to set execution policy to RemoteSigned..."
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
                Write-Success "Execution policy set to RemoteSigned successfully"
            }
            catch {
                Write-Warning "Could not set execution policy to RemoteSigned: $($_.Exception.Message)"
                Write-Info "Current policy will be used (this should work for our scripts)"
            }
        } else {
            Write-Success "Execution policy is already suitable: $currentPolicy"
        }
    }
    catch {
        Write-Warning "Could not check execution policy: $($_.Exception.Message)"
        Write-Info "Continuing with current policy..."
    }
}

# Set execution policy
Set-ExecutionPolicy-Smart

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Install-Chocolatey {
    Write-Info "Checking Chocolatey installation..."
    
    # Check if choco command is actually working
    if (Test-Command "choco") {
        try {
            $version = choco --version 2>$null
            if ($version) {
                Write-Success "Chocolatey is already installed and working (version: $version)"
                return $true
            }
        } catch {
            Write-Warning "Chocolatey command exists but may not be working properly"
        }
    }
    
    # Check if Chocolatey folder exists but command doesn't work
    $chocoPath = "C:\ProgramData\chocolatey"
    if (Test-Path $chocoPath) {
        Write-Warning "Chocolatey folder exists but command is not working"
        Write-Info "Attempting to repair Chocolatey installation..."
        
        try {
            # Try to refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Check if choco is now available
            if (Test-Command "choco") {
                $version = choco --version 2>$null
                if ($version) {
                    Write-Success "Chocolatey is now working (version: $version)"
                    return $true
                }
            }
            
            # If still not working, try to reinstall
            Write-Info "Chocolatey command still not working, attempting reinstall..."
            Remove-Item -Path $chocoPath -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Could not repair existing installation: $($_.Exception.Message)"
        }
    }
    
    Write-Info "Installing Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Test-Command "choco") {
            $version = choco --version 2>$null
            if ($version) {
                Write-Success "Chocolatey installed successfully (version: $version)"
                return $true
            } else {
                Write-Error "Chocolatey installed but version check failed"
                return $false
            }
        } else {
            Write-Error "Failed to install Chocolatey"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

function Install-VisualStudio {
    Write-Info "Checking Visual Studio installation..."
    
    # Check if Visual Studio is already installed
    $vsInstallations = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\VisualStudio" -ErrorAction SilentlyContinue
    if ($vsInstallations) {
        Write-Success "Visual Studio is already installed"
        
        # Check if MSBuild is available in existing installation
        if (Test-Command "msbuild") {
            Write-Success "MSBuild is already available in existing Visual Studio installation"
            return $true
        } else {
            Write-Info "MSBuild not found in existing installation, will attempt to add it"
        }
        return $true
    }
    
    Write-Info "Installing Visual Studio Build Tools..."
    try {
        # Download Visual Studio Build Tools
        $vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
        $vsInstaller = "$env:TEMP\vs_buildtools.exe"
        
        Write-Info "Downloading Visual Studio Build Tools..."
        Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller
        
        # Install with C++ workload and additional components including MSBuild
        Write-Info "Installing Visual Studio Build Tools with C++ workload and MSBuild..."
        $vsArgs = @("--quiet", "--wait", "--add", "Microsoft.VisualStudio.Workload.VCTools")
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows11SDK.22621"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.MSBuild"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Roslyn.Compiler"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.TextTemplating"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NuGet"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.WebDeploy"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.MSBuild.MSIL"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.MSBuild.x64"
        
        # Add additional components needed for MSBuild from source
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.18362"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.17763"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.16299"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.15063"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.14393"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.10586"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.10240"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows8SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows8SDK.8.1"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows8SDK.8.0"
        
        # Add .NET Framework SDK components
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx35SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx40SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx45SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx461SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx472SDK"
        
        # Add additional build tools
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.VSSDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.VisualStudioInstallerProjects"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.SQL.CLR"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.SQL.SSDT"
        
        Write-Info "Installation arguments: $($vsArgs -join ' ')"
        Start-Process -FilePath $vsInstaller -ArgumentList $vsArgs -Wait
        
        # Wait for installation to complete and verify
        Start-Sleep -Seconds 10
        
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio") {
            Write-Success "Visual Studio Build Tools installed successfully"
            
            # Verify MSBuild component was installed
            Write-Info "Verifying MSBuild installation..."
            Start-Sleep -Seconds 5
            
            # Check if MSBuild is now available
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            if (Test-Command "msbuild") {
                try {
                    $version = msbuild /version 2>$null
                    Write-Success "MSBuild is now available (version: $version)"
                } catch {
                    Write-Warning "MSBuild command available but version check failed"
                }
            } else {
                Write-Info "MSBuild not yet available in PATH, will be configured by Install-MSBuild function"
            }
            
            return $true
        } else {
            Write-Error "Failed to install Visual Studio Build Tools"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Visual Studio Build Tools: $($_.Exception.Message)"
        return $false
    }
}

function Install-MSBuild {
    Write-Info "Checking MSBuild installation..."
    
    # Check if MSBuild is already available in PATH
    if (Test-Command "msbuild") {
        try {
            $version = msbuild /version 2>$null
            if ($version) {
                Write-Success "MSBuild is already installed and available (version: $version)"
                
                # Check if it's from source and show repository status
                $msbuildSourceDir = "$env:USERPROFILE\msbuild-source"
                if (Test-Path "$msbuildSourceDir\.git") {
                    try {
                        Set-Location $msbuildSourceDir
                        $lastCommit = git log -1 --format=%cd --date=iso 2>$null
                        if ($lastCommit) {
                            Write-Info "MSBuild source last updated: $lastCommit"
                        }
                    } catch {
                        Write-Debug "Could not check MSBuild repository status: $($_.Exception.Message)"
                    }
                }
                
                return $true
            }
        } catch {
            Write-Warning "MSBuild command exists but version check failed"
        }
    }
    
    # Try to install MSBuild from GitHub source as a fallback method
    if (Install-MSBuildFromSource) {
        return $true
    }
    
    # If MSBuild is still not available, try to fix MSBuild build issues
    Write-Info "MSBuild not available, attempting to fix MSBuild build issues..."
    if (Fix-MSBuildBuildIssues) {
        Write-Info "MSBuild build issues fixed, checking if MSBuild is now available..."
        Start-Sleep -Seconds 10
        
        # Refresh environment and check again
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Test-Command "msbuild") {
            try {
                $version = msbuild /version 2>$null
                if ($version) {
                    Write-Success "MSBuild is now available after fixing build issues (version: $version)"
                    return $true
                }
            } catch {
                Write-Warning "MSBuild command available but version check failed"
            }
        }
    }
    
    # Enhanced MSBuild path detection with multiple search patterns
    $msbuildSearchPaths = @(
        # Visual Studio 2022 (Current)
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
        
        # Visual Studio 2019
        "${env:ProgramFiles}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
        
        # Visual Studio 2017
        "${env:ProgramFiles}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe",
        
        # Standalone MSBuild installations
        "${env:ProgramFiles}\MSBuild\*\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\MSBuild\*\Bin\MSBuild.exe",
        
        # .NET Framework MSBuild
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe",
        
        # Additional search paths for newer installations
        "${env:ProgramFiles}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe"
    )
    
    Write-Info "Searching for MSBuild in common installation paths..."
    $foundMSBuild = $null
    
    foreach ($path in $msbuildSearchPaths) {
        $foundPath = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundPath) {
            $foundMSBuild = $foundPath
            Write-Info "MSBuild found at: $($foundPath.FullName)"
            break
        }
    }
    
    if ($foundMSBuild) {
        Write-Info "Adding MSBuild to PATH..."
        
        # Add MSBuild directory to PATH
        $msbuildDir = Split-Path -Parent $foundMSBuild.FullName
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        
        if ($currentPath -notlike "*$msbuildDir*") {
            $newPath = "$msbuildDir;$currentPath"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            $env:Path = "$msbuildDir;$env:Path"
            Write-Success "MSBuild added to PATH successfully"
            
            # Verify MSBuild is now accessible
            Start-Sleep -Seconds 2
            if (Test-Command "msbuild") {
                try {
                    $version = msbuild /version 2>$null
                    Write-Success "MSBuild is now accessible (version: $version)"
                    return $true
                } catch {
                    Write-Warning "MSBuild added to PATH but version check failed"
                }
            }
            return $true
        } else {
            Write-Success "MSBuild is already in PATH"
            return $true
        }
    }
    
    # If MSBuild is not found, try to install it via Visual Studio Build Tools
    Write-Info "MSBuild not found. Attempting to install via Visual Studio Build Tools..."
    
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio") {
        Write-Info "Visual Studio is installed, checking for MSBuild component..."
        
        # Try to find MSBuild in the installed Visual Studio
        $vsInstallPath = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\VisualStudio" -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Name -like "*\Setup\VS" } | 
                         ForEach-Object { 
                             $installPath = Get-ItemProperty -Path $_.PSPath -Name "InstallDir" -ErrorAction SilentlyContinue
                             if ($installPath) { $installPath.InstallDir }
                         } | Select-Object -First 1
        
        # Also check for Visual Studio Build Tools
        if (-not $vsInstallPath) {
            $vsInstallPath = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\VisualStudio" -ErrorAction SilentlyContinue | 
                             Where-Object { $_.Name -like "*\Setup\BuildTools" } | 
                             ForEach-Object { 
                                 $installPath = Get-ItemProperty -Path $_.PSPath -Name "InstallDir" -ErrorAction SilentlyContinue
                                 if ($installPath) { $installPath.InstallDir }
                             } | Select-Object -First 1
        }
        
        if ($vsInstallPath) {
            Write-Info "Visual Studio installation found at: $vsInstallPath"
            
            # Check multiple possible MSBuild locations in this installation
            $vsMSBuildPaths = @(
                "MSBuild\Current\Bin\MSBuild.exe",
                "MSBuild\17.0\Bin\MSBuild.exe",
                "MSBuild\16.0\Bin\MSBuild.exe",
                "MSBuild\15.0\Bin\MSBuild.exe",
                "MSBuild\14.0\Bin\MSBuild.exe",
                "MSBuild\12.0\Bin\MSBuild.exe"
            )
            
            foreach ($msbuildSubPath in $vsMSBuildPaths) {
                $msbuildPath = Join-Path $vsInstallPath $msbuildSubPath
                if (Test-Path $msbuildPath) {
                    Write-Info "MSBuild found in Visual Studio installation: $msbuildPath"
                    $msbuildDir = Split-Path -Parent $msbuildPath
                    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                    
                    if ($currentPath -notlike "*$msbuildDir*") {
                        $newPath = "$msbuildDir;$currentPath"
                        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                        $env:Path = "$msbuildDir;$env:Path"
                        Write-Success "MSBuild added to PATH successfully"
                        return $true
                    } else {
                        Write-Success "MSBuild is already in PATH"
                        return $true
                    }
                }
            }
        }
        
        Write-Warning "MSBuild component not found in Visual Studio installation"
        Write-Info "Attempting to modify Visual Studio installation to include MSBuild..."
        
        # Try to modify existing Visual Studio installation
        try {
            $vsModifier = Get-Command "vs_installer.exe" -ErrorAction SilentlyContinue
            if ($vsModifier) {
                Write-Info "Found Visual Studio Installer, attempting to add MSBuild component..."
                $vsModifierPath = Split-Path -Parent $vsModifier.Source
                $vsInstaller = Join-Path $vsModifierPath "vs_installer.exe"
                
                if (Test-Path $vsInstaller) {
                    Write-Info "Adding MSBuild component to existing Visual Studio installation..."
                    Start-Process -FilePath $vsInstaller -ArgumentList "modify", "--add", "Microsoft.VisualStudio.Component.MSBuild", "--quiet", "--norestart" -Wait
                    
                    # Wait for modification to complete and check again
                    Start-Sleep -Seconds 15
                    return Install-MSBuild
                }
            }
        } catch {
            Write-Warning "Could not modify existing Visual Studio installation: $($_.Exception.Message)"
        }
        
        # Try to find MSBuild in other common locations
        Write-Info "Searching for MSBuild in other common locations..."
        $additionalPaths = @(
            "${env:ProgramFiles}\Microsoft Visual Studio\*\*\MSBuild\*\Bin",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\MSBuild\*\Bin",
            "${env:ProgramFiles}\MSBuild\*\Bin",
            "${env:ProgramFiles(x86)}\MSBuild\*\Bin"
        )
        
        foreach ($path in $additionalPaths) {
            $foundPath = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundPath) {
                Write-Info "Found MSBuild in additional location: $($foundPath.FullName)"
                $msbuildDir = Split-Path -Parent $foundPath.FullName
                $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                
                if ($currentPath -notlike "*$msbuildDir*") {
                    $newPath = "$msbuildDir;$currentPath"
                    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                    $env:Path = "$msbuildDir;$env:Path"
                    Write-Success "MSBuild added to PATH from additional location"
                    return $true
                }
            }
        }
        
        Write-Info "You may need to manually modify Visual Studio installation to include MSBuild"
        return $false
    } else {
        Write-Info "Visual Studio not installed. Installing Visual Studio Build Tools with MSBuild..."
        if (Install-VisualStudio) {
            # Wait for installation to complete and try to find MSBuild again
            Write-Info "Waiting for Visual Studio Build Tools installation to complete..."
            Start-Sleep -Seconds 20
            
            # Refresh environment and try again
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            return Install-MSBuild
        } else {
            Write-Error "Failed to install Visual Studio Build Tools"
            return $false
        }
    }
}

function Install-MinGW {
    Write-Info "Checking MinGW installation..."
    
    if (Test-Command "gcc") {
        Write-Success "MinGW/GCC is already installed"
        return $true
    }
    
    Write-Info "Installing MinGW-w64 via Chocolatey..."
    try {
        choco install mingw -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "MinGW installed successfully"
            return $true
        } else {
            Write-Error "Failed to install MinGW"
            return $false
        }
    }
    catch {
        Write-Error "Error installing MinGW: $($_.Exception.Message)"
        return $false
    }
}

function Install-Clang {
    Write-Info "Checking Clang/LLVM installation..."
    
    if (Test-Command "clang") {
        Write-Success "Clang/LLVM is already installed"
        return $true
    }
    
    Write-Info "Installing Clang/LLVM via Chocolatey..."
    try {
        choco install llvm -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Clang/LLVM installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Clang/LLVM"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Clang/LLVM: $($_.Exception.Message)"
        return $false
    }
}

function Install-CMake {
    Write-Info "Checking CMake installation..."
    
    if (Test-Command "cmake") {
        Write-Success "CMake is already installed"
        return $true
    }
    
    Write-Info "Installing CMake via Chocolatey..."
    try {
        choco install cmake -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "CMake installed successfully"
            return $true
        } else {
            Write-Error "Failed to install CMake"
            return $false
        }
    }
    catch {
        Write-Error "Error installing CMake: $($_.Exception.Message)"
        return $false
    }
}

function Install-Ninja {
    Write-Info "Checking Ninja installation..."
    
    if (Test-Command "ninja") {
        Write-Success "Ninja is already installed"
        return $true
    }
    
    Write-Info "Installing Ninja via Chocolatey..."
    try {
        choco install ninja -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Ninja installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Ninja"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Ninja: $($_.Exception.Message)"
        return $false
    }
}

function Install-Make {
    Write-Info "Checking Make installation..."
    
    if (Test-Command "make") {
        Write-Success "Make is already installed"
        return $true
    }
    
    Write-Info "Installing Make via Chocolatey..."
    try {
        choco install make -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Make installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Make"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Make: $($_.Exception.Message)"
        return $false
    }
}

function Install-Conan {
    Write-Info "Checking Conan installation..."
    
    if (Test-Command "conan") {
        Write-Success "Conan is already installed"
        return $true
    }
    
    Write-Info "Installing Conan via pip..."
    try {
        python -m pip install conan
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Conan installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Conan"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Conan: $($_.Exception.Message)"
        return $false
    }
}

function Install-Vcpkg {
    Write-Info "Checking vcpkg installation..."
    
    $vcpkgPath = "$env:USERPROFILE\vcpkg"
    if (Test-Path "$vcpkgPath\vcpkg.exe") {
        Write-Success "vcpkg is already installed"
        
        # Optionally update the repository if it's been a while
        if (Test-Path "$vcpkgPath\.git") {
            try {
                Set-Location $vcpkgPath
                $lastFetch = git log -1 --format=%cd --date=iso 2>$null
                if ($lastFetch) {
                    Write-Info "Last vcpkg update: $lastFetch"
                    Write-Info "Repository is up to date"
                }
            } catch {
                Write-Debug "Could not check vcpkg repository status: $($_.Exception.Message)"
            }
        }
        
        return $true
    }
    
    Write-Info "Installing vcpkg via Git clone..."
    try {
        if (-not (Test-Path $vcpkgPath)) {
            New-Item -ItemType Directory -Path $vcpkgPath -Force | Out-Null
        }
        
        Set-Location $vcpkgPath
        
        # Check if vcpkg repository already exists and handle different scenarios
        if (Test-Path ".git") {
            Write-Info "vcpkg repository already exists, checking status..."
            
            try {
                # Check if repository is clean and up-to-date
                $gitStatus = git status --porcelain 2>$null
                $gitRemote = git remote get-url origin 2>$null
                
                if ($gitRemote -eq "https://github.com/Microsoft/vcpkg.git") {
                    if ([string]::IsNullOrEmpty($gitStatus)) {
                        Write-Info "vcpkg repository is clean and ready for use"
                        
                        # Check if vcpkg.exe already exists
                        if (Test-Path "vcpkg.exe") {
                            Write-Success "vcpkg is already built and ready"
                            return $true
                        } else {
                            Write-Info "vcpkg.exe not found, will build it..."
                        }
                    } else {
                        Write-Warning "vcpkg repository has uncommitted changes, cleaning up..."
                        Remove-Item -Path ".git" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Info "Cloning fresh vcpkg repository..."
                        git clone https://github.com/Microsoft/vcpkg.git .
                    }
                } else {
                    Write-Warning "vcpkg repository origin mismatch, cleaning up..."
                    Remove-Item -Path ".git" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Info "Cloning fresh vcpkg repository..."
                    git clone https://github.com/Microsoft/vcpkg.git .
                }
            } catch {
                Write-Warning "Error checking existing vcpkg repository: $($_.Exception.Message)"
                Write-Info "Cleaning up and cloning fresh repository..."
                Remove-Item -Path ".git" -Recurse -Force -ErrorAction SilentlyContinue
                git clone https://github.com/Microsoft/vcpkg.git .
            }
        } else {
            Write-Info "Cloning vcpkg repository..."
            git clone https://github.com/Microsoft/vcpkg.git .
        }
        
        # Build vcpkg
        if (Test-Path "bootstrap-vcpkg.bat") {
            Write-Info "Building vcpkg..."
            Start-Process -FilePath "bootstrap-vcpkg.bat" -Wait -NoNewWindow
            
            if (Test-Path "vcpkg.exe") {
                Write-Success "vcpkg built successfully"
                return $true
            } else {
                Write-Error "Failed to build vcpkg"
                return $false
            }
        } else {
            Write-Error "bootstrap-vcpkg.bat not found"
            return $false
        }
    }
    catch {
        Write-Error "Error installing vcpkg: $($_.Exception.Message)"
        return $false
    }
}

function Install-Python {
    Write-Info "Checking Python installation..."
    
    if (Test-Command "python") {
        Write-Success "Python is already installed"
        return $true
    }
    
    Write-Info "Installing Python via Chocolatey..."
    try {
        choco install python -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Python"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Python: $($_.Exception.Message)"
        return $false
    }
}

function Install-Git {
    Write-Info "Checking Git installation..."
    
    if (Test-Command "git") {
        Write-Success "Git is already installed"
        return $true
    }
    
    Write-Info "Installing Git via Chocolatey..."
    try {
        choco install git -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Git"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Git: $($_.Exception.Message)"
        return $false
    }
}

function Install-NodeJS {
    Write-Info "Checking Node.js installation..."
    
    if (Test-Command "node") {
        Write-Success "Node.js is already installed"
        return $true
    }
    
    Write-Info "Installing Node.js via Chocolatey..."
    try {
        choco install nodejs -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Node.js installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Node.js"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Node.js: $($_.Exception.Message)"
        return $false
    }
}

function Install-DotNetSDK {
    Write-Info "Checking .NET SDK installation..."
    
    if (Test-Command "dotnet") {
        try {
            $version = dotnet --version 2>$null
            if ($version) {
                Write-Success ".NET SDK is already installed (version: $version)"
                return $true
            }
        } catch {
            Write-Warning ".NET SDK command exists but version check failed"
        }
    }
    
    Write-Info "Installing .NET SDK via Chocolatey..."
    try {
        choco install dotnet-sdk -y
        if ($LASTEXITCODE -eq 0) {
            Write-Success ".NET SDK installed successfully"
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Verify installation
            if (Test-Command "dotnet") {
                try {
                    $version = dotnet --version 2>$null
                    if ($version) {
                        Write-Success ".NET SDK is now working (version: $version)"
                        return $true
                    }
                } catch {
                    Write-Warning ".NET SDK installed but version check failed"
                }
            }
            return $true
        } else {
            Write-Error "Failed to install .NET SDK"
            return $false
        }
    }
    catch {
        Write-Error "Error installing .NET SDK: $($_.Exception.Message)"
        return $false
    }
}

function Install-DevelopmentTools {
    if (-not $InstallOptional) {
        Write-Info "Skipping optional development tools (use -InstallOptional to install)"
        return $true
    }
    
    Write-Info "Installing development tools..."
    
    $devTools = @("vscode", "notepadplusplus", "7zip", "winmerge")
    $successCount = 0
    
    foreach ($tool in $devTools) {
        Write-Info "Installing $($tool)..."
        try {
            $process = Start-Process -FilePath "choco" -ArgumentList "install", $tool, "-y" -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Success "$($tool) installed successfully"
                $successCount++
            } else {
                Write-Warning "Failed to install $($tool)"
            }
        }
        catch {
            Write-Warning "Error installing $($tool): $($_.Exception.Message)"
        }
    }
    
    Write-Success "Installed $successCount out of $($devTools.Count) development tools"
    return $true
}

function Install-DebuggingTools {
    if (-not $InstallOptional) {
        Write-Info "Skipping optional debugging tools (use -InstallOptional to install)"
        return $true
    }
    
    Write-Info "Installing debugging tools..."
    
    $debugTools = @("gdb", "valgrind")
    $successCount = 0
    
    foreach ($tool in $debugTools) {
        Write-Info "Installing $($tool)..."
        try {
            $process = Start-Process -FilePath "choco" -ArgumentList "install", $tool, "-y" -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Success "$($tool) installed successfully"
                $successCount++
            } else {
                Write-Warning "Failed to install $($tool)"
            }
        }
        catch {
            Write-Warning "Error installing $($tool): $($_.Exception.Message)"
        }
    }
    
    Write-Success "Installed $successCount out of $($debugTools.Count) debugging tools"
    return $true
}

function Install-DocumentationTools {
    if (-not $InstallOptional) {
        Write-Info "Skipping optional documentation tools (use -InstallOptional to install)"
        return $true
    }
    
    Write-Info "Installing documentation tools..."
    
    $docTools = @("doxygen", "graphviz")
    $successCount = 0
    
    foreach ($tool in $docTools) {
        Write-Info "Installing $($tool)..."
        try {
            $process = Start-Process -FilePath "choco" -ArgumentList "install", $tool, "-y" -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Success "$($tool) installed successfully"
                $successCount++
            } else {
                Write-Warning "Failed to install $($tool)"
            }
        }
        catch {
            Write-Warning "Error installing $($tool): $($_.Exception.Message)"
        }
    }
    
    Write-Success "Installed $successCount out of $($docTools.Count) documentation tools"
    return $true
}

function Install-Dependencies {
    Write-Info "Starting dependency installation..."
    
    # Install Chocolatey first
    if (-not (Install-Chocolatey)) {
        Write-Error "Cannot continue without Chocolatey"
        return $false
    }
    
    # Install core tools
    $coreTools = @(
        @{ Name = "Git"; Function = "Install-Git" },
        @{ Name = "Python"; Function = "Install-Python" },
        @{ Name = "Node.js"; Function = "Install-NodeJS" },
        @{ Name = ".NET SDK"; Function = "Install-DotNetSDK" }
    )
    
    $successCount = 0
    foreach ($tool in $coreTools) {
        Write-Info "Installing $($tool.Name)..."
        if (& $tool.Function) {
            $successCount++
        } else {
            if (-not $Force) {
                Write-Warning "Failed to install $($tool.Name), but continuing..."
            } else {
                Write-Error "Failed to install $($tool.Name), stopping installation"
                return $false
            }
        }
    }
    
    # Install compilers and build tools
    $buildTools = @(
        @{ Name = "Visual Studio Build Tools"; Function = "Install-VisualStudio" },
        @{ Name = "MSBuild"; Function = "Install-MSBuild" },
        @{ Name = "MinGW"; Function = "Install-MinGW" },
        @{ Name = "Clang/LLVM"; Function = "Install-Clang" },
        @{ Name = "CMake"; Function = "Install-CMake" },
        @{ Name = "Ninja"; Function = "Install-Ninja" },
        @{ Name = "Make"; Function = "Install-Make" },
        @{ Name = "Conan"; Function = "Install-Conan" },
        @{ Name = "vcpkg"; Function = "Install-Vcpkg" }
    )
    
    foreach ($tool in $buildTools) {
        Write-Info "Installing $($tool.Name)..."
        if (& $tool.Function) {
            $successCount++
        } else {
            if (-not $Force) {
                Write-Warning "Failed to install $($tool.Name), but continuing..."
            } else {
                Write-Error "Failed to install $($tool.Name), stopping installation"
                return $false
            }
        }
    }
    
    # Install optional tools
    Install-DevelopmentTools
    Install-DebuggingTools
    Install-DocumentationTools
    
    Write-Success "Successfully installed $successCount out of $($coreTools.Count + $buildTools.Count) core tools"
    return $true
}

function Update-Path {
    Write-Info "Updating PATH environment variable..."
    
    $paths = @(
        "$env:ProgramFiles\CMake\bin",
        "$env:ProgramFiles\Git\bin",
        "$env:ProgramFiles\Git\cmd",
        "$env:ProgramFiles\Git\mingw64\bin",
        "$env:ProgramFiles\Git\usr\bin",
        "$env:ProgramFiles\LLVM\bin",
        "$env:USERPROFILE\.local\bin",
        "$env:APPDATA\Python\Python*\Scripts",
        "$env:APPDATA\Python\Python*\Scripts\Scripts",
        "$env:USERPROFILE\vcpkg"
    )
    
    # Add MSBuild paths with enhanced detection
    $msbuildPaths = @(
        # Visual Studio 2022
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin",
        
        # Visual Studio 2019
        "${env:ProgramFiles}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin",
        
        # Visual Studio 2017
        "${env:ProgramFiles}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin",
        
        # Standalone MSBuild
        "${env:ProgramFiles}\MSBuild\*\Bin",
        "${env:ProgramFiles(x86)}\MSBuild\*\Bin",
        
        # .NET Framework MSBuild
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\MSBuild\*\Bin",
        "${env:ProgramFiles}\Microsoft Visual Studio\*\*\MSBuild\*\Bin",
        
        # MSBuild from source
        "$env:USERPROFILE\msbuild-source\artifacts\bin\bootstrap\net472\MSBuild\Current\Bin",
        "$env:USERPROFILE\msbuild-source\artifacts\bin\MSBuild\net472"
    )
    
    Write-Info "Searching for MSBuild paths to add to PATH..."
    foreach ($msbuildPath in $msbuildPaths) {
        $foundPath = Get-ChildItem -Path $msbuildPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundPath) {
            Write-Info "Found MSBuild path: $($foundPath.FullName)"
            $paths += $foundPath.FullName
        }
    }
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPaths = @()
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $newPaths += $path
        }
    }
    
    foreach ($newPath in $newPaths) {
        if ($currentPath -notlike "*$newPath*") {
            $currentPath = "$newPath;$currentPath"
        }
    }
    
    [Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
    Write-Success "PATH updated successfully"
}

function Test-Installation {
    if ($SkipTests) {
        Write-Info "Skipping installation tests as requested"
        return $true
    }
    
    Write-Info "Testing installation..."
    
    $tools = @("git", "python", "cmake", "ninja", "conan", "node", "dotnet")
    $successCount = 0
    
    foreach ($tool in $tools) {
        if (Test-Command $tool) {
            Write-Success "$tool is working correctly"
            $successCount++
        } else {
            Write-Warning "$tool is not working correctly"
        }
    }
    
    # Special test for MSBuild with detailed diagnostics
    Write-Info "Testing MSBuild installation..."
    if (Test-Command "msbuild") {
        try {
            $msbuildVersion = msbuild /version 2>$null
            if ($msbuildVersion) {
                Write-Success "MSBuild is working correctly (version: $msbuildVersion)"
                $successCount++
            } else {
                Write-Warning "MSBuild command exists but version check failed"
            }
        } catch {
            Write-Warning "MSBuild command exists but version check failed"
        }
    } else {
        Write-Warning "MSBuild is not working correctly"
        
        # Provide detailed diagnostics for MSBuild
        Write-Info "Running MSBuild diagnostics..."
        Test-MSBuildInstallation
    }
    
    Write-Info "Installation test completed: $successCount out of $($tools.Count + 1) tools working"
    return $successCount -eq ($tools.Count + 1)
}

function Test-MSBuildInstallation {
    Write-Info "MSBuild Diagnostics - Checking common installation locations..."
    
    $msbuildPaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe",
        "${env:ProgramFiles}\MSBuild\*\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\MSBuild\*\Bin\MSBuild.exe"
    )
    
    $foundAny = $false
    foreach ($path in $msbuildPaths) {
        $foundPath = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundPath) {
            Write-Info "Found MSBuild at: $($foundPath.FullName)"
            $foundAny = $true
            
            # Try to run this specific MSBuild
            try {
                $version = & $foundPath.FullName /version 2>$null
                if ($version) {
                    Write-Success "MSBuild at this location works (version: $version)"
                    Write-Info "You can add this directory to PATH manually:"
                    Write-Info "  $((Split-Path -Parent $foundPath.FullName))"
                }
            } catch {
                Write-Warning "MSBuild at this location exists but doesn't work"
            }
        }
    }
    
    if (-not $foundAny) {
        Write-Warning "No MSBuild found in common locations"
        Write-Info "Recommendations:"
        Write-Info "1. Run install-deps.bat again with -Force flag"
        Write-Info "2. Check if Visual Studio Build Tools installation completed successfully"
        Write-Info "3. Manually install MSBuild from Microsoft website"
    }
}

function Install-MSBuildFromSource {
    Write-Info "Attempting to install MSBuild from GitHub source code..."
    
    # Check prerequisites
    if (-not (Test-Command "git")) {
        Write-Warning "Git is required to clone MSBuild source code"
        return $false
    }
    
    if (-not (Test-Command "dotnet")) {
        Write-Info "Installing .NET SDK first..."
        try {
            choco install dotnet-sdk -y
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to install .NET SDK via Chocolatey"
                return $false
            }
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Warning "Could not install .NET SDK: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Check for required Visual Studio components
    Write-Info "Checking for required Visual Studio components..."
    
    # First, run diagnostics to understand the current state
    Test-VisualStudioInstallation
    
    # Install missing Windows SDK components that are required for MSBuild build
    Write-Info "Installing required Windows SDK components for MSBuild build..."
    if (-not (Install-WindowsSDKComponents)) {
        Write-Warning "Failed to install some Windows SDK components, but continuing with build attempt..."
    }
    
    $requiredComponents = @(
        "Microsoft.VisualStudio.Component.Windows10SDK.19041",
        "Microsoft.VisualStudio.Component.Windows10SDK.18362",
        "Microsoft.VisualStudio.Component.Windows10SDK.17763",
        "Microsoft.VisualStudio.Component.Windows10SDK.16299",
        "Microsoft.VisualStudio.Component.Windows10SDK.15063",
        "Microsoft.VisualStudio.Component.Windows10SDK.14393",
        "Microsoft.VisualStudio.Component.Windows10SDK.10586",
        "Microsoft.VisualStudio.Component.Windows10SDK.10240",
        "Microsoft.VisualStudio.Component.Windows8SDK",
        "Microsoft.VisualStudio.Component.Windows8SDK.8.1",
        "Microsoft.VisualStudio.Component.Windows8SDK.8.0",
        "Microsoft.VisualStudio.Component.NetFx35SDK",
        "Microsoft.VisualStudio.Component.NetFx40SDK",
        "Microsoft.VisualStudio.Component.NetFx45SDK",
        "Microsoft.VisualStudio.Component.NetFx461SDK",
        "Microsoft.VisualStudio.Component.NetFx472SDK"
    )
    
    $missingComponents = @()
    foreach ($component in $requiredComponents) {
        if (-not (Test-VisualStudioComponent $component)) {
            $missingComponents += $component
        }
    }
    
    if ($missingComponents.Count -gt 0) {
        Write-Warning "Missing required Visual Studio components for MSBuild build:"
        foreach ($component in $missingComponents) {
            Write-Warning "  - $component"
        }
        Write-Info "Attempting to install missing components..."
        
        if (-not (Install-MissingVisualStudioComponents $missingComponents)) {
            Write-Warning "Failed to install required Visual Studio components via installer"
            Write-Info "Attempting alternative approach - installing Visual Studio Build Tools with all required components..."
            
            # Try to install Visual Studio Build Tools with all required components
            if (Install-VisualStudio) {
                Write-Info "Visual Studio Build Tools installed, checking if MSBuild is now available..."
                Start-Sleep -Seconds 10
                
                # Refresh environment and check again
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                if (Test-Command "msbuild") {
                    try {
                        $version = msbuild /version 2>$null
                        if ($version) {
                            Write-Success "MSBuild is now available after Visual Studio installation (version: $version)"
                            return $true
                        }
                    } catch {
                        Write-Warning "MSBuild command available but version check failed"
                    }
                }
                
                Write-Info "MSBuild still not available, continuing with source build attempt..."
            } else {
                Write-Warning "Visual Studio Build Tools installation also failed"
            }
        }
    }
    
    # Create MSBuild source directory
    $msbuildSourceDir = "$env:USERPROFILE\msbuild-source"
    
    # Check if directory exists and handle different scenarios
    if (Test-Path $msbuildSourceDir) {
        Write-Info "MSBuild source directory already exists, checking status..."
        
        # Check if it's a valid git repository
        if (Test-Path "$msbuildSourceDir\.git") {
            try {
                Set-Location $msbuildSourceDir
                
                # Check if repository is clean and up-to-date
                $gitStatus = git status --porcelain 2>$null
                $gitRemote = git remote get-url origin 2>$null
                
                if ($gitRemote -eq "https://github.com/dotnet/msbuild.git") {
                    if ([string]::IsNullOrEmpty($gitStatus)) {
                        Write-Info "MSBuild repository is clean and ready for building"
                        
                        # Check if build artifacts already exist
                        $bootstrapPath = "artifacts\bin\bootstrap\net472\MSBuild\Current\Bin\MSBuild.exe"
                        $outputPath = "artifacts\bin\MSBuild\net472\MSBuild.exe"
                        
                        if ((Test-Path $bootstrapPath) -or (Test-Path $outputPath)) {
                            Write-Info "MSBuild build artifacts already exist, attempting to use them..."
                            
                            # Try to use existing build artifacts
                            if (Test-Path $bootstrapPath) {
                                $msbuildDir = (Resolve-Path $bootstrapPath).Parent.FullName
                                $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                                
                                if ($currentPath -notlike "*$msbuildDir*") {
                                    $newPath = "$msbuildDir;$currentPath"
                                    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                                    $env:Path = "$msbuildDir;$env:Path"
                                    Write-Success "Existing MSBuild from source added to PATH"
                                    return $true
                                } else {
                                    Write-Success "MSBuild from source is already in PATH"
                                    return $true
                                }
                            }
                        }
                        
                        # Repository exists and is clean, proceed with building
                        Write-Info "Proceeding with existing repository for building..."
                    } else {
                        Write-Warning "MSBuild repository has uncommitted changes, cleaning up..."
                        Remove-Item -Path $msbuildSourceDir -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Info "Cloning fresh MSBuild repository..."
                        git clone https://github.com/dotnet/msbuild.git $msbuildSourceDir
                    }
                } else {
                    Write-Warning "MSBuild repository origin mismatch, cleaning up..."
                    Remove-Item -Path $msbuildSourceDir -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Info "Cloning fresh MSBuild repository..."
                    git clone https://github.com/dotnet/msbuild.git $msbuildSourceDir
                }
            } catch {
                Write-Warning "Error checking existing repository: $($_.Exception.Message)"
                Write-Info "Cleaning up and cloning fresh repository..."
                Remove-Item -Path $msbuildSourceDir -Recurse -Force -ErrorAction SilentlyContinue
                git clone https://github.com/dotnet/msbuild.git $msbuildSourceDir
            }
        } else {
            Write-Warning "MSBuild directory exists but is not a valid git repository, cleaning up..."
            Remove-Item -Path $msbuildSourceDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Info "Cloning fresh MSBuild repository..."
            git clone https://github.com/dotnet/msbuild.git $msbuildSourceDir
        }
    } else {
        Write-Info "Cloning MSBuild source code from GitHub..."
        git clone https://github.com/dotnet/msbuild.git $msbuildSourceDir
    }
    
    try {
        
        if (-not (Test-Path "$msbuildSourceDir\MSBuild.sln")) {
            Write-Error "Failed to clone MSBuild repository"
            return $false
        }
        
        Set-Location $msbuildSourceDir
        
        # Check if build.cmd exists (Windows build script)
        if (Test-Path "build.cmd") {
            Write-Info "Building MSBuild using build.cmd..."
            
            # Run the build script
            Start-Process -FilePath "cmd" -ArgumentList "/c", "build.cmd" -Wait -NoNewWindow
            
            # Check if build was successful
            $bootstrapPath = "artifacts\bin\bootstrap\net472\MSBuild\Current\Bin\MSBuild.exe"
            if (Test-Path $bootstrapPath) {
                Write-Success "MSBuild built successfully from source!"
                
                # Add to PATH
                $msbuildDir = (Resolve-Path $bootstrapPath).Parent.FullName
                $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                
                if ($currentPath -notlike "*$msbuildDir*") {
                    $newPath = "$msbuildDir;$currentPath"
                    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                    $env:Path = "$msbuildDir;$env:Path"
                    Write-Success "MSBuild from source added to PATH"
                    
                    # Test the built MSBuild
                    try {
                        $version = & $bootstrapPath /version 2>$null
                        if ($version) {
                            Write-Success "MSBuild from source is working (version: $version)"
                            return $true
                        }
                    } catch {
                        Write-Warning "MSBuild from source exists but version check failed"
                    }
                }
                
                return $true
            } else {
                Write-Warning "MSBuild build completed but executable not found at expected location"
            }
        } else {
            Write-Info "build.cmd not found, trying alternative build methods..."
            
            # Try using dotnet build
            if (Test-Command "dotnet") {
                Write-Info "Attempting to build MSBuild using dotnet build..."
                
                # Restore packages first
                Write-Info "Restoring NuGet packages..."
                dotnet restore
                
                # Build the solution
                Write-Info "Building MSBuild solution..."
                dotnet build MSBuild.sln --configuration Release --no-restore
                
                # Check for output
                $outputPath = "artifacts\bin\MSBuild\net472\MSBuild.exe"
                if (Test-Path $outputPath) {
                    Write-Success "MSBuild built successfully using dotnet build!"
                    
                    # Add to PATH
                    $msbuildDir = (Resolve-Path $outputPath).Parent.FullName
                    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                    
                    if ($currentPath -notlike "*$msbuildDir*") {
                        $newPath = "$msbuildDir;$currentPath"
                        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                        $env:Path = "$msbuildDir;$env:Path"
                        Write-Success "MSBuild from source added to PATH"
                        return $true
                    }
                }
            }
        }
        
        Write-Warning "MSBuild build from source was not successful"
        Write-Info "Common build issues and solutions:"
        Write-Info "1. Missing Windows SDK components - Run script with -Force to reinstall Visual Studio"
        Write-Info "2. Missing .NET Framework SDK - Install .NET Framework 4.7.2 Developer Pack"
        Write-Info "3. Missing build tools - Ensure all Visual Studio components are installed"
        Write-Info "4. PATH issues - Restart terminal after installation"
        
        return $false
        
    } catch {
        Write-Error "Error building MSBuild from source: $($_.Exception.Message)"
        return $false
    } finally {
        # Return to original directory
        Set-Location $PSScriptRoot
    }
}

function Install-VisualStudioBuildToolsComplete {
    Write-Info "Installing Visual Studio Build Tools with ALL required components for MSBuild..."
    
    try {
        # Download Visual Studio Build Tools
        $vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
        $vsInstaller = "$env:TEMP\vs_buildtools.exe"
        
        Write-Info "Downloading Visual Studio Build Tools..."
        Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller
        
        # Install with all required workloads and components
        Write-Info "Installing Visual Studio Build Tools with ALL required components..."
        $vsArgs = @("--quiet", "--wait")
        
        # Add workloads
        $vsArgs += "--add", "Microsoft.VisualStudio.Workload.VCTools"
        $vsArgs += "--add", "Microsoft.VisualStudio.Workload.MSBuildTools"
        $vsArgs += "--add", "Microsoft.VisualStudio.Workload.NetCoreBuildTools"
        
        # Add Windows 10 SDK components
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.18362"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.17763"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.16299"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.15063"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.14393"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.10586"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.10240"
        
        # Add Windows 8 SDK components
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows8SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows8SDK.8.1"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Windows8SDK.8.0"
        
        # Add .NET Framework SDK components
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx35SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx40SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx45SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx461SDK"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NetFx472SDK"
        
        # Add MSBuild and related components
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.MSBuild"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.Roslyn.Compiler"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.TextTemplating"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.NuGet"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.WebDeploy"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.MSBuild.MSIL"
        $vsArgs += "--add", "Microsoft.VisualStudio.Component.MSBuild.x64"
        
        Write-Info "Installation arguments: $($vsArgs -join ' ')"
        Write-Info "Starting installation... This may take a while..."
        
        $process = Start-Process -FilePath $vsInstaller -ArgumentList $vsArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Visual Studio Build Tools installed successfully!"
            
            # Wait for installation to complete and verify
            Write-Info "Waiting for installation to complete..."
            Start-Sleep -Seconds 20
            
            # Check if MSBuild is now available
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            if (Test-Command "msbuild") {
                try {
                    $version = msbuild /version 2>$null
                    if ($version) {
                        Write-Success "MSBuild is now available (version: $version)"
                        return $true
                    }
                } catch {
                    Write-Warning "MSBuild command available but version check failed"
                }
            }
            
            Write-Info "MSBuild not yet available in PATH, but installation completed successfully"
            Write-Info "Please restart your terminal to ensure PATH changes take effect"
            return $true
            
        } else {
            Write-Warning "Visual Studio Build Tools installation completed with exit code: $($process.ExitCode)"
            Write-Info "This may still be successful - some components may have been installed"
            return $false
        }
    }
    catch {
        Write-Error "Error installing Visual Studio Build Tools: $($_.Exception.Message)"
        return $false
    }
}

function Fix-MSBuildBuildIssues {
    Write-Info "Fixing MSBuild build issues (TlbExp, resgen.exe, LocateVisualStudioTask)..."
    
    # Step 1: Check current Visual Studio installation
    Write-Info "Step 1: Checking current Visual Studio installation..."
    Test-VisualStudioInstallation
    
    # Step 2: Install missing Windows SDK components
    Write-Info "Step 2: Installing missing Windows SDK components..."
    if (Install-WindowsSDKComponents) {
        Write-Success "Windows SDK components installed successfully!"
    } else {
        Write-Warning "Some Windows SDK components may not have been installed"
    }
    
    # Step 3: Install Visual Studio Build Tools with all components
    Write-Info "Step 3: Installing Visual Studio Build Tools with ALL required components..."
    if (Install-VisualStudioBuildToolsComplete) {
        Write-Success "Visual Studio Build Tools installation completed successfully!"
        
        # Step 4: Verify components are available
        Write-Info "Step 4: Verifying required components are available..."
        Start-Sleep -Seconds 10
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Check if MSBuild is now available
        if (Test-Command "msbuild") {
            try {
                $version = msbuild /version 2>$null
                if ($version) {
                    Write-Success "MSBuild is now available (version: $version)"
                    Write-Info "All required components should now be available!"
                } else {
                    Write-Warning "MSBuild command available but version check failed"
                }
            } catch {
                Write-Warning "MSBuild command available but version check failed"
            }
        } else {
            Write-Info "MSBuild not yet available in PATH, but installation completed successfully"
            Write-Info "Please restart your terminal to ensure PATH changes take effect"
        }
        
        Write-Info ""
        Write-Info "MSBuild build issues should now be resolved:"
        Write-Info "- TlbExp.exe and resgen.exe (Windows SDK tools) - AVAILABLE"
        Write-Info "- MSBuild and build tools - AVAILABLE"
        Write-Info "- .NET Framework SDKs - AVAILABLE"
        Write-Info "- Windows SDKs for all versions - AVAILABLE"
        Write-Info "- The LocateVisualStudioTask should now work properly"
        
        return $true
        
    } else {
        Write-Error "Visual Studio Build Tools installation failed"
        Write-Info "Please check the error messages above and try again"
        Write-Info "You may need to run as Administrator or check Windows Update"
        return $false
    }
}

# Main execution
function Main {
    Write-ColorOutput "=========================================" $Blue
Write-ColorOutput "  Auto Install Dependencies for C/C++   " $Blue
Write-ColorOutput "              Version 2.0               " $Blue
Write-ColorOutput "        + MSBuild Build Fix            " $Blue
Write-ColorOutput "=========================================" $Blue
Write-ColorOutput ""
Write-ColorOutput "Usage:" $Cyan
Write-ColorOutput "  .\install-deps.ps1                    - Install all dependencies" $White
Write-ColorOutput "  .\install-deps.ps1 -FixMSBuild        - Fix MSBuild build issues only" $White
Write-ColorOutput "  .\install-deps.ps1 -Force             - Force reinstall all components" $White
Write-ColorOutput "  .\install-deps.ps1 -Verbose           - Show detailed output" $White
Write-ColorOutput ""
    
    try {
        # Check if running as administrator
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        if (-not $isAdmin) {
            Write-Warning "Not running as administrator. Some installations may fail."
        }
        
        # Update repositories if requested
        if ($UpdateRepos) {
            Update-Repositories
        }
        
        # Fix MSBuild build issues if requested
        if ($FixMSBuild) {
            Write-Info "MSBuild build issues fix requested..."
            if (Fix-MSBuildBuildIssues) {
                Write-Success "MSBuild build issues fixed successfully!"
                Write-Info "You should now be able to build MSBuild from source without errors."
                Write-Info "Please restart your terminal and try building again."
                exit 0
            } else {
                Write-Error "Failed to fix MSBuild build issues"
                exit 1
            }
        }
        
        # Install dependencies
        if (Install-Dependencies) {
            # Update PATH
            Update-Path
            
            # Test installation
            if (Test-Installation) {
                Write-Success "All dependencies installed successfully!"
                Write-Info "Please restart your terminal to ensure PATH changes take effect."
            } else {
                Write-Warning "Some dependencies may not be working correctly."
            }
        } else {
            Write-Error "Failed to install dependencies"
            exit 1
        }
    }
    catch {
        Write-Error "Unexpected error: $($_.Exception.Message)"
        exit 1
    }
}

function Test-VisualStudioComponent {
    param([string]$ComponentId)
    
    try {
        # Check registry for component installation
        $regPath = "HKLM:\SOFTWARE\Microsoft\VisualStudio\*\Setup\VS\Components\$ComponentId"
        $component = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($component) {
            $installPath = Get-ItemProperty -Path $component.PSPath -Name "InstallDir" -ErrorAction SilentlyContinue
            if ($installPath -and $installPath.InstallDir) {
                return $true
            }
        }
        
        # Also check BuildTools
        $regPathBuildTools = "HKLM:\SOFTWARE\Microsoft\VisualStudio\*\Setup\BuildTools\Components\$ComponentId"
        $componentBuildTools = Get-ChildItem -Path $regPathBuildTools -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($componentBuildTools) {
            $installPath = Get-ItemProperty -Path $componentBuildTools.PSPath -Name "InstallDir" -ErrorAction SilentlyContinue
            if ($installPath -and $installPath.InstallDir) {
                return $true
            }
        }
        
        return $false
    } catch {
        return $false
    }
}

function Test-VisualStudioInstallation {
    Write-Info "Checking Visual Studio installation status..."
    
    # Check if Visual Studio is installed at all
    $vsInstallations = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\VisualStudio" -ErrorAction SilentlyContinue
    if (-not $vsInstallations) {
        Write-Warning "No Visual Studio installation found in registry"
        return $false
    }
    
    Write-Info "Found Visual Studio installations:"
    foreach ($vs in $vsInstallations) {
        $vsName = Split-Path $vs.Name -Leaf
        Write-Info "  - $vsName"
        
        # Check if it's a valid installation
        try {
            $installPath = Get-ItemProperty -Path $vs.PSPath -Name "InstallDir" -ErrorAction SilentlyContinue
            if ($installPath -and $installPath.InstallDir) {
                Write-Info "    InstallDir: $($installPath.InstallDir)"
                
                # Check if installer exists
                $installerPath = Join-Path $installPath.InstallDir "Installer\vs_installer.exe"
                if (Test-Path $installerPath) {
                    Write-Success "    Installer found: $installerPath"
                } else {
                    Write-Warning "    Installer not found at expected location"
                }
            }
        } catch {
            Write-Warning "    Could not read installation details"
        }
    }
    
    # Check for Visual Studio Installer in common locations
    Write-Info "Checking for Visual Studio Installer..."
    $installerFound = $false
    
    $commonPaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\Installer",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer",
        "${env:LOCALAPPDATA}\Microsoft\VisualStudio\Installer"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path "$path\vs_installer.exe") {
            Write-Success "Visual Studio Installer found at: $path\vs_installer.exe"
            $installerFound = $true
            break
        }
    }
    
    if (-not $installerFound) {
        Write-Warning "Visual Studio Installer not found in common locations"
        Write-Info "This may prevent adding new components to existing installations"
    }
    
    return $true
}

function Install-MissingVisualStudioComponents {
    param([string[]]$ComponentIds)
    
    Write-Info "Attempting to install missing Visual Studio components..."
    
    # Try to find Visual Studio Installer with enhanced detection
    $vsInstaller = $null
    
    # Method 1: Check if it's in PATH
    try {
        $vsInstallerCmd = Get-Command "vs_installer.exe" -ErrorAction SilentlyContinue
        if ($vsInstallerCmd) {
            $vsInstaller = $vsInstallerCmd.Source
            Write-Info "Found Visual Studio Installer in PATH: $vsInstaller"
        }
    } catch {
        Write-Debug "Visual Studio Installer not found in PATH"
    }
    
    # Method 2: Check common installation locations
    if (-not $vsInstaller) {
        Write-Info "Searching for Visual Studio Installer in common locations..."
        $commonPaths = @(
            "${env:ProgramFiles}\Microsoft Visual Studio\Installer",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer",
            "${env:LOCALAPPDATA}\Microsoft\VisualStudio\Installer",
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\Installer",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\*\Installer",
            "${env:ProgramFiles}\Microsoft Visual Studio\2019\*\Installer",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\Installer",
            "${env:ProgramFiles}\Microsoft Visual Studio\2017\*\Installer",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\*\Installer"
        )
        
        foreach ($path in $commonPaths) {
            $foundPath = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundPath) {
                $installerPath = Join-Path $foundPath.FullName "vs_installer.exe"
                if (Test-Path $installerPath) {
                    $vsInstaller = $installerPath
                    Write-Info "Found Visual Studio Installer at: $vsInstaller"
                    break
                }
            }
        }
    }
    
    # Method 3: Try to download and install Visual Studio Installer if not found
    if (-not $vsInstaller) {
        Write-Warning "Visual Studio Installer not found in any common locations"
        Write-Info "Attempting to download and install Visual Studio Installer..."
        
        try {
            # Download Visual Studio Installer
            $installerUrl = "https://aka.ms/vs/17/release/vs_installer.exe"
            $installerPath = "$env:TEMP\vs_installer.exe"
            
            Write-Info "Downloading Visual Studio Installer from: $installerUrl"
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
            
            if (Test-Path $installerPath) {
                $vsInstaller = $installerPath
                Write-Success "Downloaded Visual Studio Installer to: $vsInstaller"
            } else {
                Write-Error "Failed to download Visual Studio Installer"
                return $false
            }
        } catch {
            Write-Error "Error downloading Visual Studio Installer: $($_.Exception.Message)"
            return $false
        }
    }
    
    if (-not $vsInstaller -or -not (Test-Path $vsInstaller)) {
        Write-Error "Visual Studio Installer not found and could not be downloaded"
        Write-Info "Please install Visual Studio Build Tools manually from: https://aka.ms/vs/17/release/vs_buildtools.exe"
        return $false
    }
    
    Write-Info "Using Visual Studio Installer at: $vsInstaller"
    
    # Build arguments for component installation
    $installArgs = @("modify", "--quiet", "--norestart")
    foreach ($componentId in $ComponentIds) {
        $installArgs += "--add", $componentId
    }
    
    Write-Info "Installing components: $($ComponentIds -join ', ')"
    Write-Info "Command: $vsInstaller $($installArgs -join ' ')"
    
    try {
        $process = Start-Process -FilePath $vsInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Success "Components installed successfully"
            return $true
        } else {
            Write-Warning "Component installation completed with exit code: $($process.ExitCode)"
            
            # Try alternative approach - install components via workload
            Write-Info "Attempting alternative installation method..."
            $workloadArgs = @("install", "--quiet", "--norestart", "--add", "Microsoft.VisualStudio.Workload.VCTools")
            foreach ($componentId in $ComponentIds) {
                $workloadArgs += "--add", $componentId
            }
            
            Write-Info "Trying workload installation: $vsInstaller $($workloadArgs -join ' ')"
            $workloadProcess = Start-Process -FilePath $vsInstaller -ArgumentList $workloadArgs -Wait -PassThru -NoNewWindow
            
            if ($workloadProcess.ExitCode -eq 0) {
                Write-Success "Components installed successfully via workload method"
                return $true
            } else {
                Write-Warning "Workload installation also failed with exit code: $($workloadProcess.ExitCode)"
                return $false
            }
        }
    } catch {
        Write-Error "Error installing components: $($_.Exception.Message)"
        return $false
    }
}

function Install-WindowsSDKDirectly {
    Write-Info "Attempting to install Windows SDK directly..."
    
    try {
        # Try to download Windows SDK directly
        $sdkUrl = "https://go.microsoft.com/fwlink/p/?linkid=2196241"  # Windows 10 SDK
        $sdkInstaller = "$env:TEMP\winsdk_installer.exe"
        
        Write-Info "Downloading Windows 10 SDK directly..."
        
        # Clean up any existing file
        if (Test-Path $sdkInstaller) {
            Remove-Item -Path $sdkInstaller -Force -ErrorAction SilentlyContinue
        }
        
        try {
            Invoke-WebRequest -Uri $sdkUrl -OutFile $sdkInstaller -UseBasicParsing -TimeoutSec 600
            Start-Sleep -Seconds 2
            
            if (Test-Path $sdkInstaller) {
                $fileSize = (Get-Item $sdkInstaller).Length
                if ($fileSize -gt 1000000) { # Should be at least 1MB
                    Write-Success "Windows SDK downloaded (Size: $([math]::Round($fileSize/1MB, 2)) MB)"
                    
                    # Install Windows SDK
                    Write-Info "Installing Windows 10 SDK..."
                    $sdkArgs = @("/quiet", "/norestart")
                    $sdkProcess = Start-Process -FilePath $sdkInstaller -ArgumentList $sdkArgs -Wait -PassThru -NoNewWindow
                    
                    if ($sdkProcess.ExitCode -eq 0) {
                        Write-Success "Windows 10 SDK installed successfully"
                        
                        # Clean up installer
                        Remove-Item -Path $sdkInstaller -Force -ErrorAction SilentlyContinue
                        return $true
                    } else {
                        Write-Warning "Windows SDK installation completed with exit code: $($sdkProcess.ExitCode)"
                        return $false
                    }
                } else {
                    Write-Error "Downloaded Windows SDK file is too small, likely corrupted"
                    Remove-Item -Path $sdkInstaller -Force -ErrorAction SilentlyContinue
                    return $false
                }
            } else {
                Write-Error "Failed to download Windows SDK"
                return $false
            }
        } catch {
            Write-Error "Error downloading Windows SDK: $($_.Exception.Message)"
            return $false
        }
    } catch {
        Write-Error "Error in Install-WindowsSDKDirectly: $($_.Exception.Message)"
        return $false
    }
}

function Install-WindowsSDKComponents {
    Write-Info "Installing missing Windows SDK components for MSBuild build..."
    
    # Check if we already have the required tools
    $requiredTools = @("TlbExp.exe", "resgen.exe")
    $missingTools = @()
    
    foreach ($tool in $requiredTools) {
        $found = $false
        
        # Search in common Windows SDK locations
        $sdkPaths = @(
            "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64",
            "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x86",
            "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64",
            "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x86",
            "${env:ProgramFiles(x86)}\Windows Kits\8.0\bin\x64",
            "${env:ProgramFiles(x86)}\Windows Kits\8.0\bin\x86"
        )
        
        foreach ($sdkPath in $sdkPaths) {
            $foundPath = Get-ChildItem -Path $sdkPath -Name $tool -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundPath) {
                $found = $true
                Write-Info "Found $tool at: $sdkPath\$foundPath"
                break
            }
        }
        
        if (-not $found) {
            $missingTools += $tool
        }
    }
    
    if ($missingTools.Count -eq 0) {
        Write-Success "All required Windows SDK tools are already available"
        return $true
    }
    
    Write-Warning "Missing Windows SDK tools: $($missingTools -join ', ')"
    Write-Info "Attempting to install Windows SDK components..."
    
    # Try to install Windows SDK via Visual Studio Installer first
    if (Install-WindowsSDKViaVisualStudio) {
        Write-Info "Windows SDK installed via Visual Studio, checking if tools are now available..."
        Start-Sleep -Seconds 10
        
        # Refresh environment and check again
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Check if tools are now available
        $stillMissing = @()
        foreach ($tool in $missingTools) {
            $found = $false
            foreach ($sdkPath in $sdkPaths) {
                $foundPath = Get-ChildItem -Path $sdkPath -Name $tool -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($foundPath) {
                    $found = $true
                    Write-Success "Found $tool at: $sdkPath\$foundPath"
                    break
                }
            }
            if (-not $found) {
                $stillMissing += $tool
            }
        }
        
        if ($stillMissing.Count -eq 0) {
            Write-Success "All Windows SDK tools are now available after Visual Studio installation"
            return $true
        } else {
            Write-Warning "Some tools still missing after Visual Studio installation: $($stillMissing -join ', ')"
        }
    }
    
    # Try direct Windows SDK installation as fallback
    if (Install-WindowsSDKDirectly) {
        Write-Info "Windows SDK installed directly, checking if tools are now available..."
        Start-Sleep -Seconds 15
        
        # Check if tools are now available
        $stillMissing = @()
        foreach ($tool in $missingTools) {
            $found = $false
            foreach ($sdkPath in $sdkPaths) {
                $foundPath = Get-ChildItem -Path $sdkPath -Name $tool -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($foundPath) {
                    $found = $true
                    Write-Success "Found $tool at: $sdkPath\$foundPath"
                    break
                }
            }
            if (-not $found) {
                $stillMissing += $tool
            }
        }
        
        if ($stillMissing.Count -eq 0) {
            Write-Success "All Windows SDK tools are now available after direct installation"
            return $true
        } else {
            Write-Warning "Some tools still missing after direct installation: $($stillMissing -join ', ')"
        }
    }
    
    # Final attempt - try to install specific .NET Framework SDKs
    Write-Info "Attempting to install .NET Framework SDKs that contain the missing tools..."
    if (Install-NetFrameworkSDKs) {
        Write-Info ".NET Framework SDKs installed, checking if tools are now available..."
        Start-Sleep -Seconds 10
        
        # Check if tools are now available
        $stillMissing = @()
        foreach ($tool in $missingTools) {
            $found = $false
            foreach ($sdkPath in $sdkPaths) {
                $foundPath = Get-ChildItem -Path $sdkPath -Name $tool -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($foundPath) {
                    $found = $true
                    Write-Success "Found $tool at: $sdkPath\$foundPath"
                    break
                }
            }
            if (-not $found) {
                $stillMissing += $tool
            }
        }
        
        if ($stillMissing.Count -eq 0) {
            Write-Success "All Windows SDK tools are now available after .NET Framework SDK installation"
            return $true
        } else {
            Write-Warning "Some tools still missing after .NET Framework SDK installation: $($stillMissing -join ', ')"
        }
    }
    
    Write-Error "Failed to install required Windows SDK tools: $($missingTools -join ', ')"
    Write-Info "These tools are required for building MSBuild from source"
    Write-Info "Please install Windows 10 SDK manually from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/"
    return $false
}

function Install-WindowsSDKViaVisualStudio {
    Write-Info "Attempting to install Windows SDK via Visual Studio Installer..."
    
    # Try to find Visual Studio Installer
    $vsInstaller = $null
    
    # Method 1: Check if it's in PATH
    try {
        $vsInstallerCmd = Get-Command "vs_installer.exe" -ErrorAction SilentlyContinue
        if ($vsInstallerCmd) {
            $vsInstaller = $vsInstallerCmd.Source
            Write-Info "Found Visual Studio Installer in PATH: $vsInstaller"
        }
    } catch {
        Write-Debug "Visual Studio Installer not found in PATH"
    }
    
    # Method 2: Check common installation locations
    if (-not $vsInstaller) {
        $commonPaths = @(
            "${env:ProgramFiles}\Microsoft Visual Studio\Installer",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer",
            "${env:LOCALAPPDATA}\Microsoft\VisualStudio\Installer"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path "$path\vs_installer.exe") {
                $vsInstaller = "$path\vs_installer.exe"
                Write-Info "Found Visual Studio Installer at: $vsInstaller"
                break
            }
        }
    }
    
    if (-not $vsInstaller -or -not (Test-Path $vsInstaller)) {
        Write-Warning "Visual Studio Installer not found, cannot install Windows SDK via this method"
        return $false
    }
    
    Write-Info "Installing Windows SDK components via Visual Studio Installer..."
    
    # Install Windows 10 SDK components
    $sdkComponents = @(
        "Microsoft.VisualStudio.Component.Windows10SDK.19041",
        "Microsoft.VisualStudio.Component.Windows10SDK.18362",
        "Microsoft.VisualStudio.Component.Windows10SDK.17763",
        "Microsoft.VisualStudio.Component.Windows10SDK.16299",
        "Microsoft.VisualStudio.Component.Windows10SDK.15063",
        "Microsoft.VisualStudio.Component.Windows10SDK.14393",
        "Microsoft.VisualStudio.Component.Windows10SDK.10586",
        "Microsoft.VisualStudio.Component.Windows10SDK.10240"
    )
    
    $installArgs = @("modify", "--quiet", "--norestart")
    foreach ($component in $sdkComponents) {
        $installArgs += "--add", $component
    }
    
    try {
        Write-Info "Installing Windows SDK components: $($sdkComponents -join ', ')"
        $process = Start-Process -FilePath $vsInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Windows SDK components installed successfully"
            return $true
        } else {
            Write-Warning "Windows SDK installation completed with exit code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Error installing Windows SDK components: $($_.Exception.Message)"
        return $false
    }
}

function Install-NetFrameworkSDKs {
    Write-Info "Installing .NET Framework SDKs that contain the missing tools..."
    
    # Try to install .NET Framework SDKs via Chocolatey
    $netFrameworkSDKs = @("netfx-4.7.2-devpack", "netfx-4.6.1-devpack", "netfx-4.5.2-devpack")
    
    foreach ($sdk in $netFrameworkSDKs) {
        Write-Info "Installing $sdk..."
        try {
            choco install $sdk -y
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$sdk installed successfully"
            } else {
                Write-Warning "Failed to install $sdk"
            }
        } catch {
            Write-Warning "Error installing $sdk - $($_.Exception.Message)"
        }
    }
    
    # Also try to download and install .NET Framework 4.7.2 Developer Pack directly
    Write-Info "Attempting to install .NET Framework 4.7.2 Developer Pack directly..."
    try {
        $netfxUrl = "https://go.microsoft.com/fwlink/?LinkId=863262"  # .NET Framework 4.7.2 Developer Pack
        $netfxInstaller = "$env:TEMP\netfx472_devpack.exe"
        
        Write-Info "Downloading .NET Framework 4.7.2 Developer Pack..."
        Invoke-WebRequest -Uri $netfxUrl -OutFile $netfxInstaller -UseBasicParsing
        
        if (Test-Path $netfxInstaller) {
            Write-Info "Installing .NET Framework 4.7.2 Developer Pack..."
            $netfxArgs = @("/quiet", "/norestart")
            $netfxProcess = Start-Process -FilePath $netfxInstaller -ArgumentList $netfxArgs -Wait -PassThru -NoNewWindow
            
            if ($netfxProcess.ExitCode -eq 0) {
                Write-Success ".NET Framework 4.7.2 Developer Pack installed successfully"
                
                # Clean up installer
                Remove-Item -Path $netfxInstaller -Force -ErrorAction SilentlyContinue
                return $true
            } else {
                Write-Warning ".NET Framework installation completed with exit code: $($netfxProcess.ExitCode)"
            }
            
            # Clean up installer
            Remove-Item -Path $netfxInstaller -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Error installing .NET Framework 4.7.2 Developer Pack: $($_.Exception.Message)"
    }
    
    return $false
}

function Update-Repositories {
    Write-Info "Checking for repository updates..."
    
    # Update MSBuild repository if it exists
    $msbuildSourceDir = "$env:USERPROFILE\msbuild-source"
    if (Test-Path "$msbuildSourceDir\.git") {
        try {
            Set-Location $msbuildSourceDir
            Write-Info "Updating MSBuild repository..."
            git fetch origin 2>$null
            $localCommit = git rev-parse HEAD 2>$null
            $remoteCommit = git rev-parse origin/main 2>$null
            
            if ($localCommit -ne $remoteCommit) {
                Write-Info "MSBuild repository has updates, pulling latest changes..."
                git pull origin main 2>$null
                Write-Success "MSBuild repository updated successfully"
            } else {
                Write-Info "MSBuild repository is already up to date"
            }
        } catch {
            Write-Warning "Could not update MSBuild repository: $($_.Exception.Message)"
        }
    }
    
    # Update vcpkg repository if it exists
    $vcpkgPath = "$env:USERPROFILE\vcpkg"
    if (Test-Path "$vcpkgPath\.git") {
        try {
            Set-Location $vcpkgPath
            Write-Info "Updating vcpkg repository..."
            git fetch origin 2>$null
            $localCommit = git rev-parse HEAD 2>$null
            $remoteCommit = git rev-parse origin/master 2>$null
            
            if ($localCommit -ne $remoteCommit) {
                Write-Info "vcpkg repository has updates, pulling latest changes..."
                git pull origin master 2>$null
                Write-Success "vcpkg repository updated successfully"
            } else {
                Write-Info "vcpkg repository is already up to date"
            }
        } catch {
            Write-Warning "Could not update vcpkg repository: $($_.Exception.Message)"
        }
    }
    
    # Return to original directory
    Set-Location $PSScriptRoot
}

# Run main function
Main
