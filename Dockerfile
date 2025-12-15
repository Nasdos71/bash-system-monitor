FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools required by the monitor script
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        procps \
        sysstat \
        lm-sensors \
        pciutils \
        dialog \
        zenity \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the bash monitor script into the image
COPY system_monitor.sh .

RUN chmod +x system_monitor.sh

# Default command: run the system monitor
CMD ["./system_monitor.sh"]


