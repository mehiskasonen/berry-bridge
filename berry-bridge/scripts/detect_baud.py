#!/usr/bin/env python3

import serial
import time
import sys

def test_baud_rate(port, baud_rate, timeout=2):
    """Test a specific baud rate"""
    try:
        ser = serial.Serial(
          port=port,
          baudrate=baud_rate,
          bytesize=serial.EIGHTBITS,
          parity=serial.PARITY_NONE,
          stopbits=serial.STOPBITS_ONE,
          timeout=timeout
        )

        ser.reset_input_buffer()
        ser.reset_output_buffer()
        time.sleep(0.2)

        responses = []
        commands = [b'\r\n', b'\r', b'\n', b'?\r\n', b'help\r\n', b' ']

        for cmd in commands:
          ser.write(cmd)
          time.sleep(0.5)
          if ser.in_waiting > 0:
            response = ser.read(ser.in_waiting)
            responses.append(response)

        ser.close()
        for response in responses:
          if is_valid_response(response):
            return True, response
 
        return False, None
    except Exception as e:
      print(f"Error testing {baud_rate}: {e}", file=sys.stderr)
      return False, None

def is_valid_response(data):
    """Checks if data looks like valid text"""
    if len(data) < 3:
      return False

    printable_count = 0
    for byte in data:
      if (32 <= byte <= 126) or byte in [9, 10, 13]:
        printable_count += 1
    ratio = printable_count / len(data)

    if ratio < 0.8:
      return False

    text = data.decode('ascii', errors='ignore')
    device_indicators = ['>', '#', 'Switch', 'Router', 'Cisco', 'login']

    for indicator in device_indicators:
      if indicator in text:
        return True

    return ratio > 0.9 and len(data) >= 3

def auto_detect_baud(port):
    """Try multiple baud rates to find the correct one"""
    common_bauds = [9600, 115200, 19200, 38400, 57600, 4800, 2400, 1200]

    print(f"Testing baud rates on {port}...", file=sys.stderr)

    for baud in common_bauds:
      print(f"Trying {baud}...", file=sys.stderr, end=' ', flush=True)
      success, response = test_baud_rate(port, baud)
      if success:
        print(f"Success!", file=sys.stderr)
        print(baud)
        return baud
      else:
        print("no response", file=sys.stderr)

    print("No valid baud rate found", file=sys.stderr)
    return None

if __name__ == "__main__":
    if len(sys.argv) > 1:
      port = sys.argv[1]
    else:
      print("Usage: detect_baud.py <serial_port>", file=sys.stderr)
      sys.exit(1)

    detected_baud = auto_detect_baud(port)
    if not detected_baud:
      sys.exit(1)
