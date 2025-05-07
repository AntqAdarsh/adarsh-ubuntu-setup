#!/bin/bash

set -e

echo "Checking for HP Plugin..."

if ! hp-plugin -i --required | grep -q 'Installed'; then
  echo "Installing HP plugin..."
  yes | hp-plugin -i --required --force || {
    echo "HP plugin installation failed."
    exit 1
  }
else
  echo "HP plugin already installed."
fi

echo "Detecting HP USB printer..."
HP_USB=$(lsusb | grep -i hp)

if [ -n "$HP_USB" ]; then
  echo "HP USB printer found."
else
  echo "No HP printer detected via USB. Aborting."
  exit 1
fi

echo "Running hp-setup..."
hp-setup -i -x --auto || {
  echo "hp-setup failed."
  exit 1
}
echo "HP Printer setup complete."

echo "Locating printer ID..."
PRINTER_ID=$(lpstat -p | grep hp | awk '{print $2}' | head -n1)

if [ -z "$PRINTER_ID" ]; then
  echo "Failed to detect configured HP printer ID."
  exit 1
fi

echo "Using printer: $PRINTER_ID"

TEST_PAGE="/usr/share/cups/data/testprint"
if [ ! -f "$TEST_PAGE" ]; then
  echo "Ubuntu test page not found at $TEST_PAGE"
  exit 1
fi

echo "Sending test page to printer..."
lp -d "$PRINTER_ID" "$TEST_PAGE" || {
  echo "Failed to print test page to $PRINTER_ID"
  exit 1
}

echo "Test page sent successfully to $PRINTER_ID"
