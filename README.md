## Bash System Monitor v2.0 🖥️
<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20WSL%20%7C%20Android-success.svg?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-purple.svg?style=flat-square)
![Built With](https://img.shields.io/badge/built%20with-Bash%20%7C%20React%20%7C%20AI-orange.svg?style=flat-square)

**The ultimate dependency-free system monitor, now with AI capabilities and a Web Dashboard.**
</div>

---

### 🚀 What's New?
- **📱 Android Support**: Run natively on your phone via Termux (Battery, WiFi, Sensors).
- **🧠 AI Insights**: Integrated Gemini AI analysis to detect system bottlenecks.
- **📊 Web Dashboard**: A modern React-based real-time dashboard.
- **📈 HTML Reports**: Generate interactive charts for post-mortem analysis.
- **🖥️ Task Manager**: New YAD-based GUI with process management.

---

### 📖 Documentation
Detailed guides in the `docs/` directory:

- **[User Guide](docs/USER_GUIDE.md)**: Manual for CLI, AI features, and Report generation.
- **[Installation Guide](docs/INSTALLATION.md)**: Setup for Linux, Termux, and Node.js.
- **[Architecture](docs/ARCHITECTURE.md)**: System design and data flow.
- **[Screenshots Guide](docs/SCREENSHOTS_GUIDE.md)**: How to capture evidence.

---

### ✨ Key Features
- **CPU**: Load averages, frequency, and real-time per-core usage.
- **Memory**: Detailed RAM and Swap breakdown (including visuals).
- **Disk**: Filesystem usage, Inode tracking, and I/O stats.
- **Network**: Real-time traffic, IP info, and interface status.
- **GPU**: NVIDIA (`nvidia-smi`) and Android Adreno support.
- **Processes**: Interactive process list with "Kill" functionality.

### 🔌 Modes
1.  **CLI**: `./system_monitor.sh` (Standard)
2.  **TUI**: `./system_monitor.sh -d` (Dialog)
3.  **GUI**: `./system_monitor.sh -w` (Zenity)
4.  **Task Manager**: `./system_monitor.sh -y` (YAD)

---

### 📦 Quick Start (Web Dashboard)
To run the new React dashboard:

```bash
# 1. Generate Data
./generate_json.sh

# 2. Start Server
cd dashboard
npm install
npm run dev
```

---
*Created for OS Course Project (Term 5)*



