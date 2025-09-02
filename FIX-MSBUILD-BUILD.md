# Fix MSBuild Build Issues

## Problem Description

When trying to build MSBuild from source, you may encounter these errors:

```
Build FAILED.

error : TlbExp was not found. Ensure that you have installed everything from .vsconfig. If you have, please report a bug to MSBuild.

error MSB3091: Task failed because "resgen.exe" was not found, or the correct Microsoft Windows SDK is not installed.
```

## Root Cause

These errors occur because the build process is missing essential Windows SDK tools:
- **TlbExp.exe** - Type Library Exporter tool
- **resgen.exe** - Resource Generator tool

These tools are part of the Windows SDK and .NET Framework SDK, not the basic Visual Studio Build Tools.

## Solutions

### Option 1: Use the Fix Script (Recommended)

Run the specialized fix script:

```powershell
# PowerShell
.\fix-msbuild-build.ps1 -Verbose

# Or batch file
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

1. **Detects missing tools** - Checks for TlbExp.exe and resgen.exe
2. **Installs Windows SDK components** via Visual Studio Installer
3. **Downloads Windows SDK directly** if Visual Studio method fails
4. **Installs .NET Framework SDKs** that contain the missing tools
5. **Updates PATH** to include the new tool locations

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
4. **The build should now succeed** without TlbExp/resgen.exe errors

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

- `fix-msbuild-build.ps1` - PowerShell fix script
- `fix-msbuild-build.bat` - Batch file wrapper
- `FIX-MSBUILD-BUILD.md` - This documentation file

The main `install-deps.ps1` script has also been enhanced with Windows SDK component installation capabilities.
