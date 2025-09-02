# Auto Install Dependencies for C/C++ Projects v2.0
# Script tự động cài đặt tất cả dependencies cần thiết để build C/C++ projects

param(
    [string]$ConfigFile = "deps-config.json",
    [switch]$Force,
    [switch]$Verbose,
    [switch]$InstallOptional,
    [switch]$SkipTests
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$Magenta = "Magenta"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
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
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
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
        $args = @("--quiet", "--wait", "--add", "Microsoft.VisualStudio.Workload.VCTools")
        $args += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041"
        $args += "--add", "Microsoft.VisualStudio.Component.Windows11SDK.22621"
        $args += "--add", "Microsoft.VisualStudio.Component.MSBuild"
        $args += "--add", "Microsoft.VisualStudio.Component.Roslyn.Compiler"
        $args += "--add", "Microsoft.VisualStudio.Component.TextTemplating"
        $args += "--add", "Microsoft.VisualStudio.Component.NuGet"
        $args += "--add", "Microsoft.VisualStudio.Component.WebDeploy"
        $args += "--add", "Microsoft.VisualStudio.Component.MSBuild.MSIL"
        $args += "--add", "Microsoft.VisualStudio.Component.MSBuild.x64"
        
        Write-Info "Installation arguments: $($args -join ' ')"
        Start-Process -FilePath $vsInstaller -ArgumentList $args -Wait
        
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
        return $true
    }
    
    Write-Info "Installing vcpkg via Git clone..."
    try {
        if (-not (Test-Path $vcpkgPath)) {
            New-Item -ItemType Directory -Path $vcpkgPath -Force | Out-Null
        }
        
        Set-Location $vcpkgPath
        
        # Clone vcpkg repository
        if (-not (Test-Path ".git")) {
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
    
    # Create MSBuild source directory
    $msbuildSourceDir = "$env:USERPROFILE\msbuild-source"
    if (Test-Path $msbuildSourceDir) {
        Write-Info "MSBuild source directory already exists, cleaning up..."
        Remove-Item -Path $msbuildSourceDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    try {
        # Clone MSBuild repository
        Write-Info "Cloning MSBuild source code from GitHub..."
        git clone https://github.com/dotnet/msbuild.git $msbuildSourceDir
        
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
                dotnet restore
                
                # Build the solution
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
        return $false
        
    } catch {
        Write-Error "Error building MSBuild from source: $($_.Exception.Message)"
        return $false
    } finally {
        # Return to original directory
        Set-Location $PSScriptRoot
    }
}

# Main execution
function Main {
    Write-ColorOutput "=========================================" $Blue
    Write-ColorOutput "  Auto Install Dependencies for C/C++   " $Blue
    Write-ColorOutput "              Version 2.0               " $Blue
    Write-ColorOutput "=========================================" $Blue
    Write-ColorOutput ""
    
    try {
        # Check if running as administrator
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        if (-not $isAdmin) {
            Write-Warning "Not running as administrator. Some installations may fail."
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

# Run main function
Main
