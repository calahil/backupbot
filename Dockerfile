# === Dockerfile ===
FROM postgres:17-alpine

# Install Docker CLI + bash + core utilities
RUN apk add --no-cache docker-cli bash coreutils btrfs-prog \
  && mkdir -p /backups

# Copy backup script
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Use bash as default
ENTRYPOINT ["/usr/local/bin/backup.sh"]

