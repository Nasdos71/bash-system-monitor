## Bash System Monitor (OS Course Project)

This project is a **pure bash** system monitor that shows the machine state, similar to a simple task manager.

---

## 🌐 NEW: Web Dashboard

A beautiful **React-based web dashboard** for real-time system monitoring:

![Dashboard Preview](docs/dashboard-preview.png)

### Features:
- **Dark/Light Mode** toggle
- **Live Performance Charts** with CPU and Memory history
- **Auto-refresh** every 1-10 seconds (configurable)
- **Collapsible Sections** for clean interface
- **GPU Monitoring** (NVIDIA support)
- **Responsive Design** works on all screen sizes

### Quick Start (Local):
```bash
# Start the dashboard
./system_monitor.sh
# Press 'r' to start the dashboard server

# Or manually:
cd dashboard && npm install && npm run dev
```

### Quick Start (Docker):
```bash
# Build and run with Docker
docker-compose up -d

# Dashboard available at http://localhost:8080
```

---

## 🖥️ YAD Task Manager Mode

The **YAD Task Manager** provides a modern, **Windows Task Manager-like** GUI experience:

- **Tabbed Interface**: Overview, Processes, CPU, Memory, Disk, Network tabs
- **Live Mode**: Real-time auto-refreshing performance view
- **Process List**: Sortable table showing all running processes
- **Visual Progress Bars**: ASCII art bars for CPU, Memory, Swap, and Disk usage
- **AI Integration**: One-click AI system analysis powered by Gemini

To use YAD Task Manager mode:
```bash
./system_monitor.sh
# Then press 't' for full Task Manager, or 'y' for simple YAD mode
```

---

## 📋 Menu Options

**Web Dashboard:**
- `j)` Generate Dashboard Data (JSON for React dashboard)
- `r)` Start Dashboard Server (opens browser at localhost:3000)

**GUI Modes (Recommended):**
- `t)` **🖥️ YAD Task Manager** — Windows Task Manager-like interface with tabs
- `p)` Performance Monitor — Live CPU/RAM/Disk/Swap bars
- `y)` YAD Simple Mode — Simple YAD dialogs

**CLI Options:**
- `1-7)` Individual system views (CPU, Memory, Disk, Processes, GPU, Network, System)
- `8)` Show everything (one-shot)
- `9)` Start logging to monitor.log
- `s)` Search processes
- `h)` Generate HTML report from log
- `a)` AI Insights (Gemini analysis)

**Legacy GUI:**
- `d)` Dialog mode (requires dialog/whiptail)
- `w)` Window mode (requires zenity)

---

## 🐳 Docker

### Production (with Web Dashboard):
```bash
# Build the image
docker build -t system-monitor .

# Run the container
docker run -d -p 8080:8080 --name system-monitor system-monitor

# Or use docker-compose
docker-compose up -d

# Access dashboard at http://localhost:8080
```

### Development Mode:
```bash
# Start dev server in Docker
docker-compose --profile dev up dashboard-dev

# Access at http://localhost:3000
```

### Environment Variables:
- `HOST_PROC=/host/proc` - Use host's /proc for accurate metrics
- `HOST_SYS=/host/sys` - Use host's /sys for temperature data

---

## 📦 Installation

### Required for YAD Task Manager (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install -y yad sysstat lm-sensors pciutils
```

### Required for Web Dashboard:
```bash
# Node.js 18+ required
cd dashboard
npm install
```

### All dependencies (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install -y yad sysstat lm-sensors pciutils dialog zenity curl
```

### Other distros:
```bash
# Fedora
sudo dnf install yad sysstat lm_sensors pciutils dialog zenity

# Arch Linux
sudo pacman -S yad sysstat lm_sensors pciutils dialog zenity
```

---

## 📁 Project Structure

```
bash-system-monitor/
├── system_monitor.sh     # Main script with all features
├── generate_json.sh      # JSON data generator for dashboard
├── dashboard/            # React + Tailwind web dashboard
│   ├── src/
│   │   ├── App.jsx       # Main dashboard component
│   │   └── index.css     # Tailwind styles
│   └── public/data/      # JSON data output directory
├── docker/
│   └── nginx.conf        # Nginx config for Docker
├── Dockerfile            # Multi-stage Docker build
├── docker-compose.yml    # Docker Compose config
└── docs/
    └── dependencies.md   # Full dependency list
```

---

## 🔧 Features

- **CPU**: usage, load averages, temperature, cache info, core details
- **Memory**: RAM, swap, cached, buffers, page tables
- **Disk**: usage per filesystem, I/O stats, inode usage
- **Processes**: full process list with sorting
- **GPU**: NVIDIA GPU stats (usage, temp, memory, power, clocks)
- **Network**: interface status, RX/TX bytes, packets, errors
- **AI Insights**: Gemini-powered system analysis

---

## 📝 Notes

- Some advanced features require extra tools (`nvidia-smi`, `lspci`, `sensors`)
- The script degrades gracefully when tools are unavailable
- Docker image includes all required dependencies
- For CPU temperatures, install `lm-sensors` or rely on thermal sysfs

---

## 📚 Documentation

See `docs/dependencies.md` for the full list (native + Docker + GPU notes).
