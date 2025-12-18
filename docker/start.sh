#!/bin/bash

echo ""
echo "=============================================="
echo "   System Monitor - Starting All Services"
echo "=============================================="
echo ""

# Start nginx (web dashboard)
echo "[1/3] Starting web server (nginx)..."
nginx
echo "      Web dashboard: http://localhost:8080"

# Start data generator in background
echo "[2/3] Starting data generator..."
(
    while true; do
        /app/generate_json.sh /var/www/html/data > /dev/null 2>&1
        sleep 3
    done
) &
echo "      Data updates every 3 seconds"

echo "[3/3] Starting System Monitor CLI..."
echo ""
echo "=============================================="
echo "   Both services are now running!"
echo "   - Web Dashboard: http://localhost:8080"
echo "   - CLI Menu: Below"
echo "=============================================="
echo ""

# Run system_monitor.sh in foreground (interactive)
exec bash /app/system_monitor.sh
