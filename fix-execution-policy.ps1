# Fix Execution Policy Script
# Script để kiểm tra và thiết lập Execution Policy cho PowerShell

Write-Host "=========================================" -ForegroundColor Blue
Write-Host "  Fix Execution Policy for PowerShell   " -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue
Write-Host ""

# Check current execution policies
Write-Host "Checking current execution policies..." -ForegroundColor Yellow
Write-Host ""

try {
    $policies = Get-ExecutionPolicy -List
    foreach ($policy in $policies) {
        $scope = $policy.Scope
        $policyValue = $policy.ExecutionPolicy
        $color = if ($policyValue -eq "Restricted") { "Red" } elseif ($policyValue -eq "AllSigned") { "Yellow" } else { "Green" }
        Write-Host "$scope`: $policyValue" -ForegroundColor $color
    }
} catch {
    Write-Host "Could not retrieve execution policies" -ForegroundColor Red
}

Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($isAdmin) {
    Write-Host "✓ Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "✗ Not running as Administrator" -ForegroundColor Red
    Write-Host "Some policy changes may require administrator privileges" -ForegroundColor Yellow
}

Write-Host ""

# Try to set execution policy
Write-Host "Attempting to set execution policy..." -ForegroundColor Yellow

try {
    # Try to set RemoteSigned for CurrentUser
    Write-Host "Setting RemoteSigned for CurrentUser..." -ForegroundColor Cyan
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
    Write-Host "✓ Successfully set RemoteSigned for CurrentUser" -ForegroundColor Green
} catch {
    Write-Host "✗ Could not set RemoteSigned for CurrentUser: $($_.Exception.Message)" -ForegroundColor Red
    
    try {
        # Try to set Bypass for CurrentUser
        Write-Host "Setting Bypass for CurrentUser..." -ForegroundColor Cyan
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "✓ Successfully set Bypass for CurrentUser" -ForegroundColor Green
    } catch {
        Write-Host "✗ Could not set Bypass for CurrentUser: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($isAdmin) {
            try {
                # Try to set RemoteSigned for LocalMachine
                Write-Host "Setting RemoteSigned for LocalMachine..." -ForegroundColor Cyan
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction Stop
                Write-Host "✓ Successfully set RemoteSigned for LocalMachine" -ForegroundColor Green
            } catch {
                Write-Host "✗ Could not set RemoteSigned for LocalMachine: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""

# Show final execution policy
Write-Host "Final execution policy for CurrentUser:" -ForegroundColor Yellow
try {
    $finalPolicy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Host "CurrentUser: $finalPolicy" -ForegroundColor Green
} catch {
    Write-Host "Could not retrieve final policy" -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "Execution Policy check completed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Blue

Write-Host ""
Write-Host "If you still have issues, try:" -ForegroundColor Yellow
Write-Host "1. Run this script as Administrator" -ForegroundColor White
Write-Host "2. Use: powershell -ExecutionPolicy Bypass -File script.ps1" -ForegroundColor White
Write-Host "3. Check Group Policy settings" -ForegroundColor White

pause
