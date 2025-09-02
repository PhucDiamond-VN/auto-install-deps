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
        return $true
    }
    
    Write-Info "Installing Visual Studio Build Tools..."
    try {
        # Download Visual Studio Build Tools
        $vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
        $vsInstaller = "$env:TEMP\vs_buildtools.exe"
        
        Write-Info "Downloading Visual Studio Build Tools..."
        Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller
        
        # Install with C++ workload and additional components
        Write-Info "Installing Visual Studio Build Tools with C++ workload..."
        $args = @("--quiet", "--wait", "--add", "Microsoft.VisualStudio.Workload.VCTools")
        $args += "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041"
        $args += "--add", "Microsoft.VisualStudio.Component.Windows11SDK.22621"
        
        Start-Process -FilePath $vsInstaller -ArgumentList $args -Wait
        
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\VisualStudio") {
            Write-Success "Visual Studio Build Tools installed successfully"
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
        @{ Name = "Node.js"; Function = "Install-NodeJS" }
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
    
    $tools = @("git", "python", "cmake", "ninja", "conan", "node")
    $successCount = 0
    
    foreach ($tool in $tools) {
        if (Test-Command $tool) {
            Write-Success "$tool is working correctly"
            $successCount++
        } else {
            Write-Warning "$tool is not working correctly"
        }
    }
    
    Write-Info "Installation test completed: $successCount out of $($tools.Count) tools working"
    return $successCount -eq $tools.Count
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
