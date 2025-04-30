#!/bin/bash

# ==============================================
# Adarsh Setup Script - Final Perfect Version
# ==============================================

# Constants and Configuration
readonly SCRIPT_PASSWORD="adarsh@123"  # In production, use hashed passwords or better auth
readonly MAX_PASSWORD_ATTEMPTS=3
readonly LOG_DIR="/var/log/adarshsetup"
readonly LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
readonly FINAL_LOG_NAME="adarshsetup-log-$(date +%Y%m%d-%H%M%S).txt"
readonly DESKTOP_PATH="${HOME}/Desktop"

# System Requirements
readonly MIN_DISK_SPACE_GB=5
readonly MIN_MEMORY_MB=1024
readonly REQUIRED_OS="Ubuntu 20.04|Ubuntu 22.04"

# Application Versions
readonly CHROME_VERSION="stable"
readonly RUSTDESK_VERSION="1.2.6"
readonly ANYDESK_VERSION="latest"

# Initialize logging
declare -a success_log=()
declare -a failure_log=()
declare -a warning_log=()

# Cleanup on exit handler
cleanup() {
    local exit_code=$?
    echo -e "\nCleaning up before exit..."
    
    # Remove temporary files
    rm -f /tmp/google-chrome.deb /tmp/rustdesk.deb
    
    # Final status message
    if [ $exit_code -eq 0 ]; then
        echo "Script completed successfully"
    else
        echo "Script exited with errors (code: $exit_code)"
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM

# ==============================================
# Core Functions
# ==============================================

# Initialize logging system
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
}

# Print formatted header
header() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') ===== $1 ====="
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') ===== $1 =====" >> "$LOG_FILE"
}

# Log success message
log_success() {
    local message="[SUCCESS] $1"
    echo "$message"
    success_log+=("$1")
}

# Log failure message
log_failure() {
    local message="[FAILED] $1"
    echo "$message" >&2
    failure_log+=("$1")
    return 1
}

# Log warning message
log_warning() {
    local message="[WARNING] $1"
    echo "$message"
    warning_log+=("$1")
}

# Check command availability
check_command() {
    command -v "$1" &>/dev/null
}

# Verify system requirements
verify_system() {
    header "System Verification"
    
    # Check OS compatibility
    if ! grep -Eiq "$REQUIRED_OS" /etc/os-release; then
        log_failure "Unsupported OS. Required: $REQUIRED_OS"
        return 1
    fi
    
    # Check disk space
    local disk_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$disk_space" -lt $MIN_DISK_SPACE_GB ]; then
        log_failure "Insufficient disk space. Required: ${MIN_DISK_SPACE_GB}GB, Available: ${disk_space}GB"
        return 1
    fi
    
    # Check memory
    local memory=$(free -m | awk '/Mem:/ {print $2}')
    if [ "$memory" -lt $MIN_MEMORY_MB ]; then
        log_warning "Low memory. Recommended: ${MIN_MEMORY_MB}MB, Available: ${memory}MB"
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com &>/dev/null; then
        log_failure "No internet connection detected"
        return 1
    fi
    
    log_success "System meets all requirements"
}

# Authenticate user
authenticate() {
    header "Authentication"
    local attempt=1
    
    while (( attempt <= MAX_PASSWORD_ATTEMPTS )); do
        read -rsp "[Attempt $attempt/$MAX_PASSWORD_ATTEMPTS] Enter script password: " input_pass
        echo
        
        if [ "$input_pass" = "$SCRIPT_PASSWORD" ]; then
            log_success "Authentication successful"
            return 0
        else
            echo "Incorrect password. Try again..."
            ((attempt++))
        fi
    done
    
    log_failure "Maximum password attempts reached"
    return 1
}

# Update system packages
system_update() {
    header "System Update"
    
    local max_retries=3
    local retry_count=0
    local update_success=false
    
    # Clean package cache
    if ! sudo apt-get clean; then
        log_failure "Failed to clean package cache"
        return 1
    fi
    
    # Update package lists with retry
    while (( retry_count < max_retries )); do
        if sudo apt-get update --fix-missing; then
            update_success=true
            break
        else
            ((retry_count++))
            log_warning "Update failed (attempt $retry_count/$max_retries), retrying..."
            sleep 5
        fi
    done
    
    if ! $update_success; then
        log_failure "Failed to update package list after $max_retries attempts"
        return 1
    fi
    
    # Upgrade packages
    if ! sudo apt-get upgrade -y; then
        log_failure "Failed to upgrade packages"
        return 1
    fi
    
    # Dist-upgrade
    if ! sudo apt-get dist-upgrade -y; then
        log_failure "Failed to upgrade distribution packages"
        return 1
    fi
    
    # Clean up
    if ! sudo apt-get autoremove -y; then
        log_warning "Failed to remove unnecessary packages"
    fi
    
    log_success "System updated successfully"
}

