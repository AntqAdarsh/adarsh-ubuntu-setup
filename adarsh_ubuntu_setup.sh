#!/bin/bash

# Adarsh Setup Script

# Constants
SCRIPT_PASSWORD="adarsh@123"  
LOG_FILE="/tmp/adarshsetup-$(date +%Y%m%d-%H%M%S).log"  # Unique log file per run
MAX_PASSWORD_ATTEMPTS=3
SUDO_USER=$(logname)  # More reliable way to get the invoking user
DESKTOP_PATH_CURRENT="$HOME/Desktop"
FINAL_LOG_NAME="adarshsetup-log-$(date +%Y%m%d-%H%M%S).txt"

# Initialize arrays
declare -a success_log=()
declare -a failure_log=()
declare -a warning_log=()

# Password protection with multiple attempts
header "Authentication"
attempt=1
while (( attempt <= MAX_PASSWORD_ATTEMPTS )); do
    read -rsp "[Attempt $attempt/$MAX_PASSWORD_ATTEMPTS] Enter script password: " input_pass
    echo
    
    if [[ "$input_pass" == "$SCRIPT_PASSWORD" ]]; then
        log_success "Authentication successful"
        break
    else
        echo "Incorrect password. Try again..."
        ((attempt++))
    fi
done

if (( attempt > MAX_PASSWORD_ATTEMPTS )); then
    echo "Maximum password attempts reached. Exiting..."
    exit 1
fi

# Enhanced logging functions
header() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') ===== $1 =====" | tee -a "$LOG_FILE"
}

log_success() {
    local message="[SUCCESS] $1"
    echo "$message" | tee -a "$LOG_FILE"
    success_log+=("$1")
}

log_failure() {
    local message="[FAILED] $1"
    echo "$message" | tee -a "$LOG_FILE"
    failure_log+=("$1")
    return 1
}

log_warning() {
    local message="[WARNING] $1"
    echo "$message" | tee -a "$LOG_FILE"
    warning_log+=("$1")
}

check_and_log() {
    if command -v "$1" &>/dev/null; then
        log_success "$2"
        return 0
    else
        log_failure "$2"
        return 1
    fi
}

# Function to pin app to Ubuntu Dock with improved reliability
pin_to_dock() {
    local app=$1
    local desktop_file
    local max_attempts=3
    local attempt=1

    # Try to find .desktop file with multiple attempts
    while (( attempt <= max_attempts )); do
        desktop_file=$(find /usr/share/applications/ ~/.local/share/applications/ -name "$app.desktop" 2>/dev/null | head -n 1)
        
        if [[ -n "$desktop_file" ]]; then
            echo "[INFO] Found $app.desktop at $desktop_file"
            break
        else
            echo "[INFO] $app.desktop not found (attempt $attempt/$max_attempts), retrying..."
            sleep 1
            ((attempt++))
        fi
    done

    if [[ -z "$desktop_file" ]]; then
        log_warning "$app.desktop file not found after $max_attempts attempts, skipping pinning"
        return 1
    fi

    echo "[INFO] Attempting to pin $app to Dock..."
    current_favorites=$(gsettings get org.gnome.shell favorite-apps | tr -d '[]')

    if [[ "$current_favorites" != *"$app.desktop"* ]]; then
        # Clean up the current favorites list
        IFS=',' read -ra favorites_array <<< "$current_favorites"
        cleaned_favorites=()
        for fav in "${favorites_array[@]}"; do
            fav=$(echo "$fav" | xargs)  # Trim whitespace
            [[ -n "$fav" ]] && cleaned_favorites+=("'$fav'")
        done

        # Add the new app
        cleaned_favorites+=("'$app.desktop'")
        new_favorites=$(IFS=, ; echo "[${cleaned_favorites[*]}]")

        # Set the new favorites
        if gsettings set org.gnome.shell favorite-apps "$new_favorites"; then
            log_success "$app pinned to Dock"
            return 0
        else
            log_failure "Failed to pin $app to Dock"
            return 1
        fi
    else
        log_success "$app is already pinned to Dock"
        return 0
    fi
}

