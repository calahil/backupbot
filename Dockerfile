FROM ghcr.io/linuxserver/duplicati:2.1.0

# Install Docker CLI + bash + core utilities
RUN apt-get -y update \
  && apt-get -y --no-install-recommends install \
  cron \
  bash \
  ca-certificates \
  curl \
  docker-ce-cli \
  postrgres17 \
  && mkdir -p /backups \
  && rm -rf /var/lib/apt/lists/*

# Copy backup script
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

COPY backup.cron /etc/cron.d/backup
RUN chmod 0644 /etc/cron.d/backup \
  && crontab /etc/cron.d/backup


COPY startup.sh /usr/local/bin/startup.sh 
RUN chmod +x /usr/local/bin/startup.sh

# Use bash as default
ENTRYPOINT ["/usr/local/bin/startup.sh"]

