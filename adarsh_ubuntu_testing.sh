#!/bin/bash

echo -e "\n===== Sending Ubuntu Test Page to USB-connected HP Printer ====="

# Get USB-connected HP printer name
PRINTER_NAME=$(lpstat -v | awk '/usb/ && /HP/ {gsub(/:$/, "", $3); print $3}')

if [ -n "$PRINTER_NAME" ]; then
  echo "Detected HP USB Printer: $PRINTER_NAME"

  # Use built-in Ubuntu test page located in CUPS example directory
  TEST_PAGE="/usr/share/cups/data/testprint"

  if [ -f "$TEST_PAGE" ]; then
    lp -d "$PRINTER_NAME" "$TEST_PAGE"
    if [ $? -eq 0 ]; then
      echo "Test print sent successfully to $PRINTER_NAME"
    else
      echo "Failed to send test page to $PRINTER_NAME"
    fi
  else
    echo "Test page file not found at $TEST_PAGE"
  fi
else
  echo "No USB-connected HP printer found"
fi