# Install package with error handling
install_package() {
    local pkg=$1
    local description=${2:-$pkg}
    
    if sudo apt-get install -y "$pkg"; then
        log_success "Installed $description"
        return 0
    else
        log_failure "Failed to install $description"
        return 1
    fi
}

# Install multiple packages
install_packages() {
    local packages=("$@")
    header "Installing Packages: ${packages[*]}"
    
    for pkg in "${packages[@]}"; do
        install_package "$pkg"
    done
}

# Pin application to dock
pin_to_dock() {
    local app=$1
    local max_attempts=3
    local attempt=1
    local desktop_file
    
    # Find .desktop file with retry
    while (( attempt <= max_attempts )); do
        desktop_file=$(find /usr/share/applications/ ~/.local/share/applications/ -name "$app.desktop" 2>/dev/null | head -n 1)
        
        if [ -n "$desktop_file" ]; then
            break
        else
            ((attempt++))
            sleep 1
        fi
    done
    
    if [ -z "$desktop_file" ]; then
        log_warning "$app.desktop file not found after $max_attempts attempts"
        return 1
    fi
    
    # Get current favorites
    local current_favorites=$(gsettings get org.gnome.shell favorite-apps | tr -d '[]' | tr -d ' ')
    
    # Check if already pinned
    if [[ "$current_favorites" == *"$app.desktop"* ]]; then
        log_success "$app is already pinned to Dock"
        return 0
    fi
    
    # Add to favorites
    local new_favorites="${current_favorites},'$app.desktop'"
    new_favorites=$(echo "$new_favorites" | sed "s/,,/,/g" | sed "s/^,//")
    new_favorites="[${new_favorites}]"
    
    if gsettings set org.gnome.shell favorite-apps "$new_favorites"; then
        log_success "$app pinned to Dock"
        return 0
    else
        log_failure "Failed to pin $app to Dock"
        return 1
    fi
}

# ==============================================
# Application Installation Functions
# ==============================================

install_google_chrome() {
    header "Installing Google Chrome"
    
    local chrome_url="https://dl.google.com/linux/direct/google-chrome-${CHROME_VERSION}_current_amd64.deb"
    local chrome_deb="/tmp/google-chrome.deb"
    
    # Download Chrome
    if ! wget -q --show-progress -O "$chrome_deb" "$chrome_url"; then
        log_failure "Failed to download Google Chrome"
        return 1
    fi
    
    # Install Chrome
    if ! sudo dpkg -i "$chrome_deb"; then
        sudo apt-get install -f -y
        if ! check_command google-chrome; then
            log_failure "Google Chrome installation failed"
            return 1
        fi
    fi
    
    log_success "Google Chrome installed"
    pin_to_dock "google-chrome"
}

install_libreoffice() {
    header "Installing LibreOffice"
    install_package libreoffice "LibreOffice"
}

install_anydesk() {
    header "Installing AnyDesk"
    
    # Import GPG key
    if ! wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /usr/share/keyrings/anydesk.gpg; then
        log_failure "Failed to import AnyDesk GPG key"
        return 1
    fi
    
    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk.list
    
    # Install AnyDesk
    if sudo apt-get update && sudo apt-get install -y anydesk; then
        log_success "AnyDesk installed"
        pin_to_dock "anydesk"
    else
        log_failure "AnyDesk installation failed"
    fi
}

install_rustdesk() {
    header "Installing RustDesk"
    
    local rustdesk_url="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"
    local rustdesk_deb="/tmp/rustdesk.deb"
    
    # Download RustDesk
    if ! wget -q --show-progress -O "$rustdesk_deb" "$rustdesk_url"; then
        log_failure "Failed to download RustDesk"
        return 1
    fi
    
    # Install RustDesk
    if sudo apt install -fy "$rustdesk_deb"; then
        log_success "RustDesk installed"
        pin_to_dock "rustdesk"
    else
        log_failure "RustDesk installation failed"
    fi
}

