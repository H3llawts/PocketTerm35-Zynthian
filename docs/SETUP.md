# Setup walkthrough: PocketTerm35 + Zynthian on Pi 4

## 1. Starting point
This procedure records a successful Raspberry Pi 4 8 GB setup. Start with a booting Zynthian SD card and working HDMI display. Have SSH access so you can edit boot settings even if an input device fails.

The exact Zynthian image/kernel version and final Webconf Kit/Wiring/Display/Audio choices were not recorded. Do not treat an unverified Webconf preset as part of the proven fix. Preserve a currently working Webconf setup.

The commands below run **on the Pi**, not on your desktop. The original session used root; use `sudo` where required if logged in as another user.

## 2. Install Waveshare's boot support
Follow [Waveshare's software guide](https://docs.waveshare.com/PocketTerm35/Software-Guide) to obtain the official PocketTerm35 DTBO archive. Extract the Pi 4 file and place `waveshare-35dpi-4b.dtbo` in `/boot/firmware/overlays/` on this Zynthian installation.

Back up the active configuration before editing:

```bash
sudo cp -n /boot/firmware/config.txt /boot/firmware/config.txt.before-pocketterm
sudo nano /boot/firmware/config.txt
```

Merge these lines under an appropriate `[all]` section; reuse existing entries rather than add duplicates:

```ini
[all]
dtparam=i2c_arm=on
dtoverlay=waveshare-35dpi-4b
dtoverlay=dwc2,dr_mode=host
```

These are the initial vendor settings. The touch repair later **replaces** the Waveshare overlay line. Keep the rest of Zynthian's config, including existing audio/MIDI and model-specific sections.

On the tested installation, `/boot/firmware/config.txt` was active. Files under an unused `/boot/overlays` directory do not automatically create duplicate active overlays.

Reboot. Check built-in keyboard and pointing controls. The keyboard uses USB; the touchscreen uses I²C, so keyboard success does not prove touch is working.

## 3. Diagnose touch before changing its address
If touch already works, skip the repair.

```bash
cat /proc/bus/input/devices
sudo dmesg | grep -Ei 'touch|goodix|gt9|i2c'
sudo i2cdetect -y 1 0x14 0x14
sudo i2cdetect -y 1 0x5d 0x5d
```

Install missing tools if needed:

```bash
sudo apt-get update
sudo apt-get install -y device-tree-compiler i2c-tools python3
```

The confirmed failure was Goodix probing at `1-0014`, reporting I²C error `-5`, with no touch input device. The targeted scan showed `--` at 0x14 and `5d` at 0x5d.

**Apply this repair only for that address mismatch.** `UU` means an address is reserved by a driver; it is not a successful communication test. Neither address responding calls for more diagnosis, not this patch.

## 4. Apply the verified address change
Clone this repository using your normal GitHub authentication (if private), or copy it onto the Pi. From the repository directory:

```bash
sudo bash scripts/fix-touch-5d.sh --address-5d-confirmed
```

The helper:
- checks for a Pi 4 and the expected vendor overlay;
- compiles a separate overlay with address 0x5d;
- preserves GPIO 4 falling-edge interrupt, 640×480 dimensions and other vendor settings;
- makes a unique config backup;
- replaces the original overlay entry;
- leaves the original vendor DTBO intact and does not reboot automatically.

Warnings about fixups/phandles can appear while decompiling a standalone overlay; the original successful procedure produced those warnings. A compilation error is different: stop and read it.

Confirm:

```bash
ls -l /boot/firmware/overlays/pocketterm-touch-5d.dtbo
grep '^dtoverlay=' /boot/firmware/config.txt
```

Expect `dtoverlay=pocketterm-touch-5d`, with no active `dtoverlay=waveshare-35dpi-4b` entry. Then:

```bash
sudo reboot
```

## 5. Verify on the device
Tap menus and controls; confirm that touch positions match the display. Check keyboard and trackball again.

```bash
sudo dmesg | grep -Ei 'goodix|touch'
cat /proc/bus/input/devices
```

Rob reported “touch is working now” after this address change. No touch rotation/calibration change was needed in that report.

The helper is a guarded packaging of the manual repair; the hardware-confirmed operation was the original manual patch, not a separate run of this helper.

## 6. Existing Pimoroni trackball
The tested system already exposed `PocketTerm35 Pimoroni Trackball` through `py-evdev-uinput`. Keep the existing driver/service and calibration. This session did not capture the service file, startup command, sensitivity or LED configuration.

See the separate [PocketTerm35 Addons project](https://github.com/H3llawts/-PocketTerm35-Addons) for that work. Its installer compatibility with this Zynthian image has not been independently verified here.

## 7. Backup and rollback
Save both files together off the SD card:
- `/boot/firmware/config.txt`
- `/boot/firmware/overlays/pocketterm-touch-5d.dtbo`

Also save your Zynthian configuration and existing trackball service separately. Keep a full SD image once satisfied.

To revert just the touch overlay selection:

```bash
sudo sed -i 's/^dtoverlay=pocketterm-touch-5d$/dtoverlay=waveshare-35dpi-4b/' /boot/firmware/config.txt
sudo reboot
```

That restores the original address behavior, including its original touch failure on the tested unit. If needed, restore the exact timestamp-independent unique backup path printed by the helper; doing so also reverts any later edits to that config.

After changing hardware settings through Zynthian Webconf or an update, check that the custom overlay entry and DTBO still exist if touch stops working.

## Optional: compile the readable source
The repository also contains a readable equivalent of the successful overlay. To compile it locally for inspection:

```bash
dtc -@ -I dts -O dtb -o /tmp/pocketterm-touch-5d.dtbo overlays/pocketterm-touch-5d.dts
```

This does not install or activate it. The main repair route patches the original vendor overlay as in the successful session.
