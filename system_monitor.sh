#!/usr/bin/env bash
#
# system_monitor.sh
# A pure-bash system monitor (simple "task manager") for Linux / WSL / Termux.

# set -u  # Disabled to avoid "unbound variable" errors with optional features

# Modes:
# - default: CLI menu
# - --dialog / -d : dialog-based menu (requires dialog/whiptail)
# - --window / -w : windowed popups via zenity (requires zenity)

# Initialize colors and other globals
init_colors

#######################################
# Helper: check if a command exists
#######################################
have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Helper: colors (fallback-safe)
#######################################
init_colors() {
    if [ -t 1 ] && have_cmd tput; then
        local ncolors
        ncolors=$(tput colors 2>/dev/null || echo 0)
        if [ "$ncolors" -ge 8 ]; then
            C_RESET=$(tput sgr0)
            C_BOLD=$(tput bold)
            C_RED=$(tput setaf 1)
            C_GREEN=$(tput setaf 2)
            C_YELLOW=$(tput setaf 3)
            C_BLUE=$(tput setaf 4)
            C_MAGENTA=$(tput setaf 5)
            C_CYAN=$(tput setaf 6)
        fi
    fi
    : "${C_RESET:=}"
    : "${C_BOLD:=}"
    : "${C_RED:=}"
    : "${C_GREEN:=}"
    : "${C_YELLOW:=}"
    : "${C_BLUE:=}"
    : "${C_MAGENTA:=}"
    : "${C_CYAN:=}"
}

#######################################
# Helper: simple bar graph
#######################################
draw_bar() {
    # $1 = percentage (0-100), $2 = width
    local pct=${1%.*}
    local width=${2:-20}
    if [ -z "$pct" ] || [ "$pct" -lt 0 ] 2>/dev/null; then
        pct=0
    fi
    if [ "$pct" -gt 100 ] 2>/dev/null; then
        pct=100
    fi
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    printf "["
    printf "%${filled}s" "" | tr " " "#"
    printf "%${empty}s" "" | tr " " "-"
    printf "] %s%%\n" "$pct"
}

cpu_usage_percent() {
    if have_cmd mpstat; then
        mpstat 1 1 | awk '/all/ {print 100 - $NF; exit}'
    else
        # Fallback using top
        top -b -n1 | awk '/Cpu\(s\)/ {print $2+$4+$6; exit}'
    fi
}

#######################################
# SECTION: CPU
#######################################
show_cpu_info() {
    echo "${C_BOLD}${C_CYAN}========== CPU INFO ==========${C_RESET}"
    # Basic CPU model
    if [ -r /proc/cpuinfo ]; then
        echo "Model name:"
        grep -m1 "model name" /proc/cpuinfo | cut -d: -f2- | sed 's/^[ \t]*//'
        echo
        echo "Cores (logical / physical estimate):"
        LOGICAL=$(grep -c "^processor" /proc/cpuinfo || echo "?")
        PHYSICAL=$(grep "cpu cores" /proc/cpuinfo | head -n1 | awk -F: '{gsub(/ /, "", $2); print $2}' 2>/dev/null)
        echo "  Logical:  $LOGICAL"
        [ -n "${PHYSICAL:-}" ] && echo "  Physical cores per socket (from cpuinfo): $PHYSICAL"
        echo
    fi

    echo "Load averages (1m, 5m, 15m):"
    uptime
    echo

    show_cpu_temps
}

show_cpu_usage() {
    echo "${C_BOLD}${C_CYAN}========== CPU USAGE ==========${C_RESET}"
    if have_cmd mpstat; then
        # Per-CPU stats snapshot (single sample)
        mpstat -P ALL 1 1
        local pct
        pct=$(cpu_usage_percent 2>/dev/null || echo "")
        if [ -n "$pct" ]; then
            echo
            echo "Overall CPU usage:"
            draw_bar "$pct" 30
            local pct_int=${pct%.*}
            if [ "${pct_int:-0}" -ge 90 ] 2>/dev/null; then
                echo "${C_RED}${C_BOLD}WARNING:${C_RESET} CPU usage is very high!"
            elif [ "${pct_int:-0}" -ge 70 ] 2>/dev/null; then
                echo "${C_YELLOW}Notice:${C_RESET} CPU usage is elevated."
            fi
        fi
    else
        echo "mpstat not found (install package 'sysstat' for detailed per-CPU stats)."
        echo "Falling back to 'top' (batch mode snapshot)."
        echo
        top -b -n1 | head -n 15
    fi
    echo
}

