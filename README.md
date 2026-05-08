# SteamOS-LGTV-Wake

SteamOS-LGTV-Wake is a lightweight user-space utility for SteamOS gaming PCs that automatically wakes LG webOS TVs and switches to a specified HDMI input.

The project was designed specifically for SteamOS and living room gaming setups, with a strong focus on update-resistant behavior. All scripts and services run entirely in user space and avoid modifying the immutable operating system or relying on external Python packages.

## Features

* Wake LG webOS TVs over the network
* Automatically switch to a configured HDMI input
* Repeatedly send HDMI input switch commands after wake for improved reliability during TV/AVR/HDMI handshake and startup timing
* Trigger TV wake from a controller Guide button press
* Trigger TV wake when the PC resumes from sleep
* Configurable behavior through a simple JSON config file
* No CEC hardware required
* No root filesystem modifications
* No external Python dependencies

## Linux Compatibility

Although this project is primarily targeted at SteamOS, it should also work on most modern Linux distributions that use:

* systemd
* Python 3
* standard Linux input event devices (`/dev/input/event*`)

This includes distributions such as:

* Bazzite
* Arch Linux
* Fedora
* CachyOS
* Ubuntu
* Pop!_OS
* other similar Linux desktop environments

## Installation

```bash
curl -LO https://raw.githubusercontent.com/M-Gilly/SteamOS-LGTV-Wake/main/install.sh
chmod +x install.sh
./install.sh
```

The installer will:

* pair with your LG TV
* configure wake and HDMI input behavior
* install user-space systemd services
* optionally add your user to the `input` group for Guide button support

You may need to reboot once after installation if your user was added to the `input` group.

## Configuration

Configuration is stored at:

```text
~/scripts/lgtvcontrol/config.json
```

Example:

```json
{
  "tv_ip": "192.168.1.30",
  "input_id": "HDMI_1",
  "guide_button_code": 316,

  "trigger_on_wake": true,
  "trigger_on_guide_button": true,

  "hdmi_force_seconds": 10,
  "hdmi_force_interval": 2,

  "wake_on_lan": true,
  "network_wait_seconds": 30
}
```

Most Xbox-style controllers expose the Guide/Home button as Linux input code `316` (`BTN_MODE`).

## Manual Commands

Wake TV and force HDMI input:

```bash
~/scripts/lgtvcontrol/lgtv-on.sh
```

Turn TV off:

```bash
~/scripts/lgtvcontrol/lgtv-off.sh
```

Force HDMI input once:

```bash
~/scripts/lgtvcontrol/lgtv-hdmi.sh
```

Full test cycle:

```bash
~/scripts/lgtvcontrol/lgtv-test.sh
```

## Service Status

Guide button watcher:

```bash
systemctl --user status guide-lgtv-watch.service
```

Wake/resume watcher:

```bash
systemctl --user status wake-lgtv-watch.service
```

Logs:

```bash
journalctl --user -u guide-lgtv-watch.service -n 100 --no-pager
journalctl --user -u wake-lgtv-watch.service -n 100 --no-pager
```

## LG TV Settings

For Wake-on-LAN support, enable:

```text
Settings
→ General
→ Devices
→ External Devices
→ TV On With Mobile
```

Enable:

* Turn On via Wi-Fi
* Mobile TV On

For best reliability, also disable:

```text
Settings
→ General
→ Quick Start+
```

Some LG TVs do not reliably respond to network wake events when Quick Start+ is enabled.

## Uninstall

Run:

```bash
~/scripts/lgtvcontrol/uninstall.sh
```

This will:

* disable and remove the user services
* optionally remove the LGTV control directory and pairing key

## Repository

https://github.com/M-Gilly/SteamOS-LGTV-Wake

## Credits

Special thanks to quickbits910 for BazziteLGTV (https://github.com/quickbits910/BazziteLGTV). It provided the original source and groundwork around lightweight LG webOS control on Linux.
