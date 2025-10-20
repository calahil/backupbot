# === Dockerfile ===
FROM ghcr.io/linuxserver/duplicati:2.1.0

# Remove old docker
RUN for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
# Install Docker CLI + bash + core utilities
RUN apt-get update \
  && apt-get install ca-certificates curl \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
  && chmod a+r /etc/apt/keyrings/docker.asc \
  && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update



RUN apt-get -y install docker-ce docker-ce-cli \
  && containerd.io docker-buildx-plugin docker-compose-plugin postrgres17 \
  && mkdir -p /backups

# Copy backup script
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Use bash as default
ENTRYPOINT ["/usr/local/bin/backup.sh"]

