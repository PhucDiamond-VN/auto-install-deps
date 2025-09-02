# Fix MSBuild Build Issues Script
# This script specifically addresses the TlbExp and resgen.exe missing tools errors

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

Write-ColorOutput "=========================================" $Blue
Write-ColorOutput "   Fix MSBuild Build Issues Script      " $Blue
Write-ColorOutput "=========================================" $Blue
Write-ColorOutput ""

Write-Info "This script will fix the MSBuild build errors related to missing tools:"
Write-Info "- TlbExp.exe (Windows SDK tool)"
Write-Info "- resgen.exe (Windows SDK tool)"
Write-Info ""

# Import the functions from the main script
$mainScriptPath = Join-Path $PSScriptRoot "install-deps.ps1"
if (Test-Path $mainScriptPath) {
    Write-Info "Loading functions from main script..."
    . $mainScriptPath
    
    # Call the Windows SDK components installation function
    Write-Info "Installing missing Windows SDK components..."
    if (Install-WindowsSDKComponents) {
        Write-Success "Windows SDK components installed successfully!"
        
        Write-Info "Checking if MSBuild is now available..."
        Start-Sleep -Seconds 5
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Test-Command "msbuild") {
            try {
                $version = msbuild /version 2>$null
                if ($version) {
                    Write-Success "MSBuild is now available (version: $version)"
                    Write-Info "You should now be able to build MSBuild from source successfully!"
                } else {
                    Write-Warning "MSBuild command available but version check failed"
                }
            } catch {
                Write-Warning "MSBuild command available but version check failed"
            }
        } else {
            Write-Info "MSBuild not yet available in PATH, but Windows SDK tools should now be available"
            Write-Info "Try building MSBuild again from your source directory"
        }
        
        Write-Info ""
        Write-Info "Next steps:"
        Write-Info "1. Restart your terminal to ensure PATH changes take effect"
        Write-Info "2. Navigate to your MSBuild source directory"
        Write-Info "3. Try building again with: build.cmd"
        Write-Info "4. The TlbExp and resgen.exe tools should now be available"
        
    } else {
        Write-Error "Failed to install Windows SDK components"
        Write-Info "Please try running the main install-deps.ps1 script with -Force flag"
    }
} else {
    Write-Error "Main script not found: $mainScriptPath"
    Write-Info "Please ensure install-deps.ps1 is in the same directory"
}

Write-Info ""
Write-Info "Fix completed!"
Write-Info "========================================="