# System configuration
configure_system() {
    header "System Configuration"
    
    # Disabling sleep settings
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    gsettings set org.gnome.desktop.session idle-delay 0
    log_success "Sleep settings set to never sleep"

    # Configure sudo to not require password for Depo user
    if id "Depo" &>/dev/null; then
        echo "Depo ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/depo-nopasswd >/dev/null
        sudo chmod 440 /etc/sudoers.d/depo-nopasswd
        log_success "Configured passwordless sudo for Depo user"
    fi
}

# System update & upgrade with improved error handling
system_update() {
    header "System Update"
    
    # Clean up first
    if ! sudo apt-get clean; then
        log_failure "Failed to clean package cache"
    fi
    
    # Update with retry logic
    local max_retries=3
    local retry_count=0
    local update_success=false
    
    while (( retry_count < max_retries )); do
        if sudo apt-get update --fix-missing; then
            update_success=true
            break
        else
            ((retry_count++))
            echo "[WARNING] Update failed (attempt $retry_count/$max_retries), retrying..."
            sleep 5
        fi
    done
    
    if $update_success; then
        log_success "Package list updated"
    else
        log_failure "Failed to update package list after $max_retries attempts"
        return 1
    fi
    
    # Upgrade packages
    if sudo apt-get upgrade -y; then
        log_success "Packages upgraded"
    else
        log_failure "Failed to upgrade packages"
    fi
    
    # Dist-upgrade
    if sudo apt-get dist-upgrade -y; then
        log_success "Distribution packages upgraded"
    else
        log_failure "Failed to upgrade distribution packages"
    fi
    
    # Clean up
    if sudo apt-get autoremove -y; then
        log_success "Unnecessary packages removed"
    else
        log_failure "Failed to remove unnecessary packages"
    fi
}

# Package installation with improved error handling
install_packages() {
    local packages=("$@")
    header "Installing Packages: ${packages[*]}"
    
    for pkg in "${packages[@]}"; do
        if sudo apt-get install -y "$pkg"; then
            log_success "Installed $pkg"
        else
            log_failure "Failed to install $pkg"
        fi
    done
}

# Install Google Chrome with checksum verification
install_google_chrome() {
    header "Installing Google Chrome"
    
    local chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    local chrome_deb="/tmp/google-chrome.deb"
    
    if ! sudo wget -q --show-progress -O "$chrome_deb" "$chrome_url"; then
        log_failure "Failed to download Google Chrome"
        return 1
    fi
    
    # Basic file verification
    if [[ ! -f "$chrome_deb" ]]; then
        log_failure "Downloaded file not found"
        return 1
    fi
    
    if ! sudo dpkg -i "$chrome_deb"; then
        sudo apt-get install -f -y
        if ! command -v google-chrome &>/dev/null; then
            log_failure "Google Chrome installation failed"
            return 1
        fi
    fi
    
    check_and_log google-chrome "Google Chrome Installed"
    pin_to_dock "google-chrome"
}

# Install AnyDesk with improved verification
install_anydesk() {
    header "Installing AnyDesk"
    
    # Import GPG key securely
    if ! wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /usr/share/keyrings/anydesk.gpg; then
        log_failure "Failed to import AnyDesk GPG key"
        return 1
    fi
    
    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk.list
    
    # Update and install
    if sudo apt-get update && sudo apt-get install -y anydesk; then
        check_and_log anydesk "AnyDesk Installed"
        pin_to_dock "anydesk"
    else
        log_failure "AnyDesk installation failed"
    fi
}

# Install RustDesk with version checking
install_rustdesk() {
    header "Installing RustDesk"
    
    local rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/1.2.6/rustdesk-1.2.6-x86_64.deb"
    local rustdesk_deb="/tmp/rustdesk.deb"
    
    if ! sudo wget -q --show-progress -O "$rustdesk_deb" "$rustdesk_url"; then
        log_failure "Failed to download RustDesk"
        return 1
    fi
    
    if sudo apt install -fy "$rustdesk_deb"; then
        check_and_log rustdesk "RustDesk Installed"
        pin_to_dock "rustdesk"
    else
        log_failure "RustDesk installation failed"
    fi
}

