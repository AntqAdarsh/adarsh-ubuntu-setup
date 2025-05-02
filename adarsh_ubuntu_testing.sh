#!/bin/bash

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
warning_log=()

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

pin_to_dock() {
  local app=$1
  desktop_file=$(find /usr/share/applications/ ~/.local/share/applications/ -name "$app.desktop" 2>/dev/null | head -n 1)
  
  if [ -n "$desktop_file" ]; then
    current_favorites=$(gsettings get org.gnome.shell favorite-apps)
    if [[ "$current_favorites" != *"$app.desktop"* ]]; then
      new_favorites=$(echo "$current_favorites" | sed "s/]$/, '$app.desktop']/")
      if gsettings set org.gnome.shell favorite-apps "$new_favorites"; then
        log_success "Pinned $app to dock"
      else
        log_warning "Failed to pin $app to dock"
      fi
    fi
  else
    log_warning "$app.desktop file not found"
  fi
}

install_with_retry() {
  local cmd=$1
  local desc=$2
  local max_retries=3
  local attempt=1
  
  while [ $attempt -le $max_retries ]; do
    if eval "$cmd"; then
      log_success "$desc"
      return 0
    fi
    ((attempt++))
    sleep 2
  done
  
  log_failure "$desc"
  return 1
}

# System update & upgrade
header "System Update"
install_with_retry "sudo apt-get update --fix-missing" "Package list update"
install_with_retry "sudo apt-get upgrade -y" "System upgrade"
install_with_retry "sudo apt-get dist-upgrade -y" "Distribution upgrade"

# Install basic dependencies
header "Installing Dependencies"
install_with_retry "sudo apt-get install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release expect cups rar unrar cups-pdf" "Basic dependencies"

# Install Chrome
header "Installing Google Chrome"
install_with_retry "wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo dpkg -i /tmp/google-chrome.deb" "Chrome installation"
pin_to_dock "google-chrome"

# Install LibreOffice
header "Installing LibreOffice"
install_with_retry "sudo apt-get install -y libreoffice" "LibreOffice installation"

# Install AnyDesk
header "Installing AnyDesk"
install_with_retry "wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /usr/share/keyrings/anydesk.gpg && echo 'deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main' | sudo tee /etc/apt/sources.list.d/anydesk.list && sudo apt-get update && sudo apt-get install -y anydesk" "AnyDesk installation"
pin_to_dock "anydesk"

# Install RustDesk
header "Installing RustDesk"
install_with_retry "wget -q -O /tmp/rustdesk.deb https://github.com/rustdesk/rustdesk/releases/download/1.2.6/rustdesk-1.2.6-x86_64.deb && sudo apt install -fy /tmp/rustdesk.deb" "RustDesk installation"
pin_to_dock "rustdesk"

# HP Printer Setup
header "Printer Setup"
install_with_retry "sudo apt-get install -y hplip hplip-gui" "HPLIP installation"

# HP Plugin Installation
header "HP Plugin Setup"
if [ -x "$(command -v expect)" ]; then
  sudo -u "$SUDO_USER" expect <<EOF
spawn hp-plugin -i
expect {
  "Do you accept the license agreement*" { send "y\r"; exp_continue }
  "Download and install the plug-in*" { send "d\r"; exp_continue }
  eof
}
EOF
  [ $? -eq 0 ] && log_success "HP Plugin installed" || log_failure "HP Plugin installation"
else
  log_failure "Expect not found for HP Plugin setup"
fi

# Printer Detection
header "Printer Detection"
printer_detected=false
for i in {1..15}; do
  if lsusb | grep -i hp; then
    printer_detected=true
    break
  fi
  echo "Waiting for printer... ($i/15)"
  sleep 3
done

if $printer_detected; then
  sudo -u "$SUDO_USER" expect <<EOF
spawn hp-setup -i
expect {
  "Found USB printers*" { send "1\r"; exp_continue }
  eof
}
EOF
  [ $? -eq 0 ] && log_success "Printer configured" || log_failure "Printer configuration"
else
  log_failure "No printer detected"
fi

# Create Depo User
header "User Creation"
if id "Depo" &>/dev/null; then
  log_warning "User Depo already exists"
else
  sudo useradd -m -s /bin/bash Depo && \
  echo "Depo:depo" | sudo chpasswd && \
  sudo usermod -aG sudo Depo && log_success "User Depo created" || log_failure "User creation"
fi

# Final Summary
header "Setup Summary"
echo -e "\nSUCCESSES:"
printf "• %s\n" "${success_log[@]}"
echo -e "\nWARNINGS:"
printf "• %s\n" "${warning_log[@]}"
echo -e "\nFAILURES:"
printf "• %s\n" "${failure_log[@]}"

# Save log to desktop
cp "$LOG_FILE" "$HOME/Desktop/adarshsetup-log.txt" 2>/dev/null && \
  echo -e "\nLog saved to Desktop" || \
  echo -e "\nFailed to save log to Desktop"

echo -e "\nRebooting in 5 seconds..."
sleep 5
sudo reboot
