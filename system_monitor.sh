#!/usr/bin/env bash
#
# system_monitor.sh
# A pure-bash system monitor (simple "task manager") for Linux / WSL / Termux.

set -u

# Modes:
# - default: CLI menu
# - --dialog / -d : dialog-based menu (requires dialog/whiptail)
# - --window / -w : windowed popups via zenity (requires zenity)

#######################################
# Helper: check if a command exists
#######################################
have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# SECTION: CPU
#######################################
show_cpu_info() {
    echo "========== CPU INFO =========="
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
    echo "========== CPU USAGE =========="
    if have_cmd mpstat; then
        # Per-CPU stats snapshot (single sample)
        mpstat -P ALL 1 1
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
    echo "========== MEMORY INFO =========="
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
    echo "========== DISK USAGE =========="
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
    echo "========== TOP PROCESSES (by CPU) =========="
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
    echo "========== GPU INFO =========="

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
            6 "Show everything (one-shot)" \
            0 "Exit" \
            2>/dev/null) || return
        case "$choice" in
            1) zenity_live_loop "CPU (info + usage + temps)" "cpu_view" ;;
            2) zenity_live_loop "Memory info" "mem_view" ;;
            3) zenity_live_loop "Disk usage" "disk_view" ;;
            4) zenity_live_loop "Top processes" "top_view" ;;
            5) zenity_live_loop "GPU info" "gpu_view" ;;
            6)
                local buf
                buf="$(cpu_view; mem_view; disk_view; top_view; gpu_view)"
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
        choice=$("$DIALOG_CMD" --clear --backtitle "System Monitor" --title "Menu" --menu "Select:" 15 60 7 \
            1 "CPU (info + usage + temps)" \
            2 "Memory info" \
            3 "Disk usage" \
            4 "Top processes" \
            5 "GPU info" \
            6 "Show everything (one-shot)" \
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
            6)
                local buf
                buf="$(cpu_view; mem_view; disk_view; top_view; gpu_view)"
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
        echo "6) Show everything (one-shot)"
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
            6)
                show_cpu_info
                show_cpu_usage
                show_memory_info
                show_disk_info
                show_top_processes
                show_gpu_info
                echo
                echo "Press Enter to return to menu..."
                read -r _
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


