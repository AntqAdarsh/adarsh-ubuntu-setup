#!/bin/bash

# ==============================================
# Adarsh Setup Script - Debugged Version
# ==============================================

# Configuration
readonly SCRIPT_PASSWORD="adarsh@123"
readonly LOG_FILE="/tmp/adarshsetup-$(date +%s).log"
readonly DESKTOP_LOG="$HOME/Desktop/adarshsetup-final.log"
readonly SUPPORTED_VERSIONS=("20.04" "22.04" "24.04")

# Initialize logs
declare -a SUCCESS_LOG=()
declare -a FAILURE_LOG=()
declare -a WARNING_LOG=()

# Enhanced cleanup
cleanup() {
    echo -e "\nCleaning up temporary files..."
    rm -f /tmp/google-chrome.deb /tmp/rustdesk.deb
    
    # Final status
    if [ ${#FAILURE_LOG[@]} -eq 0 ]; then
        echo -e "\n${GREEN}Script completed successfully${NC}"
    else
        echo -e "\n${RED}Script completed with ${#FAILURE_LOG[@]} error(s)${NC}"
    fi
    
    exit
}
trap cleanup EXIT INT TERM

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Improved logging
header() {
    echo -e "\n${BLUE}===== $1 =====${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
    SUCCESS_LOG+=("$1")
}

log_failure() {
    echo -e "${RED}[FAILED] $1 (Exit Code: $?)${NC}" | tee -a "$LOG_FILE" >&2
    FAILURE_LOG+=("$1")
    return 1
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
    WARNING_LOG+=("$1")
}

# Version check with better error handling
verify_system() {
    header "System Verification"
    
    if ! lsb_release -i | grep -q Ubuntu; then
        log_failure "Only Ubuntu systems are supported"
        return 1
    fi

    local version_id=$(lsb_release -rs)
    local supported=0
    
    for v in "${SUPPORTED_VERSIONS[@]}"; do
        if [ "$version_id" == "$v" ]; then
            supported=1
            break
        fi
    done

    if [ $supported -eq 0 ]; then
        log_warning "Untested Ubuntu version ($version_id)"
        read -rp "Continue anyway? [y/N] " choice
        if [[ ! "$choice" =~ ^[Yy] ]]; then
            log_failure "User aborted due to unsupported version"
            return 1
        fi
    fi

    log_success "Ubuntu $version_id detected"
}

# Network check with timeout
verify_network() {
    if ! timeout 5 ping -c 1 google.com &>/dev/null; then
        log_failure "No internet connection detected"
        return 1
    fi
    log_success "Network connection verified"
}

# Robust package installation
install_pkg() {
    local pkg=$1
    header "Installing $pkg"
    
    if dpkg -l | grep -q "^ii  $pkg "; then
        log_success "$pkg already installed"
        return 0
    fi

    local max_retries=3
    local attempt=1
    
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

# Chrome installation with proper error tracking
install_chrome() {
    header "Installing Google Chrome"
    
    if command -v google-chrome &>/dev/null; then
        log_success "Chrome already installed"
        return 0
    fi

    local deb_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    local deb_file="/tmp/google-chrome.deb"

    if ! wget -q --show-progress -O "$deb_file" "$deb_url"; then
        log_failure "Failed to download Chrome"
        return 1
    fi

    if ! sudo dpkg -i "$deb_file"; then
        if ! sudo apt-get install -f -y; then
            log_failure "Failed to resolve Chrome dependencies"
            return 1
        fi
    fi

    if command -v google-chrome &>/dev/null; then
        log_success "Chrome installed successfully"
    else
        log_failure "Chrome installation completed but binary not found"
    fi
}

# Main execution flow
main() {
    clear
    echo -e "${BLUE}Adarsh Setup Script - Starting...${NC}"
    echo -e "Log file: ${BLUE}$LOG_FILE${NC}"
    
    # System checks
    verify_system || exit 1
    verify_network || exit 1
    
    # Authentication
    echo
    read -rsp "Enter script password: " input_pass
    if [[ "$input_pass" != "$SCRIPT_PASSWORD" ]]; then
        log_failure "Incorrect password"
        exit 1
    fi
    echo -e "\n${GREEN}Authentication successful${NC}"

    # System updates
    header "System Update"
    sudo apt-get update && sudo apt-get upgrade -y || {
        log_failure "System update failed"
        exit 1
    }

    # Installations
    install_pkg curl
    install_pkg wget
    install_pkg git
    install_chrome

    # Final report
    header "Setup Summary"
    echo -e "\n${GREEN}=== SUCCESSFUL OPERATIONS (${#SUCCESS_LOG[@]}) ==="
    printf "• %s\n" "${SUCCESS_LOG[@]:-None}"
    
    echo -e "\n${YELLOW}=== WARNINGS (${#WARNING_LOG[@]}) ==="
    printf "• %s\n" "${WARNING_LOG[@]:-None}"
    
    echo -e "\n${RED}=== FAILURES (${#FAILURE_LOG[@]}) ==="
    printf "• %s\n" "${FAILURE_LOG[@]:-None}"

    # Save log
    if cp "$LOG_FILE" "$DESKTOP_LOG" 2>/dev/null; then
        echo -e "\n${GREEN}Log saved to ${BLUE}$DESKTOP_LOG${NC}"
    else
        log_warning "Could not save log to desktop (saved to $LOG_FILE)"
    fi
}

main
