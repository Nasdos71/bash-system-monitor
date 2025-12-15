## Dependencies

These are the packages/tools the bash monitor expects. Install them on native Linux, or bake them into Docker (already added in the Dockerfile).

### Required (for full CLI features)
- `bash`
- `procps` (ps, top, uptime)
- `sysstat` (mpstat for CPU usage)
- `lm-sensors` (sensors for temps)
- `pciutils` (lspci for GPU device listing)
- `dialog` (for future text-based GUI)
- `ca-certificates` (good practice)

Install on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y bash procps sysstat lm-sensors pciutils dialog ca-certificates
```

After installing `lm-sensors` on bare metal (not usually useful on WSL):
```bash
sudo sensors-detect   # accept defaults
sensors
```

### Optional / conditional
- `nvidia-smi` (only if host has NVIDIA drivers; inside Docker, run with `--gpus all` on a compatible Linux host).

### Notes for WSL / Android (Termux)
- WSL often does **not** expose hardware temps or GPUs; expect limited sensor data.
- Termux can run the script, but GPU/temps are usually unavailable.

### Docker
The provided `Dockerfile` installs the required packages above. For GPU inside Docker on a Linux host with NVIDIA drivers:
```bash
docker run --gpus all --rm -it bash-system-monitor
```
WSL GPU visibility may be limited even with this flag.