#######################################
# SECTION: CPU TEMPERATURE
# Tries sensors, falls back to /sys/class/thermal if possible.
#######################################
show_cpu_temps() {
    echo "CPU temperature:"

    if have_cmd sensors; then
        # Prefer common CPU-related lines
        local out
        out="$(sensors 2>/dev/null | grep -Ei 'cpu|package id|core [0-9]+|tctl|tccd' || true)"
        if [ -n "$out" ]; then
            echo "$out"
            echo
            return
        fi
    fi

    # Fallback: check thermal zones for CPU-like labels
    local found=0
    if [ -d /sys/class/thermal ]; then
        for z in /sys/class/thermal/thermal_zone*; do
            [ -e "$z/type" ] || continue
            typ=$(cat "$z/type" 2>/dev/null)
            if echo "$typ" | grep -Eqi 'cpu|x86_pkg_temp|acpitz'; then
                if [ -e "$z/temp" ]; then
                    raw=$(cat "$z/temp" 2>/dev/null)
                    # Many systems report millidegrees C
                    if [ -n "$raw" ]; then
                        if [ "$raw" -gt 1000 ] 2>/dev/null; then
                            printf "%s: %.1f°C\n" "$typ" "$(awk "BEGIN {print $raw/1000}")"
                        else
                            printf "%s: %s°C\n" "$typ" "$raw"
                        fi
                        found=1
                    fi
                fi
            fi
        done
    fi

    if [ "$found" -eq 0 ]; then
        echo "CPU temperature not available (need 'lm-sensors' or thermal sysfs)."
    fi
    echo
}

#######################################
# SECTION: MEMORY
#######################################
show_memory_info() {
    echo "${C_BOLD}${C_MAGENTA}========== MEMORY INFO ==========${C_RESET}"
    if have_cmd free; then
        free -h
    else
        echo "'free' command not available."
    fi
    echo
}

#######################################
# SECTION: DISK
#######################################
show_disk_info() {
    echo "${C_BOLD}${C_BLUE}========== DISK USAGE ==========${C_RESET}"
    if have_cmd df; then
        df -h
    else
        echo "'df' command not available."
    fi
    echo
}

#######################################
# SECTION: PROCESSES
#######################################
show_top_processes() {
    echo "${C_BOLD}${C_YELLOW}========== TOP PROCESSES (by CPU) ==========${C_RESET}"
    if have_cmd ps; then
        ps -eo pid,ppid,user,%cpu,%mem,command --sort=-%cpu | head -n 15
    else
        echo "'ps' command not available."
    fi
    echo
}

#######################################
# SECTION: GPU
# Notes:
# - On NVIDIA: use nvidia-smi for info/usage/temp.
# - On generic systems: try lspci + /sys/class/drm + sensors.
# - On WSL or Android/Termux, some of these may not exist.
#######################################
show_gpu_info() {
    echo "${C_BOLD}${C_GREEN}========== GPU INFO ==========${C_RESET}"

    if have_cmd nvidia-smi; then
        echo "Detected NVIDIA GPU via nvidia-smi."
        echo
        # Basic info
        echo "--- Basic GPU Info ---"
        nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu --format=csv,noheader || \
            echo "nvidia-smi query failed."
        echo
        echo "--- Full nvidia-smi output (short) ---"
        nvidia-smi | head -n 20
        echo
        return
    fi

    # Try to detect GPUs via lspci if available
    if have_cmd lspci; then
        echo "--- PCI GPU Devices (lspci | grep -i 'vga\\|3d\\|display') ---"
        lspci | grep -Ei 'vga|3d|display' || echo "No PCI GPU devices found by lspci."
        echo
    else
        echo "lspci not available; cannot list PCI GPU devices."
        echo
    fi

    # Attempt to read basic DRM info
    if [ -d /sys/class/drm ]; then
        echo "--- /sys/class/drm devices ---"
        ls -1 /sys/class/drm
        echo
    fi

    # Temperatures via sensors (if available)
    if have_cmd sensors; then
        echo "--- Sensors (temperatures) ---"
        sensors | grep -i "gpu\\|vga\\|temp" || sensors
        echo
    else
        echo "sensors command not available (install 'lm-sensors' for detailed temps)."
        echo
    fi

    echo "Note: GPU usage & temperature support depends heavily on hardware and installed tools."
    echo "On WSL / Android (Termux) this may be limited or unavailable."
    echo
}

