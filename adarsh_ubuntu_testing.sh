#!/bin/bash

echo -e "\n===== Running HP Setup ====="

# Wait for USB printer detection
PRINTER_DETECTED=false
for i in {1..10}; do
  if lsusb | grep -i hp; then
    echo "HP USB Printer detected."
    PRINTER_DETECTED=true
    break
  fi
  sleep 5
  echo "Waiting for printer to be connected... ($i/10)"
done

if [ "$PRINTER_DETECTED" = true ]; then
  echo "Proceeding with HP Setup..."

  # Run hp-setup with non-interactive mode using expect (scripted interaction)
  sudo -u "$SUDO_USER" expect <<EOF
log_user 0
spawn hp-setup -i

expect {
  "*Found USB printers*" {
    send "1\r"
    exp_continue
  }
  eof
}
EOF

  if [ $? -eq 0 ]; then
    echo "HP Setup completed successfully."
  else
    echo "HP Setup failed."
  fi

  # Print Test Page after HP Setup
  echo "Sending test page to HP printer..."
  PRINTER_NAME=$(lpstat -v | awk '/usb/ && /HP/ {gsub(/:$/, "", $3); print $3}')
  
  if [ -n "$PRINTER_NAME" ]; then
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
    echo "HP printer not detected after setup."
  fi
else
  echo "No HP USB printer detected. Skipping HP Setup and Test Print."
fi
