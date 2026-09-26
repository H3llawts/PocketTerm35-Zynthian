# PocketTerm35-Zynthian
Waveshare PocketTerm35 configuration for Zynthian.

A working pocket Zynthian setup on **Raspberry Pi 4, 8 GB** with the PocketTerm35 HDMI display, built-in USB keyboard/mouse, and an added Pimoroni trackball.

## Confirmed working
Rob confirmed keyboard, trackball, and touchscreen operation on September 25, 2026. The touchscreen fix below was applied successfully on that device.

| Component | Verified configuration |
| --- | --- |
| Display | PocketTerm35 HDMI, 640 × 480 |
| Built-in keyboard/mouse | USB Pico device; `dtoverlay=dwc2,dr_mode=host` |
| I²C bus | `dtparam=i2c_arm=on`; GPIO 2 SDA1, GPIO 3 SCL1 |
| Touch controller | Goodix GT911, responding at **0x5d** |
| Touch interrupt | GPIO 4, falling edge |
| Touch overlay | `pocketterm-touch-5d.dtbo` |
| Added trackball | Existing userspace service exposes “PocketTerm35 Pimoroni Trackball” |

The supplied Waveshare overlay on this installation declared touch at **0x14**. Linux loaded Goodix but failed to communicate. A targeted bus check found the controller at **0x5d**. Changing that address in a separate overlay restored touch.

**This is a confirmed Pi 4 setup, not a universal Pi 4/5 image or preset.** Zynthian image/kernel version, exact Webconf selections, audio routing, and MIDI operation were not captured in this session.

## Start here
1. Follow [the setup walkthrough](docs/SETUP.md).
2. Use [the diagnostic record](docs/TROUBLESHOOTING.md) if touch fails.
3. Keep the [boot fragment](config/pocketterm35-pi4.txt) as a reference, not a replacement for your full config.
4. The [repair script](scripts/fix-touch-5d.sh) creates the corrected overlay from your installed Waveshare file.

Already working after our fix? **You do not need to rerun the installer.** Save your current boot configuration and corrected overlay.

## Repository contents
- `docs/SETUP.md` — prerequisites, boot edits, confirmed touch repair, verification, backup and rollback.
- `docs/TROUBLESHOOTING.md` — actual failure signatures and diagnostic commands.
- `scripts/fix-touch-5d.sh` — guarded version of the successful manual patch; no automatic reboot.
- `config/pocketterm35-pi4.txt` — only the relevant boot lines.
- `overlays/pocketterm-touch-5d.dts` — readable equivalent of the working overlay.

## Scope and validation
The original manual patch was tested on hardware and confirmed working by Rob. The packaged helper is derived from that patch; it has not itself been run on his hardware. Trackball installation is a separate project: its service was already working, so this repository does not replace it or invent its calibration settings.

## References
- [Waveshare software guide](https://docs.waveshare.com/PocketTerm35/Software-Guide)
- [Waveshare troubleshooting](https://docs.waveshare.com/PocketTerm35/FAQ)
- [Zynthian project](https://github.com/zynthian)