#######################################
# SECTION: NETWORK
#######################################
show_network_info() {
    echo "${C_BOLD}${C_BLUE}========== NETWORK ==========${C_RESET}"
    if [ -d /sys/class/net ]; then
        echo "Interfaces (RX/TX bytes):"
        printf "%-10s %-15s %-15s\n" "IFACE" "RX (MB)" "TX (MB)"
        for iface in /sys/class/net/*; do
            iface=$(basename "$iface")
            [ "$iface" = "lo" ] && continue
            rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
            tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
            rx_mb=$(awk "BEGIN {printf \"%.1f\", $rx/1024/1024}")
            tx_mb=$(awk "BEGIN {printf \"%.1f\", $tx/1024/1024}")
            printf "%-10s %-15s %-15s\n" "$iface" "$rx_mb" "$tx_mb"
        done
        echo
    fi

    if have_cmd ip; then
        echo "IP addresses:"
        ip -4 addr show | sed 's/^[ \t]*//'
        echo
    elif have_cmd ifconfig; then
        ifconfig
        echo
    else
        echo "No 'ip' or 'ifconfig' command available."
        echo
    fi
}

#######################################
# SECTION: SYSTEM INFO
#######################################
show_system_info() {
    echo "${C_BOLD}${C_CYAN}========== SYSTEM INFO ==========${C_RESET}"
    echo "Hostname: $(hostname 2>/dev/null || echo '?')"
    echo "Kernel: $(uname -sr 2>/dev/null || echo '?')"
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        echo "Distro: ${NAME:-?} ${VERSION_ID:-}"
    fi
    echo "Uptime:"
    uptime
    echo
    echo "Logged-in users:"
    if have_cmd who; then
        who || echo "none"
    else
        echo "'who' not available."
    fi
    echo
    if [ -d /sys/class/power_supply ]; then
        echo "Power / battery:"
        for bat in /sys/class/power_supply/*; do
            [ -e "$bat/type" ] || continue
            typ=$(cat "$bat/type" 2>/dev/null)
            if echo "$typ" | grep -qi "battery"; then
                echo "Battery: $(basename "$bat")"
                cat "$bat"/{status,capacity} 2>/dev/null || true
                echo
            fi
        done
    fi
}

#######################################
# SECTION: PROCESS SEARCH
#######################################
search_processes() {
    echo "${C_BOLD}${C_YELLOW}========== PROCESS SEARCH ==========${C_RESET}"
    printf "Enter search term (regex allowed): "
    read -r pattern
    if [ -z "${pattern:-}" ]; then
        echo "Empty pattern, returning."
        return
    fi
    if ! have_cmd ps; then
        echo "'ps' not available."
        return
    fi
    echo
    ps -eo pid,ppid,user,%cpu,%mem,command | head -n 1
    ps -eo pid,ppid,user,%cpu,%mem,command | grep -Ei "$pattern" | grep -v "grep -Ei" || echo "No matching processes."
    echo
}

#######################################
# SECTION: LOGGING
#######################################
LOG_FILE="${LOG_FILE:-./monitor.log}"

log_full_snapshot() {
    echo "=========================================="
    echo "TIMESTAMP: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo
    cpu_view
    mem_view
    disk_view
    top_view
    gpu_view
    net_view
    sys_view
    echo
    echo "=========================================="
    echo
}

start_logging() {
    local delay=2
    echo "Logging FULL system snapshots to $LOG_FILE (every ${delay}s)."
    echo "This will capture ALL system information for report generation."
    echo "Press any key to stop logging..."
    echo
    while true; do
        log_full_snapshot >>"$LOG_FILE" 2>&1
        read -r -t "$delay" -n 1 _ && break
    done
    # Clear the input buffer to avoid double prompts
    read -r -t 0.1 _ 2>/dev/null || true
    echo
    echo "Stopped logging. Full log file: $LOG_FILE"
    echo "File size: $(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo '?')"
}

#######################################
# SECTION: REFRESH HELPERS
#######################################
refresh_loop() {
    # $1 is the name of the function to call repeatedly
    local fn="$1"
    local delay=2
    while true; do
        clear
        $fn
        echo
        echo "(Refreshing every ${delay}s. Press any key to return to menu.)"
        read -r -t "$delay" -n 1 _ && break
    done
}

cpu_view() {
    show_cpu_info
    show_cpu_usage
}

mem_view() {
    show_memory_info
}

disk_view() {
    show_disk_info
}

top_view() {
    show_top_processes
}

gpu_view() {
    show_gpu_info
}

net_view() {
    show_network_info
}

sys_view() {
    show_system_info
}

#######################################
# WINDOW MODE (zenity)
#######################################
need_zenity() {
    have_cmd zenity
}

zenity_show_box() {
    local title="$1"
    local content="$2"
    # Use a temp file to avoid process substitution incompatibilities
    local tmp
    tmp=$(mktemp)
    printf "%s\n" "$content" > "$tmp"
    zenity --width=800 --height=600 --text-info --title="$title" --no-wrap --filename="$tmp"
    rm -f "$tmp"
}

zenity_collect_and_show() {
    local title="$1"
    local fn="$2"
    local buf
    buf="$($fn 2>&1)"
    zenity_show_box "$title" "$buf"
}

zenity_live_loop() {
    local title="$1"
    local fn="$2"
    local delay=2
    while true; do
        local buf
        buf="$($fn 2>&1)"
        zenity_show_box "$title" "$buf" --timeout "$delay"
        local status=$?
        # zenity exit codes: 0=OK,1=Cancel,5=timeout
        case "$status" in
            0|1) break ;;
            5) continue ;;
            *) break ;;
        esac
    done
}

window_mode() {
    if ! need_zenity; then
        echo "zenity not installed. Install 'zenity' for windowed mode."
        return
    fi
    while true; do
        local choice
        choice=$(zenity --list --title="System Monitor" --text="Select:" --column="Option" --column="Description" \
            1 "CPU (info + usage + temps)" \
            2 "Memory info" \
            3 "Disk usage" \
            4 "Top processes" \
            5 "GPU info" \
            6 "Network" \
            7 "System info" \
            8 "Show everything (one-shot)" \
            0 "Exit" \
            2>/dev/null) || return
        case "$choice" in
            1) zenity_live_loop "CPU (info + usage + temps)" "cpu_view" ;;
            2) zenity_live_loop "Memory info" "mem_view" ;;
            3) zenity_live_loop "Disk usage" "disk_view" ;;
            4) zenity_live_loop "Top processes" "top_view" ;;
            5) zenity_live_loop "GPU info" "gpu_view" ;;
            6) zenity_live_loop "Network" "net_view" ;;
            7) zenity_live_loop "System info" "sys_view" ;;
            8)
                local buf
                buf="$(cpu_view; mem_view; disk_view; top_view; gpu_view; net_view; sys_view)"
                zenity_show_box "Everything" "$buf"
                ;;
            0) return ;;
        esac
    done
}

#######################################
# DIALOG MODE
#######################################
need_dialog() {
    if have_cmd dialog; then
        DIALOG_CMD=dialog
    elif have_cmd whiptail; then
        DIALOG_CMD=whiptail
    else
        return 1
    fi
    return 0
}

dialog_show_box() {
    local title="$1"
    local content="$2"
    "$DIALOG_CMD" --backtitle "System Monitor" --title "$title" --msgbox "$content" 20 100
}

dialog_collect_and_show() {
    local title="$1"
    local fn="$2"
    local buf
    buf="$($fn 2>&1)"
    dialog_show_box "$title" "$buf"
}

dialog_live_loop() {
    local title="$1"
    local fn="$2"
    local delay=2
    while true; do
        local buf
        buf="$($fn 2>&1)"
        "$DIALOG_CMD" --backtitle "System Monitor" --title "$title" \
            --ok-label "Stop" --timeout "$delay" --msgbox "$buf" 20 100
        local status=$?
        # dialog exit: 0 OK, 1 Cancel, 255 ESC/timeout. We treat OK/Cancel/ESC as stop; timeout continues.
        if [ "$status" -eq 255 ]; then
            continue
        fi
        break
    done
}

dialog_mode() {
    if ! need_dialog; then
        echo "dialog/whiptail not installed. Install 'dialog' and retry."
        return
    fi
    while true; do
        local choice
        choice=$("$DIALOG_CMD" --clear --backtitle "System Monitor" --title "Menu" --menu "Select:" 15 60 9 \
            1 "CPU (info + usage + temps)" \
            2 "Memory info" \
            3 "Disk usage" \
            4 "Top processes" \
            5 "GPU info" \
            6 "Network" \
            7 "System info" \
            8 "Show everything (one-shot)" \
            0 "Exit" \
            2>&1 >/dev/tty)
        [ $? -ne 0 ] && clear && return
        clear
        case "$choice" in
            1) dialog_live_loop "CPU (info + usage + temps)" "cpu_view" ;;
            2) dialog_live_loop "Memory info" "mem_view" ;;
            3) dialog_live_loop "Disk usage" "disk_view" ;;
            4) dialog_live_loop "Top processes" "top_view" ;;
            5) dialog_live_loop "GPU info" "gpu_view" ;;
            6) dialog_live_loop "Network" "net_view" ;;
            7) dialog_live_loop "System info" "sys_view" ;;
            8)
                local buf
                buf="$(cpu_view; mem_view; disk_view; top_view; gpu_view; net_view; sys_view)"
                dialog_show_box "Everything" "$buf"
                ;;
            0) return ;;
        esac
    done
}

#######################################
# MAIN MENU (CLI VERSION)
#######################################
main_menu() {
    while true; do
        echo "==================== SYSTEM MONITOR ===================="
        echo "1) CPU (info + usage)"
        echo "2) Memory info"
        echo "3) Disk usage"
        echo "4) Top processes"
        echo "5) GPU info"
        echo "6) Network"
        echo "7) System info"
        echo "8) Show everything (one-shot)"
        echo "9) Start logging (FULL snapshots -> monitor.log)"
        echo "d) Dialog mode"
        echo "w) Window mode (zenity)"
        echo "0) Exit"
        echo "========================================================"
        printf "Choose an option: "
        read -r choice

        clear
        case "${choice:-}" in
            1) refresh_loop cpu_view ;;
            2) refresh_loop mem_view ;;
            3) refresh_loop disk_view ;;
            4) refresh_loop top_view ;;
            5) refresh_loop gpu_view ;;
            6) refresh_loop net_view ;;
            7) refresh_loop sys_view ;;
            8)
                show_cpu_info
                show_cpu_usage
                show_memory_info
                show_disk_info
                show_top_processes
                show_gpu_info
                show_network_info
                show_system_info
                echo
                echo "Press Enter to return to menu..."
                read -r _
                ;;
            9)
                start_logging
                ;;
            d|D)
                dialog_mode
                ;;
            w|W)
                window_mode
                ;;
            0)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid option."
                ;;
        esac

        echo
        echo "Press Enter to return to menu..."
        read -r _
        clear
    done
}

main_menu


