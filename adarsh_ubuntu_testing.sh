#!/bin/bash

# ==============================================
# Adarsh Setup Script - Ubuntu 20.04-25.04+ Compatible
# ==============================================

# Configuration
readonly SCRIPT_PASSWORD="adarsh@123"  # Change in production
readonly LOG_FILE="/tmp/adarshsetup-$(date +%s).log"
readonly DESKTOP_LOG="$HOME/Desktop/adarshsetup-final.log"
readonly SUPPORTED_VERSIONS=("20.04" "22.04" "24.04" "25.04")

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

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
header() {
    echo -e "\n${BLUE}===== $1 =====${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
    SUCCESS_LOG+=("$1")
}

log_failure() {
    echo -e "${RED}[FAILED] $1${NC}" | tee -a "$LOG_FILE" >&2
    FAILURE_LOG+=("$1")
    return 1
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
    WARNING_LOG+=("$1")
}

# Improved version check
verify_ubuntu_version() {
    header "System Verification"
    
    local version_id
    version_id=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release)
    
    local supported=0
    for supported_version in "${SUPPORTED_VERSIONS[@]}"; do
        if [[ "$version_id" == "$supported_version" ]]; then
            supported=1
            break
        fi
    done

    if [[ $supported -eq 0 ]]; then
        log_warning "Untested Ubuntu version detected ($version_id)"
        log_warning "Officially supported versions: ${SUPPORTED_VERSIONS[*]}"
        read -rp "Continue anyway? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy] ]]; then
            log_failure "Unsupported Ubuntu version"
            return 1
        fi
    fi

    log_success "Ubuntu $version_id detected"
}

# Network check
verify_network() {
    if ! ping -c 1 google.com &>/dev/null; then
        log_failure "No internet connection detected"
        return 1
    fi
    log_success "Network connection verified"
}

# Package installation with retry
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

# Google Chrome installation
install_chrome() {
    header "Installing Google Chrome"
    
    if command -v google-chrome &>/dev/null; then
        log_success "Chrome already installed"
        return 0
    fi

    local deb_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    local deb_file="/tmp/google-chrome.deb"

    if wget -q --show-progress -O "$deb_file" "$deb_url"; then
        sudo dpkg -i "$deb_file" || sudo apt-get install -f -y
        if command -v google-chrome &>/dev/null; then
            log_success "Chrome installed successfully"
        else
            log_failure "Chrome installation failed"
        fi
    else
        log_failure "Failed to download Chrome"
    fi
}

# Main execution
main() {
    clear
    echo -e "${BLUE}Adarsh Setup Script - Starting...${NC}"
    
    # Verify system first
    verify_ubuntu_version || exit 1
    verify_network || exit 1
    
    # Password check
    echo
    read -rsp "Enter script password: " input_pass
    if [[ "$input_pass" != "$SCRIPT_PASSWORD" ]]; then
        log_failure "Incorrect password"
        exit 1
    fi
    echo -e "\n${GREEN}Authentication successful${NC}"

    # System updates
    header "Updating System"
    sudo apt-get update && sudo apt-get upgrade -y

    # Install core packages
    header "Installing Dependencies"
    install_pkg curl
    install_pkg wget
    install_pkg git
    install_pkg software-properties-common

    # Install applications
    install_chrome

    # Summary
    header "Setup Summary"
    echo -e "\n${GREEN}=== SUCCESS ==="
    printf "• %s\n" "${SUCCESS_LOG[@]}"
    
    echo -e "\n${YELLOW}=== WARNINGS ==="
    [[ ${#WARNING_LOG[@]} -eq 0 ]] && echo "None" || printf "• %s\n" "${WARNING_LOG[@]}"
    
    echo -e "\n${RED}=== FAILURES ==="
    [[ ${#FAILURE_LOG[@]} -eq 0 ]] && echo "None" || printf "• %s\n" "${FAILURE_LOG[@]}"

    # Save log
    cp "$LOG_FILE" "$DESKTOP_LOG" 2>/dev/null && 
        echo -e "\nLog saved to ${BLUE}$DESKTOP_LOG${NC}"

    echo -e "\n${BLUE}Setup completed at $(date)${NC}"
}

main
