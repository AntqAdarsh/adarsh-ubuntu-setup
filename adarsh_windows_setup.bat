@echo off
set LOG_FILE=%USERPROFILE%\Desktop\windows-automation-log.txt

rem Check Internet Connectivity
echo [INFO] Checking Internet Connection... >> %LOG_FILE%
echo Checking Internet Connection...
ping -n 1 google.com >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No internet connection detected. Please connect to the internet and press any key to continue... >> %LOG_FILE%
    echo No internet connection detected. Please connect to the internet and press any key to continue...
    pause
    rem Wait until the user connects the device to the internet
    :waitForInternet
    ping -n 1 google.com >nul 2>&1
    if errorlevel 1 (
        echo Still no internet connection. Waiting for connection... >> %LOG_FILE%
        echo Still no internet connection. Waiting for connection...
        timeout /t 5 >nul
        goto waitForInternet
    )
    echo [INFO] Internet connection detected! >> %LOG_FILE%
    echo Internet connection detected!
)

rem Create Software Folder in D: Drive
echo [INFO] Creating Software folder in D:\... >> %LOG_FILE%
mkdir D:\Software

rem Set the default download path to D:\Software
set DOWNLOAD_PATH=D:\Software

rem Download Google Chrome Installer
echo [INFO] Downloading Google Chrome... >> %LOG_FILE%
echo Downloading Google Chrome...
powershell -Command "Invoke-WebRequest 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb' -OutFile '%DOWNLOAD_PATH%\chrome_installer.deb'"
if errorlevel 1 (
    echo [ERROR] Failed to download Google Chrome installer. >> %LOG_FILE%
    echo Failed to download Google Chrome installer.
    exit /b 1
)
echo [SUCCESS] Google Chrome downloaded. >> %LOG_FILE%
echo Google Chrome downloaded.

rem Install Google Chrome
echo [INFO] Installing Google Chrome... >> %LOG_FILE%
echo Installing Google Chrome...
start /wait powershell -Command "Start-Process 'msiexec.exe' -ArgumentList '/i', '%DOWNLOAD_PATH%\chrome_installer.deb', '/quiet', '/norestart' -NoNewWindow -Wait"
if errorlevel 1 (
    echo [ERROR] Failed to install Google Chrome. >> %LOG_FILE%
    echo Failed to install Google Chrome.
    exit /b 1
)
echo [SUCCESS] Google Chrome installed. >> %LOG_FILE%
echo Google Chrome installed.

rem Download Firefox Installer
echo [INFO] Downloading Mozilla Firefox... >> %LOG_FILE%
echo Downloading Mozilla Firefox...
powershell -Command "Invoke-WebRequest 'https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US' -OutFile '%DOWNLOAD_PATH%\firefox_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download Firefox installer. >> %LOG_FILE%
    echo Failed to download Firefox installer.
    exit /b 1
)
echo [SUCCESS] Firefox downloaded. >> %LOG_FILE%
echo Firefox downloaded.

rem Install Firefox
echo [INFO] Installing Firefox... >> %LOG_FILE%
echo Installing Firefox...
start /wait %DOWNLOAD_PATH%\firefox_installer.exe /silent
if errorlevel 1 (
    echo [ERROR] Failed to install Firefox. >> %LOG_FILE%
    echo Failed to install Firefox.
    exit /b 1
)
echo [SUCCESS] Firefox installed. >> %LOG_FILE%
echo Firefox installed.

rem Download WinRAR Installer
echo [INFO] Downloading WinRAR... >> %LOG_FILE%
echo Downloading WinRAR...
powershell -Command "Invoke-WebRequest 'https://www.rarlab.com/rar/winrar-x64-611.exe' -OutFile '%DOWNLOAD_PATH%\winrar_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download WinRAR installer. >> %LOG_FILE%
    echo Failed to download WinRAR installer.
    exit /b 1
)
echo [SUCCESS] WinRAR downloaded. >> %LOG_FILE%
echo WinRAR downloaded.

rem Install WinRAR
echo [INFO] Installing WinRAR... >> %LOG_FILE%
echo Installing WinRAR...
start /wait %DOWNLOAD_PATH%\winrar_installer.exe /S
if errorlevel 1 (
    echo [ERROR] Failed to install WinRAR. >> %LOG_FILE%
    echo Failed to install WinRAR.
    exit /b 1
)
echo [SUCCESS] WinRAR installed. >> %LOG_FILE%
echo WinRAR installed.

rem Download UltraViewer Installer
echo [INFO] Downloading UltraViewer... >> %LOG_FILE%
echo Downloading UltraViewer...
powershell -Command "Invoke-WebRequest 'https://www.ultraviewer.net/download/ultraviewer_setup.exe' -OutFile '%DOWNLOAD_PATH%\ultraviewer_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download UltraViewer installer. >> %LOG_FILE%
    echo Failed to download UltraViewer installer.
    exit /b 1
)
echo [SUCCESS] UltraViewer downloaded. >> %LOG_FILE%
echo UltraViewer downloaded.

