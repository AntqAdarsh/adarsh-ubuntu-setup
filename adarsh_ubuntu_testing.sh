#!/bin/bash

# Optional flags
NO_REBOOT=false
SKIP_PRINTER=false
for arg in "$@"; do
  case $arg in
    --no-reboot) NO_REBOOT=true ;;
    --skip-printer) SKIP_PRINTER=true ;;
  esac
done

# Password protection
read -sp "Enter script password: " input_pass
echo
SCRIPT_PASSWORD="adarsh@123"
if [ "$input_pass" != "$SCRIPT_PASSWORD" ]; then
  echo "Incorrect password. Exiting..."
  exit 1
fi

LOG_FILE="/tmp/adarshsetup.log"
echo "===== Adarsh Setup Started at $(date) =====" | tee "$LOG_FILE"

success_log=()
failure_log=()

log_success() {
  echo "[SUCCESS] $1" | tee -a "$LOG_FILE"
  success_log+=("$1")
}

log_failure() {
  echo "[FAILED] $1" | tee -a "$LOG_FILE"
  failure_log+=("$1")
}

header() {
  echo -e "\n===== $1 =====" | tee -a "$LOG_FILE"
}

check_and_log() {
  if command -v "$1" &>/dev/null; then
    log_success "$2"
  else
    log_failure "$2"
  fi
}

pin_to_dock() {
  local app=$1
  local desktop_file
  desktop_file=$(find /usr/share/applications/ ~/.local/share/applications/ -name "$app.desktop" 2>/dev/null | head -n 1)

  if [[ -n "$desktop_file" ]]; then
    echo "[INFO] Pinning $app to Dock..."
    current_favorites=$(gsettings get org.gnome.shell favorite-apps)
    if [[ "$current_favorites" != *"$app.desktop"* ]]; then
      new_favorites=$(echo "$current_favorites" | sed "s/]$/, '$app.desktop']/")
      gsettings set org.gnome.shell favorite-apps "$new_favorites"
      echo "[SUCCESS] $app pinned to Dock."
    else
      echo "[INFO] $app is already pinned to Dock."
    fi
  else
    echo "[WARNING] $app.desktop file not found, skipping pinning."
  fi
}

install_hp_plugin() {
  header "Installing HP Plugin"
  sudo -u "$SUDO_USER" expect <<EOF
log_user 1
spawn hp-plugin -i

expect {
  "*Download the plugin*" { send "d\r"; exp_continue }
  "*Do you accept*" { send "a\r"; exp_continue }
  "*Is this OK*" { send "y\r"; exp_continue }
  eof
}
EOF
  if [ $? -eq 0 ]; then
    log_success "HP Plugin Installed Successfully"
  else
    log_failure "HP Plugin Installation Failed"
  fi
}

# Disable sleep
header "Disabling Sleep Settings"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
gsettings set org.gnome.desktop.session idle-delay 0
log_success "Sleep settings set to never sleep"

# System update
header "System Update"
sudo apt-get clean
sudo apt-get update --fix-missing
sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y
[ $? -eq 0 ] && log_success "System update and upgrade" || log_failure "System update and upgrade"

# Dependencies
header "Installing Basic Dependencies"
sudo apt-get install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release expect cups rar unrar cups-pdf
check_and_log curl "Curl Installed"
check_and_log wget "Wget Installed"

# Chrome
header "Installing Google Chrome"
sudo wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i /tmp/google-chrome.deb || sudo apt-get install -f -y
check_and_log google-chrome "Google Chrome Installed"
command -v google-chrome && pin_to_dock "google-chrome"

# LibreOffice
header "Installing LibreOffice"
sudo apt-get install -y libreoffice
check_and_log libreoffice "LibreOffice Installed"

# AnyDesk
header "Installing AnyDesk"
wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /usr/share/keyrings/anydesk.gpg
echo "deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk.list
sudo apt-get update && sudo apt-get install -y anydesk
check_and_log anydesk "AnyDesk Installed"
command -v anydesk && pin_to_dock "anydesk"

# RustDesk
header "Installing RustDesk"
sudo wget https://github.com/rustdesk/rustdesk/releases/download/1.2.6/rustdesk-1.2.6-x86_64.deb -O /tmp/rustdesk.deb
sudo apt install -fy /tmp/rustdesk.deb
check_and_log rustdesk "RustDesk Installed"
command -v rustdesk && pin_to_dock "rustdesk"

# HPLIP
header "Installing HPLIP & GUI"
sudo apt-get install -y hplip hplip-gui
check_and_log hp-toolbox "HPLIP & GUI Installed"

# Printer Setup
if [ "$SKIP_PRINTER" = false ]; then
  header "Waiting for USB Printer Detection"
  echo "Please connect the USB printer..."
  printer_detected=false
  for i in {1..10}; do
    if lsusb | grep -i hp; then
      echo "HP USB Printer detected."
      printer_detected=true
      break
    fi
    sleep 5
    echo "Waiting for printer to be connected... ($i/10)"
  done

  if [ "$printer_detected" = true ]; then
    # Install HP plugin (only after detecting printer)
    install_hp_plugin

    header "Running HP Setup"
    sudo -u "$SUDO_USER" expect <<EOF
log_user 1
spawn hp-setup -i
expect {
  "*Found USB printers*" { send "1\r"; exp_continue }
  eof
}
EOF
    [ $? -eq 0 ] && log_success "HP Setup Completed" || log_failure "HP Setup Failed"

    header "Printing Test Page"
    echo "Test Print from Adarsh Setup Script" > /tmp/testprint.txt
    lp /tmp/testprint.txt
    [ $? -eq 0 ] && log_success "Test print sent successfully" || log_failure "Failed to send test print"
  else
    log_failure "No HP USB printer detected. Skipping printer setup."
  fi
else
  log_failure "Printer setup skipped due to --skip-printer flag."
fi

# Create Depo user
header "Creating User"
sudo useradd -m -s /bin/bash Depo 2>/dev/null
if id "Depo" &>/dev/null; then
  echo "Depo:depo" | sudo chpasswd
  sudo usermod -aG sudo Depo && log_success "User 'Depo' Created and Added to Sudo" || log_failure "User Modification Failed"
else
  log_failure "User Creation Failed"
fi

# Summary
header "Setup Summary"
echo -e "\n\n===== SUCCESSFULLY INSTALLED ====="
for i in "${success_log[@]}"; do echo "- $i"; done

echo -e "\n===== FAILED INSTALLATIONS ====="
for i in "${failure_log[@]}"; do echo "- $i"; done

echo -e "\nAdarsh Setup Completed! Log available at $LOG_FILE"
echo "===== Script Ended at $(date) =====" >> "$LOG_FILE"

# Copy log to Desktop
header "Copying Log File to Desktop"
DESKTOP_PATH_CURRENT="$HOME/Desktop"
FINAL_LOG_NAME="adarshsetup-log.txt"
if [ -d "$DESKTOP_PATH_CURRENT" ]; then
  cp "$LOG_FILE" "$DESKTOP_PATH_CURRENT/$FINAL_LOG_NAME" 2>/dev/null
  [ $? -eq 0 ] && log_success "Log copied to current user's Desktop" || log_failure "Failed to copy log"
else
  log_failure "Current user's Desktop directory not found"
fi

# Reboot
if [ "$NO_REBOOT" = false ]; then
  echo -e "\nRebooting in 5 seconds..."
  sleep 5
  sudo reboot
else
  echo -e "\nSkipping reboot due to --no-reboot flag"
fi
