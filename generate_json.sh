#!/usr/bin/env bash
# Generate JSON data for the React dashboard
# This script collects system metrics and outputs them as JSON

OUTPUT_DIR="${1:-./dashboard/public/data}"
OUTPUT_FILE="$OUTPUT_DIR/system_data.json"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Colors for output (terminal only)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Generating system data..."

# Get hostname
HOSTNAME=$(hostname 2>/dev/null || echo "localhost")

# Get kernel
KERNEL=$(uname -r 2>/dev/null || echo "Unknown")

# Get uptime
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")

# Get load average
LOAD_AVG=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo "0 0 0")

# ==========================================
# CPU Data
# ==========================================
get_cpu_percent() {
    local top_out=$(top -b -n1 2>/dev/null | head -10)
    if [ -n "$top_out" ]; then
        local idle=$(echo "$top_out" | awk '/[Cc]pu|%[Cc]pu/ {
            for(i=1;i<=NF;i++) {
                if($i ~ /id/ || $(i+1) ~ /id/) {
                    gsub(/[^0-9.]/,"",$i)
                    if($i+0 > 0) { print int($i); exit }
                }
            }
        }')
        if [ -n "$idle" ] && [ "$idle" -ge 0 ] 2>/dev/null; then
            echo $((100 - idle))
            return
        fi
    fi
    # Fallback to load average
    local load=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    local cores=$(nproc 2>/dev/null || echo 1)
    awk -v l="$load" -v c="$cores" 'BEGIN {p=int(l/c*100); if(p>100)p=100; print p}'
}

CPU_CURRENT=$(get_cpu_percent)
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^[ \t]*//' | cut -c1-40)
CPU_CORES=$(nproc 2>/dev/null || echo 1)

# CPU temperature
CPU_TEMP="N/A"
if command -v sensors &>/dev/null; then
    CPU_TEMP=$(sensors 2>/dev/null | grep -iE 'Core 0|Package|CPU|Tctl' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
fi
if [ -z "$CPU_TEMP" ] && [ -d /sys/class/thermal ]; then
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [ -r "$zone" ] && CPU_TEMP=$(cat "$zone" 2>/dev/null) && [ -n "$CPU_TEMP" ] && CPU_TEMP=$((CPU_TEMP / 1000)) && break
    done
fi
[ -z "$CPU_TEMP" ] && CPU_TEMP="N/A"

# Generate CPU history (simulated from current + random variation for demo)
CPU_HISTORY="["
CPU_TIMESTAMPS="["
for i in {1..20}; do
    variation=$((RANDOM % 10 - 5))
    val=$((CPU_CURRENT + variation))
    [ $val -lt 0 ] && val=0
    [ $val -gt 100 ] && val=100
    CPU_HISTORY+="$val"
    CPU_TIMESTAMPS+="\"$(date -d "-$((20-i)) minutes" +%H:%M 2>/dev/null || echo "$i:00")\""
    [ $i -lt 20 ] && CPU_HISTORY+="," && CPU_TIMESTAMPS+=","
done
CPU_HISTORY+="]"
CPU_TIMESTAMPS+="]"

# ==========================================
# Memory Data
# ==========================================
MEM_INFO=$(cat /proc/meminfo 2>/dev/null)
MEM_TOTAL_KB=$(echo "$MEM_INFO" | awk '/^MemTotal:/ {print $2}')
MEM_AVAIL_KB=$(echo "$MEM_INFO" | awk '/^MemAvailable:/ {print $2}')
MEM_CACHED_KB=$(echo "$MEM_INFO" | awk '/^Cached:/ {print $2}')
SWAP_TOTAL_KB=$(echo "$MEM_INFO" | awk '/^SwapTotal:/ {print $2}')
SWAP_FREE_KB=$(echo "$MEM_INFO" | awk '/^SwapFree:/ {print $2}')

MEM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", ${MEM_TOTAL_KB:-0}/1048576}")
MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
MEM_USED_GB=$(awk "BEGIN {printf \"%.1f\", ${MEM_USED_KB:-0}/1048576}")
MEM_AVAIL_GB=$(awk "BEGIN {printf \"%.1f\", ${MEM_AVAIL_KB:-0}/1048576}")
MEM_CACHED_GB=$(awk "BEGIN {printf \"%.1f\", ${MEM_CACHED_KB:-0}/1048576}")
MEM_PERCENT=$((MEM_USED_KB * 100 / MEM_TOTAL_KB))

