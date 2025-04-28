@echo off
setlocal enabledelayedexpansion

:: Create log file
set LOG_FILE=%USERPROFILE%\Desktop\windows-automation-log.txt
echo Windows Automation Started > "%LOG_FILE%"

:: Create D:\Software\Installers directory
if not exist "D:\Software\Installers" (
    mkdir "D:\Software\Installers"
    echo [SUCCESS] Created D:\Software\Installers >> "%LOG_FILE%"
) else (
    echo [INFO] D:\Software\Installers already exists >> "%LOG_FILE%"
)

:: Windows Update
echo Updating Windows... >> "%LOG_FILE%"
start /wait powershell -Command "Install-Module PSWindowsUpdate -Force; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -AutoReboot"

:: After updates, script will resume automatically if added to Task Scheduler (future plan)

:: Disable Sleep Settings
echo Disabling Sleep Settings... >> "%LOG_FILE%"
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0
powercfg -change -hibernate-timeout-ac 0
powercfg -change -hibernate-timeout-dc 0
echo [SUCCESS] Sleep settings disabled >> "%LOG_FILE%"

:: Disable Windows Firewall
echo Disabling Windows Firewall... >> "%LOG_FILE%"
netsh advfirewall set allprofiles state off
echo [SUCCESS] Windows Firewall disabled >> "%LOG_FILE%"

:: Download Installers
echo Downloading Installers... >> "%LOG_FILE%"

:: Chrome
powershell -Command "Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'D:\Software\Installers\chrome_installer.exe'"

:: Firefox
powershell -Command "Invoke-WebRequest -Uri 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US' -OutFile 'D:\Software\Installers\firefox_installer.exe'"

:: UltraViewer
powershell -Command "Invoke-WebRequest -Uri 'https://ultraviewer.net/UltraViewer_setup.exe' -OutFile 'D:\Software\Installers\ultraviewer_installer.exe'"

:: AnyDesk
powershell -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'D:\Software\Installers\anydesk_installer.exe'"

:: NoMachine
powershell -Command "Invoke-WebRequest -Uri 'https://download.nomachine.com/download/8.11/Windows/nomachine_8.11.3_1_x64.exe' -OutFile 'D:\Software\Installers\nomachine_installer.exe'"

:: TigerVNC
powershell -Command "Invoke-WebRequest -Uri 'https://downloads.sourceforge.net/project/tigervnc/stable/1.13.1/tigervnc-1.13.1.exe' -OutFile 'D:\Software\Installers\tigervnc_installer.exe'"

:: WinRAR
powershell -Command "Invoke-WebRequest -Uri 'https://www.rarlab.com/rar/winrar-x64-624.exe' -OutFile 'D:\Software\Installers\winrar_installer.exe'"

:: doPDF
powershell -Command "Invoke-WebRequest -Uri 'https://www.dopdf.com/download/setup/dopdf-full.exe' -OutFile 'D:\Software\Installers\dopdf_installer.exe'"

echo [SUCCESS] All installers downloaded >> "%LOG_FILE%"

:: Install Applications
echo Installing Applications... >> "%LOG_FILE%"

start /wait D:\Software\Installers\chrome_installer.exe /silent /install
start /wait D:\Software\Installers\firefox_installer.exe /silent
start /wait D:\Software\Installers\ultraviewer_installer.exe /silent
start /wait D:\Software\Installers\anydesk_installer.exe --install
start /wait D:\Software\Installers\nomachine_installer.exe /quiet
start /wait D:\Software\Installers\tigervnc_installer.exe /S
start /wait D:\Software\Installers\winrar_installer.exe /S
start /wait D:\Software\Installers\dopdf_installer.exe /VERYSILENT

echo [SUCCESS] All applications installed >> "%LOG_FILE%"

:: Create Desktop Shortcuts (only for Chrome, Firefox, UltraViewer, AnyDesk)
echo Creating Desktop Shortcuts... >> "%LOG_FILE%"

powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\Google Chrome.lnk');$s.TargetPath='C:\Program Files\Google\Chrome\Application\chrome.exe';$s.Save()"
powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\Mozilla Firefox.lnk');$s.TargetPath='C:\Program Files\Mozilla Firefox\firefox.exe';$s.Save()"
powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\UltraViewer.lnk');$s.TargetPath='C:\Program Files\UltraViewer\UltraViewer.exe';$s.Save()"
powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\AnyDesk.lnk');$s.TargetPath='C:\Program Files (x86)\AnyDesk\AnyDesk.exe';$s.Save()"

echo [SUCCESS] Desktop Shortcuts Created >> "%LOG_FILE%"

:: Done
echo Windows Automation Completed Successfully! >> "%LOG_FILE%"
exit
