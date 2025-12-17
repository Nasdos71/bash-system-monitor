#!/usr/bin/env bash
# Report generator script - parses monitor.log and generates HTML report

LOG_FILE="${1:-monitor.log}"
OUTPUT_FILE="${2:-system_report.html}"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    exit 1
fi

echo "Parsing log file: $LOG_FILE"

# Extract CPU usage data (handle both formats)
# Format 1: "CPU usage: X%"
# Format 2: "Overall CPU usage:" followed by progress bar "[]  X%"
CPU_DATA_SIMPLE=$(grep "^CPU usage:" "$LOG_FILE" | awk '{print $3}' | tr -d '%' | head -n 100)
CPU_DATA_FULL=$(grep -A 1 "Overall CPU usage:" "$LOG_FILE" | grep -oP '\]\s+\K\d+' | head -n 100)

# Combine both (prefer full format if available, otherwise simple)
if [ -n "$CPU_DATA_FULL" ] && [ "$(echo "$CPU_DATA_FULL" | wc -l)" -gt 5 ]; then
    CPU_DATA="$CPU_DATA_FULL"
elif [ -n "$CPU_DATA_SIMPLE" ]; then
    CPU_DATA="$CPU_DATA_SIMPLE"
else
    CPU_DATA=""
fi

# Extract timestamps (handle both formats)
TIMESTAMPS_SIMPLE=$(grep "^Timestamp:" "$LOG_FILE" | awk '{print $2, $3}' | head -n 100)
TIMESTAMPS_FULL=$(grep "^TIMESTAMP:" "$LOG_FILE" | awk '{print $2, $3}' | head -n 100)

if [ -n "$TIMESTAMPS_FULL" ] && [ "$(echo "$TIMESTAMPS_FULL" | wc -l)" -gt 5 ]; then
    TIMESTAMPS="$TIMESTAMPS_FULL"
elif [ -n "$TIMESTAMPS_SIMPLE" ]; then
    TIMESTAMPS="$TIMESTAMPS_SIMPLE"
else
    TIMESTAMPS=""
fi

# Extract GPU temperature data (nvidia-smi format: "| 30%   36C    P0 ...")
GPU_TEMPS=$(grep -oP '^\|\s+\d+%\s+\K\d+(?=C)' "$LOG_FILE" | head -n 100)

# Extract Memory data
MEM_USED=$(grep "Used.*Gi$" "$LOG_FILE" | head -n 100 | awk '{print $2}' | tr -d 'Mi' | awk '{sum+=$1; count++} END {if(count>0) printf "%.0f", sum/count}')

# Count data points
DATA_COUNT=$(echo "$CPU_DATA" | grep -c '^' 2>/dev/null || echo "0")
echo "Found $DATA_COUNT CPU data points"

