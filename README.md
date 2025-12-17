## Bash System Monitor (OS Course Project)

This project is a **pure bash** system monitor that shows the machine state, similar to a simple task manager.

### Features (planned)
- **CPU**: usage, load averages, basic info.
- **Memory**: RAM and swap usage.
- **Disk**: usage per filesystem.
- **Processes**: top processes by CPU/RAM.
- **GPU**: basic info, usage, and temperature *when supported by the system*.
- **Text-based GUI (bonus)**: menu + popup-style interface using standard Linux tools.
- **Android/Termux support (bonus)**: run the monitor in Termux on Android with graceful fallbacks.

### Main Script
- `system_monitor.sh` — entry point script.

Run (on Linux / WSL / Termux):

```bash
chmod +x system_monitor.sh
./system_monitor.sh
```

Current menu (CLI):
- 1) CPU (info + usage + temps if available, with bar + alerts) — refreshes every ~2s until any key
- 2) Memory info — refreshes every ~2s until any key
- 3) Disk usage — refreshes every ~2s until any key
- 4) Top processes — refreshes every ~2s until any key
- 5) GPU info — refreshes every ~2s until any key
- 6) Network (interfaces, RX/TX, IPs) — refreshes every ~2s until any key
- 7) System info (kernel, distro, uptime, users, battery) — refreshes every ~2s until any key
- 8) Show everything (one-shot; press Enter to return)
- 9) Start logging FULL comprehensive snapshots to monitor.log (all sections, for report generation)
- d) Dialog mode (popup menus/boxes, auto-refresh; includes all features; requires dialog/whiptail)
- w) Window mode (zenity GUI popups, auto-refresh; includes all features; requires zenity)
- 0) Exit

GUI refresh notes:
- Dialog mode: auto-refreshes every ~2s; Stop/Cancel/ESC exits. Includes all features (CPU, Memory, Disk, Processes, GPU, Network, System info).
- Window (zenity) mode: auto-refreshes every ~2s; Stop/Cancel closes. Includes all features (CPU, Memory, Disk, Processes, GPU, Network, System info).

Logging:
- Option 9 logs FULL comprehensive snapshots (all sections: CPU, Memory, Disk, Processes, GPU, Network, System info) every ~2s to `monitor.log`.
- Perfect for generating reports later - captures complete system state at each timestamp.

Suggested packages (Ubuntu / Debian):
```bash
sudo apt update
sudo apt install -y sysstat lm-sensors pciutils dialog
# For window mode:
sudo apt install -y zenity
```

Docker image already includes all required deps (bash, procps, sysstat, lm-sensors, pciutils, dialog, zenity, ca-certificates).

> Note: Some advanced features (like GPU usage/temperature) may require extra tools such as `nvidia-smi`, `lspci`, or `sensors` to be installed on the target system. The script will try to detect what is available and degrade gracefully.
> For CPU temperatures, install and run `sensors` (`lm-sensors`) or rely on thermal sysfs if present.

### Dependencies doc
See `docs/dependencies.md` for the full list (native + Docker + GPU notes).


