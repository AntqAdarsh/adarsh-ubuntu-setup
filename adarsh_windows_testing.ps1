<#
.SYNOPSIS
    Fully automated Windows setup script for fresh installations.
.DESCRIPTION
    Installs updates, configures power/firewall settings, and installs essential software.
    All installers are saved in D:\Software (or C:\Software if D: is missing).
.NOTES
    Author: Adarsh
    Run as Administrator: Yes
#>

# Log file location
$logFile = "$env:USERPROFILE\Desktop\WindowsSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Enhanced logging
function Write-Log {
    param([string]$message, [string]$logType = "INFO")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp [$logType] $message"
    Write-Host $logMessage -ForegroundColor $(if($logType -eq "ERROR"){"Red"}elseif($logType -eq "WARNING"){"Yellow"}else{"White"})
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
}

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "This script must be run as Administrator." "ERROR"
    Start-Sleep 5
    exit 1
}

# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# Configure security protocol for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Determine software folder (D:\Software or C:\Software)
$softwareFolder = if (Test-Path "D:") { "D:\Software" } else { "C:\Software" }
if (-not (Test-Path $softwareFolder)) { New-Item -ItemType Directory -Path $softwareFolder -Force | Out-Null }
Write-Log "Using software folder: $softwareFolder"

# Function to download files with retries
function Invoke-SafeDownload {
    param([string]$url, [string]$destination, [int]$maxRetries=3)
    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
        try {
            Write-Log "Downloading $url (Attempt $($retryCount + 1))"
            Invoke-WebRequest -Uri $url -OutFile $destination -UserAgent "Mozilla/5.0" -ErrorAction Stop
            if (Test-Path $destination) { return $true }
        } catch {
            $retryCount++
            Write-Log "Download failed: $_" "WARNING"
            Start-Sleep 3
        }
    }
    return $false
}

# Function to install software silently
function Install-Software {
    param([string]$installerPath, [string]$installArgs, [string]$softwareName)
    try {
        Write-Log "Installing $softwareName..."
        Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow
        Write-Log "$softwareName installed successfully."
        return $true
    } catch {
        Write-Log "Failed to install $softwareName: $_" "ERROR"
        return $false
    }
}

# Install Windows Updates
Write-Log "=== Installing Windows Updates ==="
try {
    Install-Module PSWindowsUpdate -Force -Confirm:$false -ErrorAction SilentlyContinue
    Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Stop | Out-Null
    Write-Log "Windows updates installed."
} catch {
    Write-Log "Windows Update failed: $_" "ERROR"
}

# Disable Sleep/Hibernate
Write-Log "=== Disabling Sleep Settings ==="
powercfg -change standby-timeout-ac 0 | Out-Null
powercfg -change standby-timeout-dc 0 | Out-Null
powercfg -h off | Out-Null
Write-Log "Sleep/Hibernate disabled."

# Disable Windows Firewall
Write-Log "=== Disabling Firewall ==="
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop
Write-Log "Firewall disabled."

# Install Software
Write-Log "=== Installing Software ==="

# Google Chrome
$chromeInstaller = "$softwareFolder\ChromeSetup.exe"
if (Invoke-SafeDownload -url "https://dl.google.com/chrome/install/standalonesetup64.exe" -destination $chromeInstaller) {
    Install-Software -installerPath $chromeInstaller -installArgs "/silent /install" -softwareName "Google Chrome"
}

# Firefox
$firefoxInstaller = "$softwareFolder\FirefoxSetup.exe"
if (Invoke-SafeDownload -url "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" -destination $firefoxInstaller) {
    Install-Software -installerPath $firefoxInstaller -installArgs "/S" -softwareName "Firefox"
}

# UltraViewer
$ultraviewerInstaller = "$softwareFolder\UltraViewerSetup.exe"
if (Invoke-SafeDownload -url "https://www.ultraviewer.net/files/UltraViewer_Setup.exe" -destination $ultraviewerInstaller) {
    Install-Software -installerPath $ultraviewerInstaller -installArgs "/VERYSILENT" -softwareName "UltraViewer"
}

# NoMachine
$nomachineInstaller = "$softwareFolder\NoMachineSetup.exe"
if (Invoke-SafeDownload -url "https://download.nomachine.com/download/8.8/Windows/nomachine_8.8.1_1_x64.exe" -destination $nomachineInstaller) {
    Install-Software -installerPath $nomachineInstaller -installArgs "/S" -softwareName "NoMachine"
}

# TigerVNC
$tigervncInstaller = "$softwareFolder\TigerVNCSetup.exe"
if (Invoke-SafeDownload -url "https://github.com/TigerVNC/tigervnc/releases/download/v1.13.1/TigerVNC-1.13.1-x64.exe" -destination $tigervncInstaller) {
    Install-Software -installerPath $tigervncInstaller -installArgs "/VERYSILENT" -softwareName "TigerVNC"
}

# Final Reboot Check
if (Test-PendingReboot) {
    Write-Log "Reboot required. Restarting..."
    Restart-Computer -Force
} else {
    Write-Log "=== Setup Completed Successfully ==="
    Write-Host "✅ All operations completed. Log saved to: $logFile" -ForegroundColor Green
}