# Calculate CPU statistics
if [ -n "$CPU_DATA" ] && [ "$DATA_COUNT" -gt 0 ]; then
    CPU_AVG=$(echo "$CPU_DATA" | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
    CPU_MAX=$(echo "$CPU_DATA" | sort -n | tail -1)
    CPU_MIN=$(echo "$CPU_DATA" | sort -n | head -1)
    
    # Determine health status
    CPU_AVG_INT=${CPU_AVG%.*}
    if [ "${CPU_AVG_INT:-0}" -ge 80 ]; then
        HEALTH_BADGE='<span class="badge badge-danger">⚠️ High</span>'
    elif [ "${CPU_AVG_INT:-0}" -ge 60 ]; then
        HEALTH_BADGE='<span class="badge badge-warning">⚡ Moderate</span>'
    else
        HEALTH_BADGE='<span class="badge badge-success">✓ Good</span>'
    fi
else
    CPU_AVG="0"
    CPU_MAX="0"
    CPU_MIN="0"
    HEALTH_BADGE='<span class="badge badge-warning">No Data</span>'
fi

# Calculate GPU temperature statistics if available
if [ -n "$GPU_TEMPS" ]; then
    GPU_COUNT=$(echo "$GPU_TEMPS" | grep -c '^')
    GPU_AVG=$(echo "$GPU_TEMPS" | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "N/A"}')
    GPU_MAX=$(echo "$GPU_TEMPS" | sort -n | tail -1)
else
    GPU_AVG="N/A"
    GPU_MAX="N/A"
    GPU_COUNT=0
fi

# Format data for JavaScript (create arrays)
if [ -n "$CPU_DATA" ]; then
    CPU_ARRAY=$(echo "$CPU_DATA" | awk '{printf "%s,", $1}' | sed 's/,$//')
else
    CPU_ARRAY="0"
fi

if [ -n "$TIMESTAMPS" ]; then
    TIME_ARRAY=$(echo "$TIMESTAMPS" | awk '{printf "\"%s\",", $2}' | sed 's/,$//')
else
    TIME_ARRAY='"No data"'
fi

# GPU temperature array for chart
if [ -n "$GPU_TEMPS" ]; then
    GPU_TEMP_ARRAY=$(echo "$GPU_TEMPS" | awk '{printf "%s,", $1}' | sed 's/,$//')
else
    GPU_TEMP_ARRAY="0"
fi

# Calculate monitoring duration
FIRST_TIME=$(echo "$TIMESTAMPS" | head -1)
LAST_TIME=$(echo "$TIMESTAMPS" | tail -1)
if [ -n "$FIRST_TIME" ] && [ -n "$LAST_TIME" ] && [ "$FIRST_TIME" != "$LAST_TIME" ]; then
    DURATION="$FIRST_TIME to $LAST_TIME"
else
    DURATION="Single snapshot"
fi

# Generate HTML report
cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Monitor Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        .header {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
            font-weight: 700;
        }
        .timestamp {
            color: #666;
            font-size: 1.1em;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.3);
        }
        .card-title {
            font-size: 1.4em;
            font-weight: 600;
            color: #333;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .icon {
            width: 30px;
            height: 30px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        .stat-group {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-top: 15px;
        }
        .stat {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .stat-label {
            font-size: 0.85em;
            color: #666;
            margin-bottom: 5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .stat-value {
            font-size: 1.8em;
            font-weight: 700;
            color: #333;
        }
        .stat-unit {
            font-size: 0.6em;
            color: #666;
            font-weight: 400;
        }
        canvas {
            max-height: 300px;
        }
        .badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
            margin-left: 10px;
        }
        .badge-success { background: #d4edda; color: #155724; }
        .badge-warning { background: #fff3cd; color: #856404; }
        .badge-danger { background: #f8d7da; color: #721c24; }
        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            font-size: 0.9em;
        }
        .chart-card {
            grid-column: span 2;
        }
        @media (max-width: 900px) {
            .chart-card {
                grid-column: span 1;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 System Monitor Report</h1>
            <div class="timestamp">Generated: <strong>REPORT_TIME</strong></div>
            <div class="timestamp">Data Points: <strong>DATA_POINTS</strong> samples</div>
            <div class="timestamp">Period: <strong>MONITOR_DURATION</strong></div>
        </div>

        <div class="grid">
            <div class="card chart-card">
                <div class="card-title">
                    <div class="icon">📈</div>
                    CPU Usage Over Time
                </div>
                <canvas id="cpuChart"></canvas>
            </div>
        </div>

        GPU_CHART_SECTION

        <div class="grid">
            <div class="card">
                <div class="card-title">
                    <div class="icon">💻</div>
                    CPU Statistics
                </div>
                <div class="stat-group">
                    <div class="stat">
                        <div class="stat-label">Average Usage</div>
                        <div class="stat-value">CPU_AVG<span class="stat-unit">%</span></div>
                    </div>
                    <div class="stat">
                        <div class="stat-label">Peak Usage</div>
                        <div class="stat-value">CPU_MAX<span class="stat-unit">%</span></div>
                    </div>
                    <div class="stat">
                        <div class="stat-label">Minimum Usage</div>
                        <div class="stat-value">CPU_MIN<span class="stat-unit">%</span></div>
                    </div>
                    <div class="stat">
                        <div class="stat-label">Health Status</div>
                        <div class="stat-value" style="font-size: 1.3em;">HEALTH_BADGE</div>
                    </div>
                </div>
            </div>

            GPU_STATS_SECTION

            <div class="card">
                <div class="card-title">
                    <div class="icon">🎯</div>
                    System Information
                </div>
                <div class="stat-group">
                    <div class="stat">
                        <div class="stat-label">Monitoring Period</div>
                        <div class="stat-value" style="font-size: 0.9em;">MONITOR_DURATION</div>
                    </div>
                    <div class="stat">
                        <div class="stat-label">Samples Collected</div>
                        <div class="stat-value">DATA_POINTS</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>Generated by Bash System Monitor | Data source: LOG_FILE_NAME</p>
        </div>
    </div>

    <script>
        const cpuData = [CPU_DATA_ARRAY];
        const timestamps = [TIMESTAMP_ARRAY];
        const gpuTemps = [GPU_TEMP_ARRAY];

        // CPU Chart
        const ctx = document.getElementById('cpuChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: timestamps,
                datasets: [{
                    label: 'CPU Usage (%)',
                    data: cpuData,
                    borderColor: 'rgb(102, 126, 234)',
                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    pointBackgroundColor: 'rgb(102, 126, 234)',
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        labels: {
                            font: { size: 14, weight: '600' },
                            padding: 20
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            callback: function(value) { return value + '%'; }
                        }
                    },
                    x: {
                        ticks: {
                            maxRotation: 45,
                            minRotation: 45
                        }
                    }
                }
            }
        });

        GPU_CHART_SCRIPT
    </script>
</body>
</html>
EOF

# Add GPU section if data available
if [ "$GPU_COUNT" -gt 0 ]; then
    GPU_CHART='<div class="grid">
            <div class="card chart-card">
                <div class="card-title">
                    <div class="icon">🌡️</div>
                    GPU Temperature Over Time
                </div>
                <canvas id="gpuChart"></canvas>
            </div>
        </div>'
    
    GPU_STATS='<div class="card">
                <div class="card-title">
                    <div class="icon">🎮</div>
                    GPU Statistics
                </div>
                <div class="stat-group">
                    <div class="stat" style="grid-column: span 2;">
                        <div class="stat-label">Average Temperature</div>
                        <div class="stat-value">GPU_AVG<span class="stat-unit">°C</span></div>
                    </div>
                    <div class="stat" style="grid-column: span 2;">
                        <div class="stat-label">Peak Temperature</div>
                        <div class="stat-value">GPU_MAX<span class="stat-unit">°C</span></div>
                    </div>
                </div>
            </div>'
    
    GPU_SCRIPT='const gpuCtx = document.getElementById("gpuChart").getContext("2d");
        new Chart(gpuCtx, {
            type: "line",
            data: {
                labels: timestamps,
                datasets: [{
                    label: "GPU Temp (°C)",
                    data: gpuTemps,
                    borderColor: "rgb(244, 67, 54)",
                    backgroundColor: "rgba(244, 67, 54, 0.1)",
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    pointBackgroundColor: "rgb(244, 67, 54)",
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: true,
                        position: "top",
                        labels: {
                            font: { size: 14, weight: "600" },
                            padding: 20
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: false,
                        ticks: {
                            callback: function(value) { return value + "°C"; }
                        }
                    },
                    x: {
                        ticks: {
                            maxRotation: 45,
                            minRotation: 45
                        }
                    }
                }
            }
        });'
else
    GPU_CHART=""
    GPU_STATS=""
    GPU_SCRIPT=""
fi

# Replace placeholders in HTML
sed -i "s|REPORT_TIME|$(date '+%Y-%m-%d %H:%M:%S')|g" "$OUTPUT_FILE"
sed -i "s|DATA_POINTS|$DATA_COUNT|g" "$OUTPUT_FILE"
sed -i "s|CPU_AVG|$CPU_AVG|g" "$OUTPUT_FILE"
sed -i "s|CPU_MAX|$CPU_MAX|g" "$OUTPUT_FILE"
sed -i "s|CPU_MIN|$CPU_MIN|g" "$OUTPUT_FILE"
sed -i "s|HEALTH_BADGE|$HEALTH_BADGE|g" "$OUTPUT_FILE"
sed -i "s|CPU_DATA_ARRAY|$CPU_ARRAY|g" "$OUTPUT_FILE"
sed -i "s|TIMESTAMP_ARRAY|$TIME_ARRAY|g" "$OUTPUT_FILE"
sed -i "s|GPU_TEMP_ARRAY|$GPU_TEMP_ARRAY|g" "$OUTPUT_FILE"
sed -i "s|GPU_AVG|$GPU_AVG|g" "$OUTPUT_FILE"
sed -i "s|GPU_MAX|$GPU_MAX|g" "$OUTPUT_FILE"
sed -i "s|MONITOR_DURATION|$DURATION|g" "$OUTPUT_FILE"
sed -i "s|LOG_FILE_NAME|$(basename "$LOG_FILE")|g" "$OUTPUT_FILE"
sed -i "s|GPU_CHART_SECTION|$GPU_CHART|g" "$OUTPUT_FILE"
sed -i "s|GPU_STATS_SECTION|$GPU_STATS|g" "$OUTPUT_FILE"
sed -i "s|GPU_CHART_SCRIPT|$GPU_SCRIPT|g" "$OUTPUT_FILE"

echo "✓ Report generated successfully: $OUTPUT_FILE"
echo "  CPU data points: $DATA_COUNT"
echo "  GPU temp points: $GPU_COUNT"
echo "  Open in browser: file://$(pwd)/$OUTPUT_FILE"