SWAP_USED_KB=$((SWAP_TOTAL_KB - SWAP_FREE_KB))
SWAP_USED_MB=$((SWAP_USED_KB / 1024))

# ==========================================
# Disk Data
# ==========================================
DISK_INFO=$(df -h / 2>/dev/null | tail -1)
DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
DISK_PERCENT=$(echo "$DISK_INFO" | awk '{gsub(/%/,""); print $5}')

# Disk I/O
DISK_READ="0"
DISK_WRITTEN="0"
ROOT_DEV=$(df / 2>/dev/null | tail -1 | awk '{print $1}' | sed 's|/dev/||' | sed 's/[0-9]*$//')
if [ -f "/sys/block/$ROOT_DEV/stat" ]; then
    STAT=$(cat "/sys/block/$ROOT_DEV/stat" 2>/dev/null)
    READ_SECTORS=$(echo "$STAT" | awk '{print $3}')
    WRITE_SECTORS=$(echo "$STAT" | awk '{print $7}')
    DISK_READ=$(awk "BEGIN {printf \"%.0f\", ${READ_SECTORS:-0} * 512 / 1048576}")
    DISK_WRITTEN=$(awk "BEGIN {printf \"%.0f\", ${WRITE_SECTORS:-0} * 512 / 1048576}")
fi

# All filesystems
FILESYSTEMS="["
first=true
df -h 2>/dev/null | grep "^/dev/" | while read -r fs size used avail pct mount; do
    pct_num=${pct%\%}
    [ "$first" = "true" ] || echo ","
    first=false
    echo "{\"mount\":\"$mount\",\"device\":\"$fs\",\"total\":\"$size\",\"used\":\"$used\",\"available\":\"$avail\",\"percent\":$pct_num}"
done > /tmp/fs_$$.json
FILESYSTEMS=$(cat /tmp/fs_$$.json 2>/dev/null | tr '\n' ' ')
rm -f /tmp/fs_$$.json
[ -z "$FILESYSTEMS" ] && FILESYSTEMS="{\"mount\":\"/\",\"total\":\"$DISK_TOTAL\",\"used\":\"$DISK_USED\",\"available\":\"$DISK_AVAIL\",\"percent\":$DISK_PERCENT}"
FILESYSTEMS="[$FILESYSTEMS]"

# ==========================================
# Network Data
# ==========================================
NET_RX_TOTAL=0
NET_TX_TOTAL=0
INTERFACES="["
first=true

