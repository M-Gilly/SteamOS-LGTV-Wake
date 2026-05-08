#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/scripts/lgtvcontrol"
SERVICE_DIR="$HOME/.config/systemd/user"

mkdir -p "$APP_DIR"
mkdir -p "$SERVICE_DIR"

echo
echo "SteamOS-LGTV-Wake Installer"
echo

DEFAULT_TV_IP="192.168.1.30"
DEFAULT_INPUT_ID="HDMI_1"
DEFAULT_GUIDE_CODE="316"

read -rp "LG TV IP [$DEFAULT_TV_IP]: " TV_IP
TV_IP="${TV_IP:-$DEFAULT_TV_IP}"

read -rp "HDMI input [$DEFAULT_INPUT_ID]: " INPUT_ID
INPUT_ID="${INPUT_ID:-$DEFAULT_INPUT_ID}"

echo
echo "Press your controller Guide/Home button to detect the button code..."
echo "Waiting for input..."

GUIDE_CODE="$(
python3 - <<'PY'
from evdev import InputDevice, categorize, ecodes, list_devices
import select

devices = []
for path in list_devices():
    try:
        dev = InputDevice(path)
        devices.append(dev)
    except Exception:
        pass

while True:
    r, _, _ = select.select(devices, [], [])
    for dev in r:
        for event in dev.read():
            if event.type == ecodes.EV_KEY and event.value == 1:
                print(event.code)
                raise SystemExit
PY
)"

echo "Detected Guide button code: $GUIDE_CODE"

cat > "$APP_DIR/config.json" <<EOF
{
"tv_ip": "$TV_IP",
"input_id": "$INPUT_ID",
"guide_button_code": $GUIDE_CODE,

"trigger_on_wake": true,
"trigger_on_guide_button": true,

"hdmi_force_seconds": 10,
"hdmi_force_interval": 2,

"wake_on_lan": true,
"network_wait_seconds": 30
}
EOF

echo
echo "Configuration written to:"
echo "$APP_DIR/config.json"

cat > "$APP_DIR/lgtv-on.sh" <<'EOF'
#!/usr/bin/env bash
echo "Placeholder lgtv-on.sh"
EOF

cat > "$APP_DIR/lgtv-off.sh" <<'EOF'
#!/usr/bin/env bash
echo "Placeholder lgtv-off.sh"
EOF

cat > "$APP_DIR/lgtv-hdmi.sh" <<'EOF'
#!/usr/bin/env bash
echo "Placeholder lgtv-hdmi.sh"
EOF

cat > "$APP_DIR/lgtv-test.sh" <<'EOF'
#!/usr/bin/env bash
echo "Placeholder lgtv-test.sh"
EOF

chmod +x "$APP_DIR"/lgtv-*.sh

cat > "$SERVICE_DIR/guide-lgtv-watch.service" <<EOF
[Unit]
Description=SteamOS LGTV Guide Button Watcher

[Service]
ExecStart=$APP_DIR/lgtv-on.sh
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
EOF

cat > "$SERVICE_DIR/wake-lgtv-watch.service" <<EOF
[Unit]
Description=SteamOS LGTV Resume Watcher

[Service]
ExecStart=$APP_DIR/lgtv-on.sh
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
EOF

if ! groups "$USER" | grep -qw input; then
echo
echo "Adding $USER to input group..."
sudo usermod -aG input "$USER"
echo "Reboot required for input group changes."
fi

systemctl --user daemon-reload
systemctl --user enable --now guide-lgtv-watch.service
systemctl --user enable --now wake-lgtv-watch.service

cat > "$APP_DIR/uninstall.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

systemctl --user disable --now guide-lgtv-watch.service || true
systemctl --user disable --now wake-lgtv-watch.service || true

rm -f "$SERVICE_DIR/guide-lgtv-watch.service"
rm -f "$SERVICE_DIR/wake-lgtv-watch.service"

systemctl --user daemon-reload

echo
read -rp "Remove $APP_DIR? [y/N]: " REMOVE

case "$REMOVE" in
y|Y|yes|YES)
rm -rf "$APP_DIR"
;;
esac

echo "Uninstall complete."
EOF

chmod +x "$APP_DIR/uninstall.sh"

echo
echo "Install complete."
echo
echo "Recommended LG TV settings:"
echo "  Settings -> General -> Devices -> External Devices -> TV On With Mobile"
echo "    Enable: Turn On via Wi-Fi"
echo "    Enable: Mobile TV On"
echo
echo "Also disable:"
echo "  Settings -> General -> Quick Start+"
echo
echo "You may need to reboot once if your user was added to the input group."
