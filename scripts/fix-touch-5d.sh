#!/usr/bin/env bash
# Apply only after confirming the PocketTerm35 GT911 responds at 0x5d.
# Uses the installed vendor overlay so its remaining settings are preserved.
set -euo pipefail

if [[ "${1:-}" != "--address-5d-confirmed" ]]; then
    echo "First follow docs/SETUP.md and confirm touch responds at 0x5d."
    echo "Then: sudo bash scripts/fix-touch-5d.sh --address-5d-confirmed"
    exit 1
fi
[[ $EUID -eq 0 ]] || { echo "Run as root or with sudo."; exit 1; }
grep -aq 'Raspberry Pi 4' /proc/device-tree/model ||
    { echo "This helper is restricted to Raspberry Pi 4."; exit 1; }
for tool in dtc python3; do
    command -v "$tool" >/dev/null || { echo "Missing dependency: $tool"; exit 1; }
done

boot=/boot/firmware
source_overlay="$boot/overlays/waveshare-35dpi-4b.dtbo"
target_overlay="$boot/overlays/pocketterm-touch-5d.dtbo"
[[ -f "$boot/config.txt" && -f "$source_overlay" ]] ||
    { echo "Expected config.txt and Waveshare overlay under /boot/firmware."; exit 1; }
[[ ! -e "$target_overlay" ]] ||
    { echo "Custom overlay already exists; inspect it rather than overwrite it."; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dtc -I dtb -O dts "$source_overlay" -o "$work/original.dts"

python3 - "$work" "$boot/config.txt" <<'PY'
import pathlib, re, sys
work = pathlib.Path(sys.argv[1])
config = pathlib.Path(sys.argv[2]).read_text()
source = (work / "original.dts").read_text()
if 'compatible = "goodix,gt911";' not in source:
    raise SystemExit("Unexpected controller; no boot files changed.")
if source.count("ft6236@14") != 2 or source.count("reg = <0x14>;") != 1:
    raise SystemExit("Overlay differs from the verified version; inspect manually.")
if re.search(r"^\s*dtoverlay=pocketterm-touch-5d", config, re.M):
    raise SystemExit("Custom overlay already configured; inspect manually.")
pattern = r"^(\s*)dtoverlay=waveshare-35dpi-4b[ \t]*(?:#.*)?$"
if len(re.findall(pattern, config, re.M)) != 1:
    raise SystemExit("Expected exactly one plain waveshare-35dpi-4b entry.")
source = source.replace("ft6236@14", "ft6236@5d").replace("reg = <0x14>;", "reg = <0x5d>;")
config = re.sub(pattern, r"\1dtoverlay=pocketterm-touch-5d", config, flags=re.M)
(work / "patched.dts").write_text(source)
(work / "config.txt").write_text(config)
PY

dtc -I dts -O dtb "$work/patched.dts" -o "$work/patched.dtbo"
backup=$(mktemp "$boot/config.txt.before-touch-5d.XXXXXX")
cp "$boot/config.txt" "$backup"
# Install the overlay before activating it. Original vendor DTBO is untouched.
cp "$work/patched.dtbo" "$target_overlay"
cp "$work/config.txt" "$boot/config.txt"
sync
echo "Installed $target_overlay"
echo "Boot configuration backup: $backup"
echo "Reboot when ready, then test touch and inspect dmesg."
