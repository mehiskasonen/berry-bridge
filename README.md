# **Berry-Bridge** a Raspberry Pi Bluetooth Serial Bridge

This project turns a Raspberry Pi (5) into a **Bluetooth Serial (RFCOMM) bridge**.

After pairing over Bluetooth, a remote laptop can connect to the Pi using a serial terminal (`screen`, PuTTY, etc.).  

The Pi then bridges that Bluetooth connection to a physical serial device (for example, a network switch console on `/dev/ttyUSB0`).


## Getting ready

Make sure your raspberry is connected to a wifi.
Install necessary dependancies manually (terminal):

```bash
sudo apt update
sudo apt install bluetooth bluez socat python3-serial rfcomm
```

Add the Serial Port Profile (SPP) to raspberry's SDP (Service Discovery Protocol):

```bash
sudo sdptool add --channel=1 SP
```

ou need to run it before the client (your laptop) attempts to connect, so the serial port service is advertised. Without it, your laptop won’t "see" the Raspberry Pi as a serial-capable device. Verify with:

```bash
sudo sdptool browse local
```

You should see the profile now in the list.
```bash
Service Name: Serial Port
...
Channel: 1
```


## 1. Pair the Raspberry Pi with another device (using BlueZ)

On the Raspberry Pi, open a terminal and run:

```bash
sudo bluetoothctl
````

Inside the bluetoothctl prompt:

```bash
power on
agent on
default-agent
discoverable on
pairable on
scan on
```

On your laptop, start Bluetooth discovery.
When your laptop appears in the list, note its MAC address. If your laptop/phone's MAC address is hard to spot enter into bluetoothctl:

```bash
devices
```

This gives a list of discovered devices. Now inside bluetoothctl run:

```bash
pair AA:BB:CC:DD:EE:FF
trust AA:BB:CC:DD:EE:FF
```

When a matching confirmation code is displayed on both devices, accept. Depending on the communication, raspberry might ask for you to accept some communication protocols by choosing yes/no.

You can now turn 'discoverable off' and exit bluetoothctl.

## 2. Connect from a laptop/phone/tablet etc.

macOS example (inside terminal):
```bash
screen /dev/cu.raspberrypi 115200
```

Linux example:
```bash
screen /dev/rfcomm0 115200
```

## 3. Start Berry-Bridge

Execute the bridging shell script:
```bash
sudo ./usr/local/sbin/device-console.sh
```

## 4. Help / Troubleshooting: device names may differ 

#### 4.1. Different Raspberry Pi models and USB adapters may use different device names.

```bash
ls -l /dev/rfcomm*
````

```bash
/dev/rfcomm0
```

If you see /dev/rfcomm1 or another number, update the  command accordingly.


#### 4.2. Check which USB serial device is connected

Plug in your USB‑to‑serial adapter and run:
```bash
ls -l /dev/ttyUSB*
ls -l /dev/ttyACM*
```

Common results are '/dev/ttyUSB0' and '/dev/ttyACM0'. If yours differ from the default used in code (/dev/ttyUSB0). Note: Wireless mouse and keyboard receivers use HID (Human Interface Device) protocols, not serial communication. Only serial devices like USB-to-RS232 adapters will show up as /dev/ttyUSB0.