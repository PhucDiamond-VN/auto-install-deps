# Fix MSBuild Build Issues Script
# This script directly installs Visual Studio Build Tools with required components
# No need to build MSBuild from Git source

param(
    [switch]$Force,
    [switch]$Verbose
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

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

function Install-VisualStudioBuildTools {
    Write-Info "Installing Visual Studio Build Tools with all required components..."
    
    try {
        # Download Visual Studio Build Tools
        $vsUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
        $vsInstaller = "$env:TEMP\vs_buildtools.exe"
        
        Write-Info "Downloading Visual Studio Build Tools..."
        Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller
        
        # Install with all required workloads and components
        Write-Info "Installing Visual Studio Build Tools with all required components..."
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

function Verify-RequiredComponents {
    Write-Info "Verifying required components are available..."
    
    # Check if MSBuild is available
    if (Test-Command "msbuild") {
        try {
            $version = msbuild /version 2>$null
            if ($version) {
                Write-Success "MSBuild is available (version: $version)"
            } else {
                Write-Warning "MSBuild command available but version check failed"
            }
        } catch {
            Write-Warning "MSBuild command available but version check failed"
        }
    } else {
        Write-Warning "MSBuild not available in PATH"
    }
    
    # Check for Windows SDK tools
    $requiredTools = @("TlbExp.exe", "resgen.exe")
    $sdkPaths = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64",
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x86",
        "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x64",
        "${env:ProgramFiles(x86)}\Windows Kits\8.1\bin\x86",
        "${env:ProgramFiles(x86)}\Windows Kits\8.0\bin\x64",
        "${env:ProgramFiles(x86)}\Windows Kits\8.0\bin\x86"
    )
    
    foreach ($tool in $requiredTools) {
        $found = $false
        foreach ($sdkPath in $sdkPaths) {
            $foundPath = Get-ChildItem -Path $sdkPath -Name $tool -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundPath) {
                Write-Success "Found $tool at: $sdkPath\$foundPath"
                $found = $true
                break
            }
        }
        if (-not $found) {
            Write-Warning "Tool not found: $tool"
        }
    }
    
    # Check for .NET Framework
    $netFxPaths = @(
        "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7.2",
        "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7.1",
        "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7",
        "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6.1",
        "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6"
    )
    
    $netFxFound = $false
    foreach ($path in $netFxPaths) {
        if (Test-Path $path) {
            Write-Success "Found .NET Framework at: $path"
            $netFxFound = $true
            break
        }
    }
    
    if (-not $netFxFound) {
        Write-Warning ".NET Framework reference assemblies not found"
    }
}

Write-ColorOutput "=========================================" $Blue
Write-ColorOutput "   Fix MSBuild Build Issues Script      " $Blue
Write-ColorOutput "=========================================" $Blue
Write-ColorOutput ""

Write-Info "This script will install Visual Studio Build Tools with all required components:"
Write-Info "- MSBuild Tools workload"
Write-Info "- C++ Tools workload"
Write-Info "- All Windows SDK versions (8.0 through 10.0.19041)"
Write-Info "- All .NET Framework SDKs (3.5 through 4.7.2)"
Write-Info "- Additional build tools (Roslyn, NuGet, etc.)"
Write-Info ""

# Step 1: Check current Visual Studio installation
Write-Info "Step 1: Checking current Visual Studio installation..."
Test-VisualStudioInstallation

# Step 2: Install Visual Studio Build Tools with all components
Write-Info "Step 2: Installing Visual Studio Build Tools with all required components..."
if (Install-VisualStudioBuildTools) {
    Write-Success "Visual Studio Build Tools installation completed successfully!"
    
    # Step 3: Verify components are available
    Write-Info "Step 3: Verifying required components are available..."
    Start-Sleep -Seconds 10
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Verify-RequiredComponents
    
    Write-Info ""
    Write-Info "Installation completed successfully!"
    Write-Info "Next steps:"
    Write-Info "1. Restart your terminal to ensure PATH changes take effect"
    Write-Info "2. Navigate to your MSBuild source directory"
    Write-Info "3. Try building again with: build.cmd"
    Write-Info "4. All required components should now be available:"
    Write-Info "   - TlbExp.exe and resgen.exe (Windows SDK tools)"
    Write-Info "   - MSBuild and build tools"
    Write-Info "   - .NET Framework SDKs"
    Write-Info "   - Windows SDKs for all versions"
    Write-Info "5. The LocateVisualStudioTask should now work properly"
    
} else {
    Write-Error "Visual Studio Build Tools installation failed"
    Write-Info "Please check the error messages above and try again"
    Write-Info "You may need to run as Administrator or check Windows Update"
}

Write-Info ""
Write-Info "Fix completed!"
Write-Info "========================================="
