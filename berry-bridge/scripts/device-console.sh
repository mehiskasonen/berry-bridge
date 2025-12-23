#!/usr/bin/env bash
set -euo pipefail

BT_DEV="/dev/rfcomm0"
NETWORK_DEV="/dev/ttyUSB0"
DEFAULT_BAUD="9600"
DETECT_SCRIPT="/usr/local/sbin/detect_baud.py"

BAUD_CANDIDATES=(115200 9600 19200 38400 57600)


echo "Bluetooth console bridge helper"
echo "-------------------------------"

if [[ ! -e "$NETWORK_DEV" ]]; then
  echo "Error: $NETWORK_DEV not found. Is the USB console cable plugged into Raspberry Pi?"
  exit 1
fi

echo "Using Bluetooth device: $BT_DEV"
echo "Using network device: $NETWORK_DEV"
echo "Baud candidates: ${BAUD_CANDIDATES[*]}"
echo
echo "Baud Rate Detection Options:"
echo " 1) Auto-detect baud rate (Python script)"
echo " 2) Manual scan (try each rate interactively)"
echo " 3) Use default ($DEFAULT_BAUD)"
echo ""

read -rp "Select option [1-3]: " option

case "$option" in
  1)
    echo "Running baud rate detection..."
    if [[ ! -f "$DETECT_SCRIPT" ]]; then
      echo "Error: Detection script not found at $DETECT_SCRIPT"
      echo "Falling back to manual scan..."
      option=2
    else
      DETECTED_BAUD=$(python3 "$DETECT_SCRIPT" "$NETWORK_DEV" 2>&1 | tee /dev/stderr | grep -E "^[0-9]+$" || true)

      if [[ -n "$DETECTED_BAUD" ]]; then
        echo ""
        echo "Detected baud rate: $DETECTED_BAUD"
        BAUD_RATE="$DETECTED_BAUD"

        echo "Starting bridge with detected baud rate..."
        exec sudo socat -d -d \
          FILE:"$BT_DEV",raw,echo=0,b115200 \
          FILE:"$NETWORK_DEV",raw,echo=0,b"$BAUD_RATE"
      else
        echo ""
        echo "x Auto-detection failed. Falling back to manual scan..."
        option=2
      fi
    fi
    ;&

  2)
    echo "Manual baud rate scan mode"

    for baud in "${BAUD_CANDIDATES[@]}"; do
      echo ""
      echo "Trying baud rate: $baud"
      echo "Press Ctrl+C to stop, or it will prompt after connection ends"

      timeout 15 socat -d -d \
        FILE:"$BT_DEV",raw,echo=0,b115200 \
        FILE:"$NETWORK_DEV",raw,echo=0,b"$baud" || true

      echo ""
      echo "Test completed for baud rate: $baud"
      read -rp "Was this the correct baud rate? [y/N]: " ans
      ans=${ans:-N}

      case "$ans" in
        [Yy]*) 
          echo "Connecting with baud rate: $baud"
          exec socat \
            FILE:"$BT_DEV",raw,echo=0,b115200 \
            FILE:"NETWORK_DEV",raw,echo=0,b"$baud"
          ;;
        *)
          read -rp "Try next baud rate? [Y/n]: " continue
          continue=${continue:-Y}
          case "$continue" in
            [Nn]*)
              echo "Stopping baud search."
              exit 0
              ;;
            *)
              echo "Continuing to next baud..."
              ;;
          esac
          ;;
      esac
    done
    echo "No more baud candidates left"
    exit 0
    ;;

  3|*)
    echo "Using default baud rate: $DEFAULT_BAUD"
    BAUD_RATE="$DEFAULT_BAUD"
    echo "Starting bridge"
    exec sudo socat -d -d \
      FILE:"$BT_DEV",raw,echo=0,b115200 \
      FILE:"$NETWORK_DEV",raw,echo=0,b"$BAUD_RATE"
    ;;
esac