#!/bin/bash

echo -e "\n===== Sending Test Page to USB-connected HP Printer ====="

# Detect USB-connected HP printer
USB_PRINTER=$(lpstat -v | awk '/usb/ && /HP/ {gsub(/:$/, "", $3); print $3}')

if [ -n "$USB_PRINTER" ]; then
  echo "Detected HP USB Printer: $USB_PRINTER"
  if hp-testpage -p "$USB_PRINTER" >/dev/null 2>&1; then
    echo "Test print sent successfully to $USB_PRINTER"
  else
    echo "Failed to send test page to $USB_PRINTER (hp-testpage command failed)"
  fi
else
  echo "No USB-connected HP printer found"
fi
