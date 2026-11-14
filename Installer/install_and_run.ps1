<#
.SYNOPSIS
    FxSound Portable Installer and Launcher
    Installs the signed WHQL FxSound Audio Enhancer driver if not present,
    configures registry settings, and launches FxSound.
#>

param (
    [switch]$UninstallDriver
)

# Ensure administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $argsList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($UninstallDriver) { $argsList += " -UninstallDriver" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argsList
    exit
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverDir = Join-Path $scriptDir "Drivers"
$appsDir = Join-Path $scriptDir "Apps"
$exePath = Join-Path $scriptDir "FxSound.exe"

# If invoked from within repo structure:
if (-not (Test-Path $driverDir)) {
    $driverDir = Join-Path $scriptDir "Drivers\Version14\win10\x64"
    $appsDir = Join-Path $scriptDir "Apps\Version14"
    $exePath = Join-Path (Split-Path -Parent $scriptDir) "bin\x64\FxSound.exe"
}

$devcon = Join-Path $driverDir "fxdevcon64.exe"
$inf = Join-Path $driverDir "fxvad.inf"
$dfxSetup = Join-Path $appsDir "DfxSetupDrv.exe"
$vendorCode = "23"
$regPath = "HKLM:\SOFTWARE\DFX\$vendorCode\devices"

if ($UninstallDriver) {
    Write-Host "Uninstalling FxSound driver..." -ForegroundColor Yellow
    if (Test-Path $devcon) {
        & $devcon remove root\fxvad
    }
    Write-Host "Driver removal complete." -ForegroundColor Green
    return
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FxSound Driver Setup & Application Launch" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check if driver is already installed
$driverInstalled = $false
if (Test-Path $dfxSetup) {
    Push-Location $appsDir
    try {
        $checkOut = (& $dfxSetup check) -join ""
        if ($checkOut -match "FxSound Audio Enhancer|DFX Audio Enhancer") {
            $driverInstalled = $true
            Write-Host "Driver already registered: $checkOut" -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

# 2. Install signed driver if not already present
if (-not $driverInstalled) {
    Write-Host "Installing signed FxSound virtual audio driver..." -ForegroundColor Yellow
    if ((Test-Path $devcon) -and (Test-Path $inf)) {
        Push-Location $driverDir
        try {
            $instOut = (& $devcon install $inf root\fxvad) -join "`n"
            Write-Host $instOut
            Start-Sleep -Seconds 2
        } finally {
            Pop-Location
        }
    } else {
        Write-Error "Driver files not found at $driverDir"
    }
}

# 3. Configure device registry entries
if (Test-Path $dfxSetup) {
    Push-Location $appsDir
    try {
        # Ensure registry key exists
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        # Get device GUID
        $guidOut = (& $dfxSetup getguid) -join ""
        $guidOut = $guidOut.Trim()
        if ($guidOut -match '^\{[0-9a-fA-F-]+\}$') {
            Set-ItemProperty -Path $regPath -Name "dfx_guid" -Value $guidOut -Type String -Force
            Write-Host "Registered device GUID: $guidOut" -ForegroundColor Green
        }

        # Set friendly name
        $nameOut = (& $dfxSetup setname) -join ""
        Write-Host "Set device name: $nameOut" -ForegroundColor Green

        # Set default buffer size
        $bufOut = (& $dfxSetup defaultbuffersize) -join ""
        $bufOut = $bufOut.Trim()
        if ($bufOut -and $bufOut -ne "Failed") {
            Set-ItemProperty -Path $regPath -Name "default_buffer_size" -Value $bufOut -Type String -Force
            Write-Host "Set default buffer size: $bufOut" -ForegroundColor Green
        }

        # Power request override
        & powercfg -REQUESTSOVERRIDE DRIVER "FxSound Audio Enhancer" SYSTEM 2>$null
    } finally {
        Pop-Location
    }
}

# 4. Launch FxSound
if (Test-Path $exePath) {
    Write-Host "`nLaunching FxSound from $exePath..." -ForegroundColor Cyan
    Start-Process -FilePath $exePath -WorkingDirectory (Split-Path -Parent $exePath)
    Write-Host "FxSound started successfully!" -ForegroundColor Green
} else {
    Write-Warning "FxSound.exe not found at $exePath."
}
