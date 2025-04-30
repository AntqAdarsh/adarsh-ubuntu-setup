<#
.SYNOPSIS
    Complete Windows setup automation with progress tracking and error handling.
.DESCRIPTION
    Installs updates, configures system settings, and installs essential software.
    Features progress bar, automatic recovery, and detailed logging.
.NOTES
    Author: Adarsh
    Version: 5.0
    Requirements: Windows 10/11, PowerShell 5.1+, Administrator privileges
#>

#region Initialization
# Configure logging
$logFile = "$env:USERPROFILE\Desktop\Adarsh_WindowsSetup.log"
$errorLogFile = "$env:USERPROFILE\Desktop\Adarsh_WindowsSetup_Errors.log"

# Progress tracking
$totalSteps = 15
$currentStep = 0
$currentOperation = "Initializing"

# Create log files
New-Item -Path $logFile -ItemType File -Force | Out-Null
New-Item -Path $errorLogFile -ItemType File -Force | Out-Null

# Enhanced logging function
function Write-Status {
    param(
        [string]$message,
        [string]$type = "INFO",
        [bool]$increment = $true,
        [string]$operation = $null
    )

    # Update progress
    if ($operation) { $script:currentOperation = $operation }
    if ($increment) { $script:currentStep++ }
    $percentComplete = ($script:currentStep / $script:totalSteps) * 100

    # Format message
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp [$type] $message"
    
    # Display progress
    Write-Progress -Activity "Adarsh's Windows Setup" -Status $currentOperation -CurrentOperation $message -PercentComplete $percentComplete
    
    # Write to logs
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    if ($type -eq "ERROR") { Add-Content -Path $errorLogFile -Value $logMessage -ErrorAction SilentlyContinue }
    
    # Console output
    $color = @{"INFO"="White"; "WARNING"="Yellow"; "ERROR"="Red"}[$type]
    Write-Host $logMessage -ForegroundColor $color
}

# Check administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Status "This script must be run as Administrator." "ERROR" -increment $false
    Start-Sleep 5
    exit 1
}

# Set execution policy
try {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction Stop
    Write-Status "Execution policy configured" -operation "Configuration"
} catch {
    Write-Status "Failed to set execution policy: $_" "ERROR" -increment $false
}

# Configure security protocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#endregion

#region Core Functions
function Invoke-RobustDownload {
    param(
        [string]$url,
        [string]$destination,
        [int]$retries = 3,
        [int]$delay = 5
    )

    $fileName = [System.IO.Path]::GetFileName($destination)
    $attempt = 0
    $success = $false

    while (-not $success -and $attempt -lt $retries) {
        $attempt++
        try {
            Write-Status "Downloading $fileName (Attempt $attempt/$retries)" -operation "Downloading $fileName" -increment $false

            # Use BITS if available
            if (Get-Command -Name Start-BitsTransfer -ErrorAction SilentlyContinue) {
                Start-BitsTransfer -Source $url -Destination $destination -DisplayName "Downloading $fileName" -ErrorAction Stop
            } else {
                # Fallback to WebClient
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($url, $destination)
            }

            # Verify download
            if (Test-Path $destination -PathType Leaf) {
                $fileSize = [math]::Round((Get-Item $destination).Length / 1MB, 2)
                Write-Status "Downloaded $fileName ($fileSize MB)" -increment $false
                $success = $true
            }
        } catch {
            Write-Status "Download attempt $attempt failed: $_" "WARNING" -increment $false
            if (Test-Path $destination) { Remove-Item $destination -Force }
            Start-Sleep $delay
            $delay = [math]::Min($delay * 2, 30) # Exponential backoff
        }
    }

    return $success
}

function Install-Application {
    param(
        [string]$installerPath,
        [string]$arguments,
        [string]$appName,
        [string]$registryPath,
        [string]$registryValue
    )

    try {
        # Check if already installed
        if ($registryPath -and $registryValue) {
            try {
                $installed = Get-ItemPropertyValue -Path $registryPath -Name $registryValue -ErrorAction SilentlyContinue
                if ($installed) {
                    Write-Status "$appName already installed" -increment $false -operation "Installing $appName"
                    return $true
                }
            } catch {}
        }

        Write-Status "Installing $appName" -operation "Installing $appName" -increment $false

        if (-not (Test-Path $installerPath)) {
            throw "Installer not found"
        }

        $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -PassThru -Wait -NoNewWindow

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Status "$appName installed successfully" -increment $false
            return $true
        } else {
            throw "Installation failed with exit code $($process.ExitCode)"
        }
    } catch {
        Write-Status "Failed to install $appName: $_" "ERROR" -increment $false
        return $false
    }
}

