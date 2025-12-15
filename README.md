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
- 1) CPU (info + usage + temps if available) — refreshes every ~2s until any key
- 2) Memory info — refreshes every ~2s until any key
- 3) Disk usage — refreshes every ~2s until any key
- 4) Top processes — refreshes every ~2s until any key
- 5) GPU info — refreshes every ~2s until any key
- 6) Show everything (one-shot; press Enter to return)
- 0) Exit

Suggested packages (Ubuntu / Debian):
```bash
sudo apt update
sudo apt install -y sysstat lm-sensors pciutils dialog
```

> Note: Some advanced features (like GPU usage/temperature) may require extra tools such as `nvidia-smi`, `lspci`, or `sensors` to be installed on the target system. The script will try to detect what is available and degrade gracefully.
> For CPU temperatures, install and run `sensors` (`lm-sensors`) or rely on thermal sysfs if present.

### Dependencies doc
See `docs/dependencies.md` for the full list (native + Docker + GPU notes).


