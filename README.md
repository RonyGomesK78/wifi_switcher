# WiFi Switcher

Automatically switch between your preferred WiFi networks based on signal strength. Uses NetworkManager (`nmcli`) to rescan, pick the strongest network from a list, and connect to it.

## Prerequisites

- **NetworkManager** with `nmcli` (default on most Linux desktops)
- Bash 4+
- Root/sudo if you run via systemd (typical for changing connections)

## Configuration

Edit `index.sh` and set the `SSIDS` array to your **NetworkManager connection names** (profile names), in order of preference. These are the names shown by:

```bash
nmcli connection show
```

They may differ from the broadcast SSID (e.g. "Wufi 5GHZ" as a profile name). List your preferred networks in the order you want them considered when signal is equal.

## Usage

### Step 1: Run manually

Make the script executable (one-time):

```bash
chmod +x /path/to/wifi_switcher/index.sh
```

Run it from any directory:

```bash
/path/to/wifi_switcher/index.sh
```

Or with bash:

```bash
bash /path/to/wifi_switcher/index.sh
```

If you get permission errors when switching networks, run with sudo:

```bash
sudo /path/to/wifi_switcher/index.sh
```

### Step 2: Run automatically with a systemd timer (recommended)

Systemd timers are a modern alternative to cron: integrated logging, better handling of missed runs, and no separate cron daemon.

Create **two** unit files in `/etc/systemd/system/` (system-wide, since WiFi management usually needs root):

#### 1. Service unit

Create `/etc/systemd/system/wifi-switcher.service`:

```ini
[Unit]
Description=Automatic WiFi network switcher based on signal strength

[Service]
Type=oneshot
ExecStart=/home/rony78k/projects/wifi_switcher/index.sh
```

- `Type=oneshot`: the script runs once and exits.
- If the script is not executable, use:  
  `ExecStart=/bin/bash /home/rony78k/projects/wifi_switcher/index.sh`
- Adjust the path to match your install location.

#### 2. Timer unit

Create `/etc/systemd/system/wifi-switcher.timer`:

```ini
[Unit]
Description=Run WiFi switcher every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=wifi-switcher.service
Persistent=true

[Install]
WantedBy=timers.target
```

- **OnBootSec=2min** — first run ~2 minutes after boot (allows WiFi to come up).
- **OnUnitActiveSec=5min** — then every 5 minutes.
- **Persistent=true** — if a run was missed (e.g. suspend), run soon after next boot.
- You can change intervals (e.g. `10min`, `15min`) as needed.

#### 3. Enable and start the timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable wifi-switcher.timer
sudo systemctl start wifi-switcher.timer
```

#### 4. Verify and monitor

- Status: `sudo systemctl status wifi-switcher.timer`
- Upcoming runs: `systemctl list-timers --all`
- Logs: `journalctl -u wifi-switcher.service -f` (live) or `journalctl -u wifi-switcher.service` (history)

To stop the timer temporarily:

```bash
sudo systemctl stop wifi-switcher.timer
```

## User-level vs system-level

For system-wide scheduling and reliable `nmcli` usage, the examples use `/etc/systemd/system/`. You can instead use user units in `~/.config/systemd/user/`, but switching WiFi often still requires sufficient privileges; adjust paths and `ExecStart` as needed.

## License

Use and modify as you like.
