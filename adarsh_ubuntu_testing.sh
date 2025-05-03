#!/bin/bash
set -e

# Password protection
read -sp "Enter script password: " input_pass
echo
SCRIPT_PASSWORD="adarsh@123"

if [ "$input_pass" != "$SCRIPT_PASSWORD" ]; then
  echo "Incorrect password. Exiting..."
  exit 1
fi


LOG_FILE="/tmp/adarshsetup.log"
echo "Starting Adarsh Setup..." | tee "$LOG_FILE"

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

# Pin to Dock function
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

# Disable Sleep
header "Disabling Sleep Settings"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
gsettings set org.gnome.desktop.session idle-delay 0
log_success "Sleep settings set to never sleep"

# Update System
header "System Update"
sudo apt-get clean
sudo apt-get update --fix-missing
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
log_success "System update and upgrade"

# Install Basic Packages
header "Installing Basic Dependencies"
sudo apt-get install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release expect cups rar unrar cups-pdf
check_and_log curl "Curl Installed"
check_and_log wget "Wget Installed"

# Install Google Chrome
header "Installing Google Chrome"
sudo wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i /tmp/google-chrome.deb || sudo apt-get install -f -y
check_and_log google-chrome "Google Chrome Installed"
pin_to_dock "google-chrome"

# Install LibreOffice
header "Installing LibreOffice"
sudo apt-get install -y libreoffice
check_and_log libreoffice "LibreOffice Installed"

# Install AnyDesk
header "Installing AnyDesk"
wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /usr/share/keyrings/anydesk.gpg
echo "deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk.list
sudo apt-get update && sudo apt-get install -y anydesk
check_and_log anydesk "AnyDesk Installed"
pin_to_dock "anydesk"

# Install RustDesk
header "Installing RustDesk"
sudo wget https://github.com/rustdesk/rustdesk/releases/download/1.2.6/rustdesk-1.2.6-x86_64.deb -O /tmp/rustdesk.deb
sudo dpkg -i /tmp/rustdesk.deb || sudo apt-get install -f -y
check_and_log rustdesk "RustDesk Installed"
pin_to_dock "rustdesk"

# Install HPLIP
header "Installing HPLIP & GUI"
sudo apt-get install -y hplip hplip-gui
check_and_log hp-toolbox "HPLIP & GUI Installed"

# Detect USB Printer
header "Waiting for USB Printer Detection"
echo "Please connect the USB printer..."
printer_detected=false
for i in {1..10}; do
  if lsusb | grep -i hp; then
    echo "HP USB Printer detected. Proceeding with setup..."
    printer_detected=true
    break
  fi
  sleep 5
  echo "Waiting for printer to be connected... ($i/10)"
done

# HP Plugin Installation via Expect
header "Installing HP Plugin"
sudo -u "$SUDO_USER" expect <<'EOF'
log_user 1
set timeout -1
spawn hp-plugin -i

expect {
  "*Do you accept the license agreement*" {
    send "a\r"
    exp_continue
  }
  "*Download the plugin from HP*" {
    send "d\r"
    exp_continue
  }
  "*Is this OK*" {
    send "y\r"
    exp_continue
  }
  "*Press 'q' to quit*" {
    send "q"
    exp_continue
  }
  eof
}
EOF

if [ $? -eq 0 ]; then
  log_success "HP Plugin Installed Successfully"
else
  log_failure "HP Plugin Installation Failed"
fi

# HP Setup & Test Print
if [ "$printer_detected" = true ]; then
  header "Running HP Setup"
  sudo -u "$SUDO_USER" expect <<EOF
log_user 1
spawn hp-setup -i

expect {
  "*Found USB printers*" {
    send "1\r"
    exp_continue
  }
  eof
}
EOF

  if [ $? -eq 0 ]; then
    log_success "HP Setup Completed"
  else
    log_failure "HP Setup Failed"
  fi

  header "Printing Test Page"
  echo "Test Print from Adarsh Setup Script" > /tmp/testprint.txt
  lp /tmp/testprint.txt && log_success "Test print sent successfully" || log_failure "Failed to send test print"
else
  log_failure "No HP USB printer detected. Skipping HP Setup and Test Print."
fi

# Create User 'Depo'
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
for i in "${success_log[@]}"; do
  echo "- $i"
done

echo -e "\n===== FAILED INSTALLATIONS ====="
for i in "${failure_log[@]}"; do
  echo "- $i"
done

echo -e "\nAdarsh Setup Completed! Log available at $LOG_FILE"

# Copy Log to SUDO_USER's Desktop
header "Copying Log File to Desktop"
USER_DESKTOP="/home/$SUDO_USER/Desktop"
FINAL_LOG_NAME="adarshsetup-log.txt"

if [ -d "$USER_DESKTOP" ]; then
  cp "$LOG_FILE" "$USER_DESKTOP/$FINAL_LOG_NAME" && \
  log_success "Log copied to $USER_DESKTOP/$FINAL_LOG_NAME" || \
  log_failure "Failed to copy log to Desktop"
else
  log_failure "Could not locate $USER_DESKTOP"
fi

# Clean Temp Files
rm -f /tmp/google-chrome.deb /tmp/rustdesk.deb /tmp/testprint.txt

# Reboot
echo -e "\nRebooting in 5 seconds..."
sleep 5
sudo reboot
