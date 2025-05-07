#!/bin/bash

echo "Checking HP Plugin..."
if ! hp-plugin -i --required | grep -q 'Installed'; then
  echo "Installing HP plugin..."
  yes | hp-plugin -i --required --force
fi

echo "Detecting HP USB printer..."
if lsusb | grep -i hp; then
  echo "HP Printer found. Running hp-setup..."
  hp-setup -i -x --auto 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "HP Printer setup complete."
  else
    echo "hp-setup failed."
    exit 1
  fi
else
  echo "No HP printer detected via USB."
  exit 1
fi

echo "Printing test page..."
PRINTER_ID=$(lpstat -v | grep hp | awk '{print $3}' | sed 's/:$//')
TEST_PAGE="/usr/share/cups/data/testprint"

if [ -f "$TEST_PAGE" ] && [ -n "$PRINTER_ID" ]; then
  lp -d "$PRINTER_ID" "$TEST_PAGE"
  if [ $? -eq 0 ]; then
    echo "Test page sent successfully to $PRINTER_ID"
  else
    echo "Test page failed to print."
  fi
else
  echo "Test page file or printer ID missing."
fi