rem Install UltraViewer
echo [INFO] Installing UltraViewer... >> %LOG_FILE%
echo Installing UltraViewer...
start /wait %DOWNLOAD_PATH%\ultraviewer_installer.exe /S
if errorlevel 1 (
    echo [ERROR] Failed to install UltraViewer. >> %LOG_FILE%
    echo Failed to install UltraViewer.
    exit /b 1
)
echo [SUCCESS] UltraViewer installed. >> %LOG_FILE%
echo UltraViewer installed.

rem Download AnyDesk Installer
echo [INFO] Downloading AnyDesk... >> %LOG_FILE%
echo Downloading AnyDesk...
powershell -Command "Invoke-WebRequest 'https://download.anydesk.com/anydesk.exe' -OutFile '%DOWNLOAD_PATH%\anydesk_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download AnyDesk installer. >> %LOG_FILE%
    echo Failed to download AnyDesk installer.
    exit /b 1
)
echo [SUCCESS] AnyDesk downloaded. >> %LOG_FILE%
echo AnyDesk downloaded.

rem Install AnyDesk
echo [INFO] Installing AnyDesk... >> %LOG_FILE%
echo Installing AnyDesk...
start /wait %DOWNLOAD_PATH%\anydesk_installer.exe /silent
if errorlevel 1 (
    echo [ERROR] Failed to install AnyDesk. >> %LOG_FILE%
    echo Failed to install AnyDesk.
    exit /b 1
)
echo [SUCCESS] AnyDesk installed. >> %LOG_FILE%
echo AnyDesk installed.

rem Download NoMachine Installer
echo [INFO] Downloading NoMachine... >> %LOG_FILE%
echo Downloading NoMachine...
powershell -Command "Invoke-WebRequest 'https://www.nomachine.com/download-package?platform=windows' -OutFile '%DOWNLOAD_PATH%\nomachine_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download NoMachine installer. >> %LOG_FILE%
    echo Failed to download NoMachine installer.
    exit /b 1
)
echo [SUCCESS] NoMachine downloaded. >> %LOG_FILE%
echo NoMachine downloaded.

rem Install NoMachine
echo [INFO] Installing NoMachine... >> %LOG_FILE%
echo Installing NoMachine...
start /wait %DOWNLOAD_PATH%\nomachine_installer.exe /silent
if errorlevel 1 (
    echo [ERROR] Failed to install NoMachine. >> %LOG_FILE%
    echo Failed to install NoMachine.
    exit /b 1
)
echo [SUCCESS] NoMachine installed. >> %LOG_FILE%
echo NoMachine installed.

rem Download DoPDF Installer
echo [INFO] Downloading DoPDF... >> %LOG_FILE%
echo Downloading DoPDF...
powershell -Command "Invoke-WebRequest 'https://www.dopdf.com/dopdf-10-6-122.exe' -OutFile '%DOWNLOAD_PATH%\dopdf_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download DoPDF installer. >> %LOG_FILE%
    echo Failed to download DoPDF installer.
    exit /b 1
)
echo [SUCCESS] DoPDF downloaded. >> %LOG_FILE%
echo DoPDF downloaded.

rem Install DoPDF
echo [INFO] Installing DoPDF... >> %LOG_FILE%
echo Installing DoPDF...
start /wait %DOWNLOAD_PATH%\dopdf_installer.exe /silent
if errorlevel 1 (
    echo [ERROR] Failed to install DoPDF. >> %LOG_FILE%
    echo Failed to install DoPDF.
    exit /b 1
)
echo [SUCCESS] DoPDF installed. >> %LOG_FILE%
echo DoPDF installed.

rem Download TigerVNC Installer
echo [INFO] Downloading TigerVNC... >> %LOG_FILE%
echo Downloading TigerVNC...
powershell -Command "Invoke-WebRequest 'https://github.com/TigerVNC/tigervnc/releases/download/v1.11.0/tigervnc-1.11.0.x64.exe' -OutFile '%DOWNLOAD_PATH%\tigervnc_installer.exe'"
if errorlevel 1 (
    echo [ERROR] Failed to download TigerVNC installer. >> %LOG_FILE%
    echo Failed to download TigerVNC installer.
    exit /b 1
)
echo [SUCCESS] TigerVNC downloaded. >> %LOG_FILE%
echo TigerVNC downloaded.

rem Install TigerVNC
echo [INFO] Installing TigerVNC... >> %LOG_FILE%
echo Installing TigerVNC...
start /wait %DOWNLOAD_PATH%\tigervnc_installer.exe /S
if errorlevel 1 (
    echo [ERROR] Failed to install TigerVNC. >> %LOG_FILE%
    echo Failed to install TigerVNC.
    exit /b 1
)
echo [SUCCESS] TigerVNC installed. >> %LOG_FILE%
echo TigerVNC installed.

echo [INFO] All software installed successfully! >> %LOG_FILE%
echo All software installed successfully!
exit /b 0
