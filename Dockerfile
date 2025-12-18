# ==========================================
# System Monitor Dashboard - Docker Setup
# ==========================================
# Runs BOTH web dashboard AND system_monitor.sh

# Stage 1: Build React Dashboard
FROM node:20-alpine AS dashboard-builder

WORKDIR /app/dashboard

COPY dashboard/package*.json ./
RUN npm ci --silent

COPY dashboard/ ./
RUN npm run build

# Stage 2: Production Image with Full Support
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install ALL dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        procps \
        sysstat \
        lm-sensors \
        pciutils \
        curl \
        ca-certificates \
        jq \
        iproute2 \
        net-tools \
        nginx \
        yad \
        zenity \
        dialog \
        x11-apps \
        dbus-x11 \
        libgtk-3-0 \
        fonts-dejavu-core \
        && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy scripts
COPY system_monitor.sh .
COPY generate_json.sh .
COPY docker/start.sh .
RUN chmod +x system_monitor.sh generate_json.sh start.sh

# Copy built dashboard
COPY --from=dashboard-builder /app/dashboard/dist /var/www/html

# Create data directory
RUN mkdir -p /var/www/html/data

# Configure nginx
COPY docker/nginx.conf /etc/nginx/sites-available/default

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["/app/start.sh"]
