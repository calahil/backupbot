# Use LinuxServer.io Duplicati base
FROM linuxserver/duplicati:2.1.0

# Install Docker CLI, bash, python3
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash \
  python3 \
  python3-pip \
  docker.io \
  btrfs-progs \
  ca-certificates curl && \
  rm -rf /var/lib/apt/lists/*

# Create directories for backup scripts and logs
RUN mkdir -p /usr/local/bin /config/log /config/web /etc/services.d/backupbot

# Copy backup script
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Copy the environment variables for the config
COPY backupbot.env /defaults/backupbot.env

# Copy s6 service for backupbot
COPY services/backupbot/run /etc/services.d/backupbot/run
RUN chmod +x /etc/services.d/backupbot/run

# Copy web frontend
COPY web /defaults/web
RUN chmod +x /defaults/web/backupbot.cgi
# Expose web frontend port
EXPOSE 8080

# Keep duplicati entrypoint
ENTRYPOINT ["/init"]
