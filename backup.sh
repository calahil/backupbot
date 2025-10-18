#!/bin/sh
# === Postgres Auto Backup Script ===
# Description: Detects Postgres containers by known image names and runs pg_dumpall.
# Author: Calahil Studios

# === CONFIGURATION ===
BACKUP_DIR="/backups/postgres"
INTERVAL_HOURS="${INTERVAL_HOURS:-24}" # Default to 24 hours if not set
RETENTION_DAYS="${RETENTION_DAYS:-7}"  # Keep 7 days of backups

# List of known image name patterns
KNOWN_IMAGES=$(
  cat <<'EOF'
postgres:17.0-alpine
postgres:17
postgres
lscr.io/linuxserver/postgres
postgres:14.0-alpine
ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
EOF
)

echo "[INFO] Starting PostgreSQL backup service..."
mkdir -p "$BACKUP_DIR"

while true; do
  TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
  echo "[INFO] $(date) - Starting backup cycle ($TIMESTAMP)"
  echo "[INFO] Checking for running Postgres containers..."

  # Find running containers matching known image names
  MATCHING_CONTAINERS=$(
    docker ps --format "{{.ID}} {{.Image}}" | while read -r ID IMAGE; do
      for pattern in $KNOWN_IMAGES; do
        case "$IMAGE" in
        *"$pattern"*)
          echo "$ID"
          break
          ;;
        esac
      done
    done
  )

  if [ -z "$MATCHING_CONTAINERS" ]; then
    echo "[WARN] No Postgres containers found."
  else
    for container in $MATCHING_CONTAINERS; do
      NAME=$(docker inspect --format '{{.Name}}' "$container" | sed 's#^/##')
      CONTAINER_BACKUP_DIR="$BACKUP_DIR/$NAME"
      FILE="$CONTAINER_BACKUP_DIR/${TIMESTAMP}.sql"

      mkdir -p "$CONTAINER_BACKUP_DIR"

      echo "[INFO] Backing up container: $NAME ($container)"
      PG_PASS=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container" | grep POSTGRES_PASSWORD | cut -d= -f2)
      if docker exec -e PGPASSWORD="$PG_PASS" "$container" pg_dumpall -U postgres -h 127.0.0.1 >"$FILE" 2>/tmp/pg_backup_error.log; then
        echo "[SUCCESS] Backup complete for $NAME -> $FILE"
      else
        echo "[ERROR] Backup failed for $NAME (check /tmp/pg_backup_error.log)"
      fi
      # Retention cleanup
      find "$CONTAINER_BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -name '*.sql' -delete
    done
  fi

  echo "[INFO] Backup cycle complete."
  echo "[INFO] Sleeping for ${INTERVAL_HOURS}h..."
  sleep "${INTERVAL_HOURS}h"
done
