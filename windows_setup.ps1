# Windows Setup Automation Script
# Author: Adarsh
# Version: 1.0
# Silent, No prompts, Full logging

#==============================#
# SETTINGS
#==============================#
$SoftwareDir = "D:\Software"
$LogFile = "$env:USERPROFILE\Desktop\windows_setup_log.txt"

#==============================#
# FUNCTIONS
#==============================#

function Log-Info($Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "[INFO] $Message"
}

function Log-Success($Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "[SUCCESS] $Message"
}

function Log-Error($Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Add-Content -Path $LogFile -Value "[ERROR] $Message"
}

function Check-Internet {
    Log-Info "Checking Internet Connection..."
    while (!(Test-Connection -ComputerName google.com -Count 1 -Quiet)) {
        Log-Error "No Internet Connection. Retrying in 10 seconds..."
        Start-Sleep -Seconds 10
    }
    Log-Success "Internet Connection is Active."
}

function Create-Software-Folder {
    if (!(Test-Path -Path $SoftwareDir)) {
        New-Item -ItemType Directory -Path $SoftwareDir -Force | Out-Null
        Log-Success "Created Software Folder at $SoftwareDir"
    } else {
        Log-Info "Software Folder already exists."
    }
}

function Download-And-Install ($Name, $Url, $InstallerArgs) {
    $InstallerPath = "$SoftwareDir\$Name.exe"
    Log-Info "Downloading $Name..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $InstallerPath -UseBasicParsing
        Log-Success "$Name downloaded successfully."
    }
    catch {
        Log-Error "Failed to download $Name."
        return
    }
    
    Log-Info "Installing $Name..."
    try {
        Start-Process -FilePath $InstallerPath -ArgumentList $InstallerArgs -Wait -NoNewWindow
        Log-Success "$Name installed successfully."
    }
    catch {
        Log-Error "Failed to install $Name."
    }

    Create-Shortcut $Name
}

function Create-Shortcut($Name) {
    $WshShell = New-Object -ComObject WScript.Shell
    $ProgramPath = (Get-ChildItem "C:\Program Files*\*\$Name.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    if (!$ProgramPath) {
        $ProgramPath = (Get-ChildItem "C:\Program Files*\*\*$Name*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }
    if ($ProgramPath) {
        $ShortcutPath = "$env:USERPROFILE\Desktop\$Name.lnk"
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $ProgramPath
        $Shortcut.Save()
        Log-Success "Shortcut for $Name created on Desktop."
    } else {
        Log-Error "Executable for $Name not found, shortcut not created."
    }
}

function Update-Windows {
    Log-Info "Starting Windows Update..."
    Install-Module PSWindowsUpdate -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-Null
    Log-Success "Windows Update Completed."
}

function Disable-Sleep {
    Log-Info "Disabling Sleep Settings..."
    powercfg -change -standby-timeout-ac 0
    powercfg -change -standby-timeout-dc 0
    powercfg -change -hibernate-timeout-ac 0
    powercfg -change -hibernate-timeout-dc 0
    Log-Success "Sleep disabled for both AC and Battery modes."
}

function Disable-Firewall {
    Log-Info "Disabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Log-Success "Firewall disabled for all profiles."
}

#==============================#
# START EXECUTION
#==============================#

Clear-Host
Log-Info "========================================="
Log-Info "   Windows Setup Automation Started      "
Log-Info "========================================="

Check-Internet
Create-Software-Folder
Update-Windows
Disable-Sleep
Disable-Firewall

# --- Software List to Install
Download-And-Install -Name "GoogleChrome" -Url "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -InstallerArgs "/silent /install"
Download-And-Install -Name "Firefox" -Url "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -InstallerArgs "-ms"
Download-And-Install -Name "WinRAR" -Url "https://www.rarlab.com/rar/winrar-x64.exe" -InstallerArgs "/S"
Download-And-Install -Name "UltraViewer" -Url "https://ultraviewer.net/en/UltraViewer_setup_en.exe" -InstallerArgs "/VERYSILENT"
Download-And-Install -Name "AnyDesk" -Url "https://download.anydesk.com/AnyDesk.exe" -InstallerArgs "--install --start-with-win --silent"
Download-And-Install -Name "NoMachine" -Url "https://download.nomachine.com/download/7.10/Windows/nomachine_7.10.1_1_x64.exe" -InstallerArgs "/silent"
Download-And-Install -Name "doPDF" -Url "https://download.dopdf.com/download/setup/dopdf-full.exe" -InstallerArgs "/VERYSILENT"
Download-And-Install -Name "TigerVNC" -Url "https://bintray.com/tigervnc/stable/download_file?file_path=tigervnc-1.11.0.exe" -InstallerArgs "/S"

Log-Success "All operations completed. Please review $LogFile for details."

Log-Info "========================================="
Log-Info "   Windows Setup Automation Completed     "
Log-Info "========================================="
