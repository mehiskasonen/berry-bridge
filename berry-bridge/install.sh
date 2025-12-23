#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Installing rfcomm-shell.sh..."
sudo cp "$PROJECT_ROOT/scripts/rfcomm-shell.sh" /usr/local/sbin/rfcomm-shell.sh
sudo chmod +x /usr/local/sbin/rfcomm-shell.sh

echo "[*] Installing device-console.sh..."
sudo cp "$PROJECT_ROOT/scripts/device-console.sh" /usr/local/sbin/device-console.sh
sudo chmod +x /usr/local/sbin/device-console.sh

echo "[*] Installing detect_baud.py..."
sudo cp "$PROJECT_ROOT/scripts/detect_baud.py" /usr/local/sbin/detect_baud.py
sudo chmod +x /usr/local/sbin/detect_baud.py

echo "[*] Installing berry-bridge.service..."
sudo cp "$PROJECT_ROOT/services/berry-bridge.service" /etc/systemd/system/berry-bridge.service

echo "[*] Checking for PySerial..."
if ! python3 -c "import serial" 2>/dev/null; then
  echo "[*] PySerial not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y python3-serial
else
  echo "[*] PySerial already installed."
fi

echo "[*] Reloading system units..."
sudo systemctl daemon-reload

echo "[*] Enabling and starting bt-rfcomm-watcher.service..."
sudo systemctl enable --now bt-rfcomm-watcher.service

echo "[*] Done." 
echo "After login, run: device-console.sh"