#!/bin/bash

# ==============================================
# Adarsh Setup Script - Final Debugged Version
# ==============================================

# Configuration
readonly SCRIPT_PASSWORD="adarsh@123"  # Change this in production
readonly LOG_FILE="/tmp/adarshsetup-$(date +%s).log"
readonly DESKTOP_LOG="$HOME/Desktop/adarshsetup-final.log"

# Initialize logs
declare -a SUCCESS_LOG=()
declare -a FAILURE_LOG=()
declare -a WARNING_LOG=()

# Cleanup function
cleanup() {
    echo -e "\nCleaning up temporary files..."
    rm -f /tmp/google-chrome.deb /tmp/rustdesk.deb
    exit
}
trap cleanup EXIT INT TERM

# Logging functions
header() {
    echo -e "\n\e[1;34m===== $1 =====\e[0m" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "\e[1;32m[SUCCESS] $1\e[0m" | tee -a "$LOG_FILE"
    SUCCESS_LOG+=("$1")
}

log_failure() {
    echo -e "\e[1;31m[FAILED] $1\e[0m" | tee -a "$LOG_FILE" >&2
    FAILURE_LOG+=("$1")
    return 1
}

log_warning() {
    echo -e "\e[1;33m[WARNING] $1\e[0m" | tee -a "$LOG_FILE"
    WARNING_LOG+=("$1")
}

# Password check
check_password() {
    read -rsp "Enter script password: " input_pass
    echo
    [[ "$input_pass" == "$SCRIPT_PASSWORD" ]] || {
        log_failure "Incorrect password"
        return 1
    }
}

# System checks
verify_system() {
    header "System Verification"
    
    # Check OS (Ubuntu 20.04/22.04)
    if ! grep -Ei "Ubuntu (20.04|22.04)" /etc/os-release &>/dev/null; then
        log_failure "Only Ubuntu 20.04/22.04 supported"
        return 1
    fi

    # Check internet
    if ! ping -c 1 google.com &>/dev/null; then
        log_failure "No internet connection"
        return 1
    fi
}

# Install package with retry
install_pkg() {
    local pkg=$1 max_retries=3 attempt=1

    while (( attempt <= max_retries )); do
        if sudo apt-get install -y "$pkg"; then
            log_success "Installed $pkg"
            return 0
        else
            log_warning "Attempt $attempt/$max_retries failed for $pkg"
            ((attempt++))
            sleep 2
        fi
    done
    log_failure "Failed to install $pkg after $max_retries attempts"
    return 1
}

# Main installation functions
install_chrome() {
    header "Installing Google Chrome"
    local deb_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    local deb_file="/tmp/google-chrome.deb"

    if wget -q --show-progress -O "$deb_file" "$deb_url"; then
        sudo dpkg -i "$deb_file" || sudo apt-get install -f -y
        log_success "Chrome installed"
    else
        log_failure "Failed to download Chrome"
    fi
}

setup_printer() {
    header "Printer Setup"
    install_pkg hplip || return 1
    
    echo "Connect HP printer now (waiting 20 seconds)..."
    local detected=false
    for i in {1..20}; do
        if lsusb | grep -i hp; then
            detected=true
            break
        fi
        sleep 1
    done

    if $detected; then
        log_success "Printer detected"
    else
        log_failure "No HP printer found"
    fi
}

# Main execution
main() {
    clear
    echo -e "\e[1;36mAdarsh Setup Script - Starting...\e[0m"
    
    # Verify system first
    verify_system || exit 1
    
    # Password check
    check_password || exit 1

    # System updates
    header "Updating System"
    sudo apt-get update && sudo apt-get upgrade -y

    # Install core packages
    header "Installing Dependencies"
    install_pkg curl
    install_pkg wget
    install_pkg git

    # Install apps
    install_chrome
    setup_printer

    # Summary
    header "Setup Summary"
    echo -e "\n\e[1;32m=== SUCCESS ===\e[0m"
    printf "• %s\n" "${SUCCESS_LOG[@]}"
    
    echo -e "\n\e[1;33m=== WARNINGS ===\e[0m"
    [[ ${#WARNING_LOG[@]} -eq 0 ]] && echo "None" || printf "• %s\n" "${WARNING_LOG[@]}"
    
    echo -e "\n\e[1;31m=== FAILURES ===\e[0m"
    [[ ${#FAILURE_LOG[@]} -eq 0 ]] && echo "None" || printf "• %s\n" "${FAILURE_LOG[@]}"

    # Save log
    cp "$LOG_FILE" "$DESKTOP_LOG" 2>/dev/null && 
        echo -e "\nLog saved to \e[1;34m$DESKTOP_LOG\e[0m"

    echo -e "\n\e[1;35mSetup completed at $(date)\e[0m"
}

main
