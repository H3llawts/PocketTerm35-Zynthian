# Touchscreen diagnostic record

## What failed
The original boot log contained:

```text
Goodix-TS 1-0014: supply AVDD28 not found, using dummy regulator
Goodix-TS 1-0014: supply VDDIO not found, using dummy regulator
Goodix-TS 1-0014: Error reading 1 bytes from 0x8140: -5
Goodix-TS 1-0014: I2C communication failure: -5
Goodix-TS 1-0014: probe with driver Goodix-TS failed with error -5
```

There was no touchscreen in /proc/bus/input/devices. The dummy regulator messages alone did not establish a power fault. The useful evidence was the failed I²C access plus a responding alternate address.

## Evidence
| Check | Observed result |
| --- | --- |
| GPIO 2 | SDA1, high, pull-up |
| GPIO 3 | SCL1, high, pull-up |
| GPIO 4 | Input, low, pull-up |
| Device-tree node | i2c bus 1, ft6236@14 |
| Compatible property | goodix,gt911 |
| Vendor reg property | 0x14 |
| Targeted scan at 0x14 | No response |
| Targeted scan at 0x5d | Response |
| Corrected overlay | reg 0x5d; remaining settings preserved |
| Result after reboot | User confirmed touch working |

The node name ft6236@14 was misleading: the compatible property selected the Goodix driver. The repair updated the node name and its fixup path as well as reg.

## Useful commands
Run on the Pi:

```bash
grep -nE '^\[|^[[:space:]]*(include|dtoverlay|dtparam|gpio)' /boot/config.txt /boot/firmware/config.txt 2>/dev/null
cat /proc/bus/input/devices
sudo dmesg | grep -Ei 'touch|goodix|gt9|i2c'
ls -l /sys/bus/i2c/devices/1-*/of_node
sudo i2cdetect -y 1 0x14 0x14
sudo i2cdetect -y 1 0x5d 0x5d
```

Pin state:

```bash
if command -v pinctrl >/dev/null; then
    sudo pinctrl get 2-4
elif command -v raspi-gpio >/dev/null; then
    sudo raspi-gpio get 2-4
fi
```

Read the original overlay (does not edit anything):

```bash
dtc -I dtb -O dts /boot/firmware/overlays/waveshare-35dpi-4b.dtbo
```

After patching, that original file still says 0x14. Inspect the **new** file to check the repair:

```bash
dtc -I dtb -O dts /boot/firmware/overlays/pocketterm-touch-5d.dtbo
```

## If the failure differs
- No custom DTBO file: the repair did not complete; inspect its output.
- Goodix still probes 1-0014 after reboot: check active boot config, includes and duplicate overlays.
- Neither address responds: compare against a known-working SD card and check powered-off hardware contacts. Waveshare identifies GPIO 2/3/4 conflicts and pogo-pin contact as possible causes.
- Kernel registers touch but Zynthian ignores it: investigate application input configuration next; do not keep changing the I²C address.
- Touch is offset/rotated: first verify display orientation and input mapping; that was not the original failure.
- Keyboard fails: check the USB host overlay and internal USB connection; this is a different path from I²C touch.