function Test-PendingReboot {
    $tests = @(
        { Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue },
        { Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue },
        { (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) -ne $null }
    )

    foreach ($test in $tests) {
        try {
            if (& $test) { return $true }
        } catch {}
    }
    return $false
}
#endregion

#region Main Execution
try {
    # Determine software location
    $softwareFolder = if (Test-Path "D:") { "D:\Software" } else { "C:\Software" }
    if (-not (Test-Path $softwareFolder)) {
        New-Item -ItemType Directory -Path $softwareFolder -Force | Out-Null
        Write-Status "Created software directory: $softwareFolder" -operation "Setup"
    }

    # 1. Windows Updates
    Write-Status "Checking for Windows updates..." -operation "Windows Updates"
    try {
        if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        
        $updates = Get-WindowsUpdate -ErrorAction Stop
        if ($updates) {
            Write-Status "Installing $($updates.Count) updates..." -increment $false
            Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Stop | Out-Null
        }
        Write-Status "Windows updates processed"
    } catch {
        Write-Status "Update process failed: $_" "ERROR"
    }

    # 2. System Configuration
    Write-Status "Configuring system settings..." -operation "System Configuration"
    
    # Power settings
    powercfg -change standby-timeout-ac 0 | Out-Null
    powercfg -change standby-timeout-dc 0 | Out-Null
    powercfg -h off | Out-Null
    
    # Firewall
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop
    
    Write-Status "System settings configured"

    # 3. Software Installation
    $applications = @(
        @{
            Name = "Google Chrome";
            Url = "https://dl.google.com/chrome/install/standalonesetup64.exe";
            Installer = "ChromeSetup.exe";
            Args = "/silent /install";
            RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe";
            RegistryValue = "(default)"
        },
        @{
            Name = "Mozilla Firefox";
            Url = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US";
            Installer = "FirefoxSetup.exe";
            Args = "/S";
            RegistryPath = "HKLM:\SOFTWARE\Mozilla\Mozilla Firefox";
            RegistryValue = "CurrentVersion"
        },
        @{
            Name = "UltraViewer";
            Url = "https://www.ultraviewer.net/files/UltraViewer_Setup.exe";
            Installer = "UltraViewerSetup.exe";
            Args = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART";
            RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\UltraViewer";
            RegistryValue = "DisplayName"
        },
        @{
            Name = "NoMachine";
            Url = "https://download.nomachine.com/download/8.8/Windows/nomachine_8.8.1_1_x64.exe";
            Installer = "NoMachineSetup.exe";
            Args = "/S";
            RegistryPath = "HKLM:\SOFTWARE\NoMachine";
            RegistryValue = "InstallPath"
        },
        @{
            Name = "TigerVNC";
            Url = "https://github.com/TigerVNC/tigervnc/releases/download/v1.13.1/TigerVNC-1.13.1-x64.exe";
            Installer = "TigerVNCSetup.exe";
            Args = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART";
            RegistryPath = "HKLM:\SOFTWARE\TigerVNC";
            RegistryValue = "InstallPath"
        }
    )

    foreach ($app in $applications) {
        $installerPath = "$softwareFolder\$($app.Installer)"
        if (Invoke-RobustDownload -url $app.Url -destination $installerPath) {
            Install-Application -installerPath $installerPath -arguments $app.Args -appName $app.Name -registryPath $app.RegistryPath -registryValue $app.RegistryValue
        }
    }

    # Completion
    if (Test-PendingReboot) {
        Write-Status "Reboot required. Restarting..." -operation "Finalizing"
        Start-Sleep 3
        Restart-Computer -Force
    } else {
        Write-Status "=== Setup Completed Successfully ===" -increment $false -operation "Complete"
        Write-Host "`n✅ All operations completed." -ForegroundColor Green
        Write-Host "✔ Log file: $logFile" -ForegroundColor Cyan
        Write-Host "✔ Error log: $errorLogFile" -ForegroundColor Cyan
    }
} catch {
    Write-Status "Fatal error: $_" "ERROR" -increment $false
    exit 1
} finally {
    Write-Progress -Completed -Activity "Windows Setup Automation"
}
#endregion
