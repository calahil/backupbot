FROM ghcr.io/linuxserver/duplicati:2.1.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  && rm -rf /var/lib/apt/lists/* \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
  && chmod a+r /etc/apt/keyrings/docker.asc \
  && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update -y

RUN install -d /usr/share/postgresql-common/pgdg \
  && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  && . /etc/os-release \
  && sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list" \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
  cron \
  bash \
  ca-certificates \
  curl \
  docker-ce-cli \
  postgresql-17 \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /backups

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

