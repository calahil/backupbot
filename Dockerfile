FROM linuxserver/duplicati:2.1.0

# Install Docker CLI, bash, python3, btrfs support and all the app directories
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  bash \
  python3 \
  python3-pip \
  btrfs-progs \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg" \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  docker-ce-cli \
  && groupadd -f docker \
  && usermod -aG docker abc \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/local/bin /config /etc/services.d/backupbot

COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Copy the environment variables for backupbot
COPY backupbot.conf /defaults/backupbot.conf
RUN chown www-data:www-data /defaults/backupbot.conf \
  && chmod 644 /defaults/backupbot.conf

# Copy s6 service for backupbot
COPY services/backupbot/run /etc/services.d/backupbot/run
RUN chmod +x /etc/services.d/backupbot/run

# Copy web frontend
COPY web /app
RUN chmod +x /app/cgi-bin/backupbot.cgi

# Expose web frontend port
EXPOSE 8080

# Keep duplicati entrypoint
ENTRYPOINT ["/init"]
