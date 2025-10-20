FROM ghcr.io/linuxserver/duplicati:2.1.0

apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update


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