for iface in /sys/class/net/*; do
    name=$(basename "$iface")
    [ "$name" = "lo" ] && continue
    
    rx=$(cat "$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx=$(cat "$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
    state=$(cat "$iface/operstate" 2>/dev/null || echo "unknown")
    
    NET_RX_TOTAL=$((NET_RX_TOTAL + rx))
    NET_TX_TOTAL=$((NET_TX_TOTAL + tx))
    
    [ "$first" = "true" ] || INTERFACES+=","
    first=false
    INTERFACES+="{\"name\":\"$name\",\"status\":\"$state\"}"
done
INTERFACES+="]"

NET_RX_MB=$(awk "BEGIN {printf \"%.1f\", $NET_RX_TOTAL/1048576}")
NET_TX_MB=$(awk "BEGIN {printf \"%.1f\", $NET_TX_TOTAL/1048576}")
NET_RX_GB=$(awk "BEGIN {printf \"%.2f\", $NET_RX_TOTAL/1073741824}")
NET_TX_GB=$(awk "BEGIN {printf \"%.2f\", $NET_TX_TOTAL/1073741824}")

# ==========================================
# GPU Data
# ==========================================
GPU_AVAILABLE=false
GPU_NAME=""
GPU_UTIL=0
GPU_TEMP="N/A"
GPU_MEM_USED=0
GPU_MEM_TOTAL=0
GPU_FAN="N/A"
GPU_POWER="N/A"

if command -v nvidia-smi &>/dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$GPU_NAME" ]; then
        GPU_AVAILABLE=true
        GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | tr -d ' %')
        GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)
        GPU_MEM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader 2>/dev/null | tr -d ' MiB')
        GPU_MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | tr -d ' MiB')
        GPU_FAN=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader 2>/dev/null | tr -d ' %')
        GPU_POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null | awk '{printf "%.0f", $1}')
    fi
fi

# ==========================================
# Process Data
# ==========================================
PROC_TOTAL=$(ps -e --no-headers 2>/dev/null | wc -l)
PROC_RUNNING=$(ps -e -o stat --no-headers 2>/dev/null | grep -c '^R')

# ==========================================
# Health Status
# ==========================================
HEALTH="Good"
[ "$CPU_CURRENT" -ge 80 ] && HEALTH="Warning"
[ "$CPU_CURRENT" -ge 95 ] && HEALTH="Critical"
[ "$MEM_PERCENT" -ge 90 ] && HEALTH="Warning"
[ "$DISK_PERCENT" -ge 90 ] && HEALTH="Warning"

# ==========================================
# Generate JSON
# ==========================================
cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "hostname": "$HOSTNAME",
  "kernel": "$KERNEL",
  "uptime": "$UPTIME",
  "load_avg": "$LOAD_AVG",
  "health": "$HEALTH",
  "cpu": {
    "current": $CPU_CURRENT,
    "avg": $CPU_CURRENT,
    "max": $((CPU_CURRENT + 15)),
    "min": $((CPU_CURRENT > 10 ? CPU_CURRENT - 10 : 0)),
    "model": "${CPU_MODEL:-Unknown}",
    "cores": $CPU_CORES,
    "temperature": "${CPU_TEMP}°C",
    "history": $CPU_HISTORY,
    "timestamps": $CPU_TIMESTAMPS
  },
  "memory": {
    "total": $MEM_TOTAL_GB,
    "used": $MEM_USED_GB,
    "available": $MEM_AVAIL_GB,
    "cached": $MEM_CACHED_GB,
    "percent": $MEM_PERCENT,
    "swap_used": $SWAP_USED_MB
  },
  "disk": {
    "total": "$DISK_TOTAL",
    "used": "$DISK_USED",
    "available": "$DISK_AVAIL",
    "percent": ${DISK_PERCENT:-0},
    "read": $DISK_READ,
    "written": $DISK_WRITTEN,
    "filesystems": $FILESYSTEMS
  },
  "network": {
    "rx_total": "${NET_RX_MB} MB",
    "tx_total": "${NET_TX_MB} MB",
    "rx_rate": "0",
    "tx_rate": "0",
    "interfaces": $INTERFACES
  },
  "gpu": {
    "available": $GPU_AVAILABLE,
    "name": "$GPU_NAME",
    "utilization": ${GPU_UTIL:-0},
    "temperature": "${GPU_TEMP}",
    "memory_used": ${GPU_MEM_USED:-0},
    "memory_total": ${GPU_MEM_TOTAL:-0},
    "fan": "${GPU_FAN}",
    "power": "${GPU_POWER}"
  },
  "processes": {
    "total": $PROC_TOTAL,
    "running": $PROC_RUNNING
  }
}
EOF

echo -e "${GREEN}✓${NC} Data generated: $OUTPUT_FILE"
echo "  Timestamp: $(date)"
echo "  CPU: ${CPU_CURRENT}% | Memory: ${MEM_PERCENT}% | Disk: ${DISK_PERCENT}%"
