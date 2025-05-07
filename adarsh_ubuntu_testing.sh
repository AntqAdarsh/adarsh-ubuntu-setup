#!/bin/bash

# Detect the first HP USB printer installed
PRINTER_NAME=$(lpstat -e | grep -i hp | head -n1)

if [ -z "$PRINTER_NAME" ]; then
  echo "Failed: No HP USB printer found. Ensure it's connected and installed."
  exit 1
fi

# Print the default Ubuntu test page (standard system test file)
TEST_PAGE="/usr/share/cups/data/testprint"
if [ ! -f "$TEST_PAGE" ]; then
  echo "Failed: Default Ubuntu test page not found at $TEST_PAGE"
  exit 1
fi

# Send test page to detected printer
lp -d "$PRINTER_NAME" "$TEST_PAGE"
if [ $? -eq 0 ]; then
  echo "Success: Test page sent to printer '$PRINTER_NAME'"
else
  echo "Failed: Unable to print test page to printer '$PRINTER_NAME'"
  exit 1
fi