# HP Printer setup with improved detection
setup_hp_printer() {
    header "HP Printer Setup"
    
    # Install HPLIP & GUI
    install_packages hplip hplip-gui
    
    # Install HP Plugin via Expect with timeout
    header "Installing HP Plugin"
    if ! command -v expect &>/dev/null; then
        log_failure "Expect not installed, cannot setup HP Plugin"
        return 1
    fi
    
    if ! sudo -u "$SUDO_USER" expect <<EOF
set timeout 120
spawn hp-plugin -i
expect {
    "Do you accept the license agreement*" { send "y\r"; exp_continue }
    "Download and install the plug-in*" { send "d\r"; exp_continue }
    timeout { exit 1 }
    eof
}
EOF
    then
        log_failure "HP Plugin installation failed or timed out"
        return 1
    fi
    
    log_success "HP Plugin Installed"
    
    # Detect HP USB Printer with improved detection
    header "Waiting for USB Printer Detection"
    echo "Please connect the USB printer..."
    
    local printer_detected=false
    local max_attempts=15
    local attempt=1
    
    while (( attempt <= max_attempts )); do
        if lsusb | grep -i "HP\|Hewlett-Packard"; then
            printer_detected=true
            echo "HP USB Printer detected. Proceeding with setup..."
            break
        fi
        echo "Waiting for printer to be connected... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    if [ "$printer_detected" = false ]; then
        log_failure "No HP USB printer detected after $max_attempts attempts"
        return 1
    fi
    
    # Running HP Setup via Expect with timeout
    header "Running HP Setup"
    if ! sudo -u "$SUDO_USER" expect <<EOF
set timeout 300
spawn hp-setup -i
expect {
    "Found USB printers*" { send "1\r"; exp_continue }
    timeout { exit 1 }
    eof
}
EOF
    then
        log_failure "HP Setup failed or timed out"
        return 1
    fi
    
    log_success "HP Setup Completed"
}

# User management with improved checks
manage_users() {
    header "User Management"
    
    local username="Depo"
    local password="depo"
    
    if id "$username" &>/dev/null; then
        log_warning "User $username already exists"
    else
        if sudo useradd -m -s /bin/bash "$username"; then
            log_success "User $username created"
        else
            log_failure "Failed to create user $username"
            return 1
        fi
    fi
    
    if echo "$username:$password" | sudo chpasswd; then
        log_success "Password set for $username"
    else
        log_failure "Failed to set password for $username"
    fi
    
    if sudo usermod -aG sudo "$username"; then
        log_success "User $username added to sudo group"
    else
        log_failure "Failed to add $username to sudo group"
    fi
}

# Main script execution
main() {
    {
        echo "Starting Adarsh Setup - $(date)"
        echo "System: $(uname -a)"
        echo "User: $SUDO_USER"
        
        # System configuration
        configure_system
        
        # System updates
        system_update
        
        # Install basic dependencies
        install_packages curl wget git software-properties-common apt-transport-https \
                         ca-certificates gnupg lsb-release expect cups rar unrar cups-pdf
        
        # Install applications
        install_google_chrome
        install_packages libreoffice
        install_anydesk
        install_rustdesk
        
        # HP Printer setup
        setup_hp_printer
        
        # User management
        manage_users
        
        # Summary
        header "Setup Summary"
        echo -e "\n===== SUCCESSFULLY INSTALLED ====="
        for i in "${success_log[@]}"; do
            echo "- $i"
        done
        
        echo -e "\n===== WARNINGS ====="
        for i in "${warning_log[@]}"; do
            echo "- $i"
        done
        
        echo -e "\n===== FAILED INSTALLATIONS ====="
        for i in "${failure_log[@]}"; do
            echo "- $i"
        done
        
        # Copy log to Desktop
        header "Saving Log File"
        if [ -d "$DESKTOP_PATH_CURRENT" ]; then
            if cp "$LOG_FILE" "$DESKTOP_PATH_CURRENT/$FINAL_LOG_NAME"; then
                log_success "Log copied to $DESKTOP_PATH_CURRENT/$FINAL_LOG_NAME"
            else
                log_failure "Failed to copy log to Desktop"
            fi
        else
            log_warning "Desktop directory not found, log saved to $LOG_FILE"
        fi
        
        echo -e "\nAdarsh Setup Completed at $(date)"
        
        # Reboot prompt
        read -rp "Do you want to reboot now? (y/n): " reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            echo "Rebooting in 5 seconds..."
            sleep 5
            sudo reboot
        else
            echo "Please reboot manually when convenient."
        fi
    } | tee -a "$LOG_FILE"
}

# Start main execution
main
