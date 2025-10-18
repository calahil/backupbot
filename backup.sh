#!/bin/sh
# === Postgres Auto Backup Script ===
# Description: Finds all Postgres containers and runs pg_dumpall.
# Author: Calahil Studios

# === CONFIGURATION ===
BACKUP_DIR="/backups/postgres"
KNOWN_IMAGES="
  postgres:17.0-alpine \
  postgres:17 \
  postgres \
  lscr.io/linuxserver/postgres \
  postgres:14.0-alpine \
  ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0 
  "

echo "[INFO] Starting PostgreSQL backup service..."
mkdir -p "$BACKUP_DIR"
while true; do
  TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
  echo "[INFO] Starting backup at $TIMESTAMP"
  echo "[INFO] Checking for Postgres containers..."

  # === FIND MATCHING CONTAINERS ===
  for container in $(docker ps --format "{{.ID}} {{.Image}}" | while read -r ID IMAGE; do
    for pattern in $KNOWN_IMAGES; do
      case "$IMAGE" in
      *"$pattern"*)
        echo "$ID"
        break
        ;;
      esac
    done
  done) do
    NAME=$(docker inspect --format '{{.Name}}' "$container" | sed 's#^/##')
    mkdir -p "$BACKUP_DIR}/${NAME}"
    FILE="$BACKUP_DIR/${NAME}/${TIMESTAMP}.sql"

    echo "[INFO] Backing up container: $NAME ($container)"
    if docker exec "$container" pg_dumpall -U postgres >"$FILE" 2>/tmp/pg_backup_error.log; then
      echo "[SUCCESS] Backup complete for $NAME -> $FILE"
    else
      echo "[ERROR] Backup failed for $NAME (check /tmp/pg_backup_error.log)"
    fi
  done

  echo "[INFO] All backups done."
  echo "[INFO] Sleeping for ${INTERVAL_HOURS} hours..."
  sleep "${INTERVAL_HOURS}h"
done
