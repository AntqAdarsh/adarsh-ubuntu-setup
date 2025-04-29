# Define log file location
$logFile = "$env:USERPROFILE\Desktop\windows_setup_log.txt"

# Create a log function to log the progress
Function Write-Log {
    param (
        [string]$message,
        [string]$logType = "[INFO]"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp $logType $message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# Check if the computer is connected to the internet
Function Test-InternetConnection {
    Write-Log "Checking Internet Connection..."
    try {
        $response = Test-Connection -ComputerName google.com -Count 1 -Quiet
        If ($response) {
            Write-Log "Internet is connected."
            return $true
        }
        else {
            Write-Log "No Internet connection detected."
            return $false
        }
    }
    catch {
        Write-Log "Error while checking internet connection: $_"
        return $false
    }
}

# Function to handle retries for failed downloads
Function Retry-Download {
    param (
        [string]$url,
        [string]$destination,
        [int]$maxRetries = 2
    )
    $retries = 0
    $success = $false
    while ($retries -le $maxRetries) {
        try {
            Write-Log "Downloading $url..."
            Invoke-WebRequest -Uri $url -OutFile $destination
            $success = $true
            Write-Log "Download successful: $destination"
            break
        }
        catch {
            $retries++
            Write-Log "Download failed (Attempt $retries of $maxRetries). Error: $_"
            if ($retries -gt $maxRetries) {
                Write-Log "Max retries reached. Aborting download."
            }
        }
    }
    return $success
}

# Start Windows Update
Write-Log "Starting Windows Update..."
try {
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-Null
    Write-Log "Windows Update completed successfully."
}
catch {
    Write-Log "Error during Windows Update: $_" -logType "[ERROR]"
}

# Disable sleep settings to never sleep
Write-Log "Disabling sleep settings..."
powercfg -change standby-timeout-ac 0
powercfg -change standby-timeout-dc 0
Write-Log "Sleep settings disabled successfully."

# Disable Windows Firewall
Write-Log "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Log "Firewall disabled for all profiles."

# Start software installations
$softwareFolder = "D:\Software"
If (!(Test-Path -Path $softwareFolder)) {
    Write-Log "Creating Software directory on D:..."
    New-Item -ItemType Directory -Path $softwareFolder | Out-Null
}

# Chrome Installation
Write-Log "Downloading Google Chrome..."
$chromeInstaller = "$softwareFolder\ChromeSetup.exe"
$chromeUrl = "https://dl.google.com/chrome/install/standalonesetup64.exe"
if (Retry-Download -url $chromeUrl -destination $chromeInstaller) {
    Write-Log "Installing Google Chrome..."
    Start-Process -FilePath $chromeInstaller -Args "/silent /install" -Wait
    Write-Log "Google Chrome installed successfully."
} else {
    Write-Log "Google Chrome installation failed." -logType "[ERROR]"
}

# Firefox Installation
Write-Log "Downloading Firefox..."
$firefoxInstaller = "$softwareFolder\FirefoxSetup.exe"
$firefoxUrl = "https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US"
if (Retry-Download -url $firefoxUrl -destination $firefoxInstaller) {
    Write-Log "Installing Firefox..."
    Start-Process -FilePath $firefoxInstaller -Args "/silent" -Wait
    Write-Log "Firefox installed successfully."
} else {
    Write-Log "Firefox installation failed." -logType "[ERROR]"
}

# WinRAR Installation
Write-Log "Downloading WinRAR..."
$winrarInstaller = "$softwareFolder\WinRARSetup.exe"
$winrarUrl = "https://www.rarlab.com/rar/winrar-x64-611.exe"
if (Retry-Download -url $winrarUrl -destination $winrarInstaller) {
    Write-Log "Installing WinRAR..."
    Start-Process -FilePath $winrarInstaller -Args "/S" -Wait
    Write-Log "WinRAR installed successfully."
} else {
    Write-Log "WinRAR installation failed." -logType "[ERROR]"
}

# UltraViewer Installation
Write-Log "Downloading UltraViewer..."
$ultraviewerInstaller = "$softwareFolder\UltraViewerSetup.exe"
$ultraviewerUrl = "https://www.ultraviewer.net/download/UltraViewerSetup.exe"
if (Retry-Download -url $ultraviewerUrl -destination $ultraviewerInstaller) {
    Write-Log "Installing UltraViewer..."
    Start-Process -FilePath $ultraviewerInstaller -Args "/silent" -Wait
    Write-Log "UltraViewer installed successfully."
} else {
    Write-Log "UltraViewer installation failed." -logType "[ERROR]"
}

# AnyDesk Installation
Write-Log "Downloading AnyDesk..."
$anydeskInstaller = "$softwareFolder\AnyDeskSetup.exe"
$anydeskUrl = "https://download.anydesk.com/AnyDesk.exe"
if (Retry-Download -url $anydeskUrl -destination $anydeskInstaller) {
    Write-Log "Installing AnyDesk..."
    Start-Process -FilePath $anydeskInstaller -Args "/S" -Wait
    Write-Log "AnyDesk installed successfully."
} else {
    Write-Log "AnyDesk installation failed." -logType "[ERROR]"
}

# NoMachine Installation
Write-Log "Downloading NoMachine..."
$nomachineInstaller = "$softwareFolder\NoMachineSetup.exe"
$nomachineUrl = "https://www.nomachine.com/download/download&id=1"
if (Retry-Download -url $nomachineUrl -destination $nomachineInstaller) {
    Write-Log "Installing NoMachine..."
    Start-Process -FilePath $nomachineInstaller -Args "/silent" -Wait
    Write-Log "NoMachine installed successfully."
} else {
    Write-Log "NoMachine installation failed." -logType "[ERROR]"
}

# doPDF Installation
Write-Log "Downloading doPDF..."
$doPdfInstaller = "$softwareFolder\doPDFSetup.exe"
$doPdfUrl = "https://www.dopdf.com/download/dopdf-full.exe"
if (Retry-Download -url $doPdfUrl -destination $doPdfInstaller) {
    Write-Log "Installing doPDF..."
    Start-Process -FilePath $doPdfInstaller -Args "/silent" -Wait
    Write-Log "doPDF installed successfully."
} else {
    Write-Log "doPDF installation failed." -logType "[ERROR]"
}

# TigerVNC Installation
Write-Log "Downloading TigerVNC..."
$tigervncInstaller = "$softwareFolder\TigervncSetup.exe"
$tigervncUrl = "https://github.com/TigerVNC/tigervnc/releases/download/v1.11.0/TigerVNC-1.11.0-x64.exe"
if (Retry-Download -url $tigervncUrl -destination $tigervncInstaller) {
    Write-Log "Installing TigerVNC..."
    Start-Process -FilePath $tigervncInstaller -Args "/silent" -Wait
    Write-Log "TigerVNC installed successfully."
} else {
    Write-Log "TigerVNC installation failed." -logType "[ERROR]"
}

Write-Log "All operations completed. Please check the log file for any errors."