setup_hp_printer() {
    header "HP Printer Setup"
    
    # Install HPLIP
    install_packages hplip hplip-gui
    
    # Install HP Plugin
    header "Installing HP Plugin"
    if ! command -v expect &>/dev/null; then
        log_failure "Expect not installed, cannot setup HP Plugin"
        return 1
    fi
    
    if ! sudo -u "$(logname)" expect <<EOF
set timeout 300
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
    
    log_success "HP Plugin installed"
    
    # Detect HP Printer
    header "Printer Detection"
    echo "Please connect the USB printer..."
    
    local max_attempts=20
    local attempt=1
    local printer_detected=false
    
    while (( attempt <= max_attempts )); do
        if lsusb | grep -i "HP\|Hewlett-Packard"; then
            printer_detected=true
            echo "HP USB Printer detected."
            break
        fi
        echo "Waiting for printer... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    if ! $printer_detected; then
        log_failure "No HP printer detected after $max_attempts attempts"
        return 1
    fi
    
    # Run HP Setup
    header "Running HP Setup"
    if ! sudo -u "$(logname)" expect <<EOF
set timeout 600
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
    
    log_success "HP Setup completed"
}

manage_depo_user() {
    header "Managing Depo User"
    
    local username="Depo"
    local password="depo"
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        log_warning "User $username already exists"
    else
        # Create user
        if ! sudo useradd -m -s /bin/bash "$username"; then
            log_failure "Failed to create user $username"
            return 1
        fi
        log_success "User $username created"
    fi
    
    # Set password
    if ! echo "$username:$password" | sudo chpasswd; then
        log_failure "Failed to set password for $username"
        return 1
    fi
    log_success "Password set for $username"
    
    # Add to sudo group
    if ! sudo usermod -aG sudo "$username"; then
        log_failure "Failed to add $username to sudo group"
        return 1
    fi
    log_success "User $username added to sudo group"
    
    # Configure passwordless sudo
    echo "$username ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/depo-nopasswd >/dev/null
    sudo chmod 440 /etc/sudoers.d/depo-nopasswd
    log_success "Configured passwordless sudo for $username"
}

# ==============================================
# Main Script Execution
# ==============================================

main() {
    # Initialize
    init_logging
    header "Starting Adarsh Setup"
    echo "System: $(uname -a)"
    echo "User: $(whoami)"
    echo "Date: $(date)"
    echo "Log file: $LOG_FILE"
    
    # Verify system
    if ! verify_system; then
        log_failure "System verification failed"
        exit 1
    fi
    
    # Authenticate
    if ! authenticate; then
        exit 1
    fi
    
    # Disable sleep
    header "Disabling Sleep Settings"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    gsettings set org.gnome.desktop.session idle-delay 0
    log_success "Sleep settings disabled"
    
    # System updates
    system_update
    
    # Install basic dependencies
    install_packages curl wget git software-properties-common \
                    apt-transport-https ca-certificates gnupg \
                    lsb-release expect cups rar unrar cups-pdf
    
    # Install applications
    install_google_chrome
    install_libreoffice
    install_anydesk
    install_rustdesk
    
    # Printer setup
    setup_hp_printer
    
    # User management
    manage_depo_user
    
    # Final summary
    header "Setup Summary"
    echo -e "\n===== SUCCESSFUL OPERATIONS ====="
    printf -- "- %s\n" "${success_log[@]}"
    
    echo -e "\n===== WARNINGS ====="
    if [ ${#warning_log[@]} -eq 0 ]; then
        echo "- None"
    else
        printf -- "- %s\n" "${warning_log[@]}"
    fi
    
    echo -e "\n===== FAILED OPERATIONS ====="
    if [ ${#failure_log[@]} -eq 0 ]; then
        echo "- None"
    else
        printf -- "- %s\n" "${failure_log[@]}"
    fi
    
    # Save log to desktop
    header "Saving Log File"
    if [ -d "$DESKTOP_PATH" ]; then
        if cp "$LOG_FILE" "${DESKTOP_PATH}/${FINAL_LOG_NAME}"; then
            log_success "Log saved to ${DESKTOP_PATH}/${FINAL_LOG_NAME}"
        else
            log_warning "Failed to copy log to Desktop"
        fi
    else
        log_warning "Desktop directory not found, log remains at $LOG_FILE"
    fi
    
    # Final message
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') Adarsh Setup Completed"
    
    # Reboot prompt
   
        echo "Rebooting in 10 seconds..."
        sleep 10
        sudo reboot
    
}

# Start execution
main
