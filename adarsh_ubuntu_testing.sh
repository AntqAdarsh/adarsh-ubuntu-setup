# Print Test Page for USB HP Printer
header "Printing Test Page for HP USB Printer"

# Find USB-connected HP printer name
USB_PRINTER=$(lpstat -v | awk '/usb/ {gsub(/:$/, "", $3); print $3}')

if [ -n "$USB_PRINTER" ]; then
  # Use hp-testpage silently with detected printer
  sudo -u "$SUDO_USER" hp-testpage -p "$USB_PRINTER" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    log_success "HP Test Page sent to $USB_PRINTER"
  else
    log_failure "Failed to print HP Test Page"
  fi
else
  log_failure "No USB-connected HP printer found"
fi
