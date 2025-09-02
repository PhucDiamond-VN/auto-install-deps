# Fix MSBuild Build Issues

## Problem Description

When trying to build MSBuild from source, you may encounter these errors:

```
Build FAILED.

error : TlbExp was not found. Ensure that you have installed everything from .vsconfig. If you have, please report a bug to MSBuild.

error MSB3091: Task failed because "resgen.exe" was not found, or the correct Microsoft Windows SDK is not installed.

error MSB4018: The "LocateVisualStudioTask" task failed unexpectedly.
error MSB4018: System.ComponentModel.Win32Exception (0x80004005): The system cannot find the file specified
```

## Root Cause

These errors occur because the build process is missing essential components:

1. **Windows SDK Tools** (part of Windows SDK and .NET Framework SDK):
   - **TlbExp.exe** - Type Library Exporter tool
   - **resgen.exe** - Resource Generator tool

2. **Visual Studio Components** (required for LocateVisualStudioTask):
   - Missing Visual Studio workloads and components
   - Incomplete Visual Studio Build Tools installation
   - Missing MSBuild tools and .NET Framework SDKs

These components are not included in the basic Visual Studio Build Tools installation.

## Solutions

### Option 1: Use the Integrated Fix (Recommended)

Run the integrated fix in the main script:

```powershell
# PowerShell - Fix MSBuild only
.\install-deps.ps1 -FixMSBuild -Verbose

# PowerShell - Full installation with MSBuild fix
.\install-deps.ps1 -Force -Verbose

# Or batch file with interactive menu
install-deps.bat

# Or legacy batch file
fix-msbuild-build.bat
```

### Option 2: Run the Main Install Script with Force Flag

```powershell
.\install-deps.ps1 -Force -Verbose
```

### Option 3: Manual Installation

If the scripts don't work, manually install:

1. **Windows 10 SDK** from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
2. **.NET Framework 4.7.2 Developer Pack** from: https://dotnet.microsoft.com/download/dotnet-framework/net472

## What the Fix Script Does

The enhanced fix script addresses all three types of build failures:

### Step 1: Visual Studio Installation Check
- **Diagnoses Visual Studio installation** - Checks registry and installer locations
- **Identifies missing components** - Lists what's installed vs. what's needed

### Step 2: Windows SDK Components Installation
- **Detects missing tools** - Checks for TlbExp.exe and resgen.exe
- **Installs Windows SDK components** via Visual Studio Installer
- **Downloads Windows SDK directly** if Visual Studio method fails
- **Installs .NET Framework SDKs** that contain the missing tools

### Step 3: Visual Studio Components Installation
- **Installs required workloads** - MSBuild Tools, C++ Tools, .NET Core Build Tools
- **Adds missing components** - All Windows SDK versions, .NET Framework SDKs
- **Updates Visual Studio installation** - Modifies existing installation or installs new one
- **Updates PATH** to include the new tool locations

## Verification

After running the fix, verify the tools are available:

```powershell
# Check if tools exist in Windows SDK locations
Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\TlbExp.exe"
Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\resgen.exe"
```

## Next Steps

1. **Restart your terminal** to ensure PATH changes take effect
2. **Navigate to your MSBuild source directory**
3. **Try building again**: `build.cmd`
4. **The build should now succeed** without:
   - TlbExp/resgen.exe errors
   - LocateVisualStudioTask failures
   - Missing Visual Studio component errors

## Troubleshooting

### If tools are still missing:

1. Check Windows SDK installation in Control Panel
2. Verify .NET Framework SDK installation
3. Run `.\install-deps.ps1 -Force` to reinstall all components
4. Check Windows Update for missing components

### If build still fails:

1. Ensure you have the latest MSBuild source code
2. Check that all Visual Studio components are installed
3. Verify .NET Framework 4.7.2 is available
4. Check Windows SDK version compatibility

## Support

If you continue to have issues:
1. Run the fix script with `-Verbose` flag for detailed output
2. Check the script output for specific error messages
3. Ensure you're running as Administrator if needed
4. Check Windows Event Viewer for installation errors

## Files Created

- `install-deps.bat` - **Main integrated batch file** with interactive menu for all functions
- `fix-msbuild-build.bat` - Legacy batch file wrapper (now calls the main integrated file)
- `FIX-MSBUILD-BUILD.md` - This documentation file

The main `install-deps.ps1` script now includes **integrated MSBuild build fix functionality** with all Windows SDK component installation capabilities.

## Interactive Menu Options

When you run `install-deps.bat`, you'll see an interactive menu:

1. **Fix MSBuild build issues only** - Resolves TlbExp, resgen.exe, and LocateVisualStudioTask errors
2. **Install all dependencies** - Full dependency installation
3. **Force reinstall everything** - Force reinstall all components

This provides a user-friendly way to choose exactly what you need without remembering command-line parameters.
