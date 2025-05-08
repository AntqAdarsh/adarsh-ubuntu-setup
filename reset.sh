#!/bin/bash

LOG="/tmp/reset_ubuntu.log"
echo "Starting Ubuntu Reset..." | tee "$LOG"

# Function to log success and failure
log() {
  echo -e "$1" | tee -a "$LOG"
}

# Remove installed packages
log "\n[INFO] Removing installed applications..."
sudo apt-get purge -y google-chrome-stable anydesk rustdesk libreoffice hplip hp-ppd cups-pdf cups
sudo apt-get autoremove -y
sudo apt-get autoclean -y
log "[DONE] Packages removed."

# Reset GNOME settings and favorites
log "\n[INFO] Resetting GNOME and Dock settings..."
dconf reset -f /
gsettings reset-recursively org.gnome.shell
log "[DONE] GNOME settings reset."

# Remove user 'Depo' if exists
log "\n[INFO] Deleting user 'Depo'..."
if id "Depo" &>/dev/null; then
  sudo deluser --remove-home Depo
  log "[DONE] User 'Depo' removed."
else
  log "[SKIP] User 'Depo' not found."
fi

# Remove HP printer configuration
log "\n[INFO] Removing printer configuration and HP setup files..."
sudo rm -rf /etc/cups /var/spool/cups /var/log/cups /var/cache/cups /usr/share/ppd/HP
sudo apt-get install --reinstall -y cups
sudo systemctl restart cups
log "[DONE] CUPS reset."

# Remove logs
log "\n[INFO] Removing log files..."
rm -f /tmp/adarshsetup.log "$HOME/Desktop/adarshsetup-log.txt"
log "[DONE] Log files deleted."

# Final message
log "\n[INFO] Ubuntu has been reset. Rebooting in 15 seconds..."
sleep 15
sudo reboot
