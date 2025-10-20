#!/usr/bin/env bash
# === Postgres Auto Backup Script ===
# Description: Detects Postgres containers by known image names and runs pg_dumpall.
# Author: Calahil Studios

# === CONFIGURATION ===
LOG_FILE="$1"
BACKUP_DIR="/backups/postgres_dumps"
RETENTION_DAYS="${RETENTION_DAYS:-7}" # Keep 7 days of backups

# List of known image name patterns
KNOWN_IMAGES=$(
  cat <<'EOF'
postgres:17.0-alpine
postgres:17
postgres
postgres:14.0-alpine
ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
EOF
)

echo "[BACKUPBOT_INFO] Starting PostgreSQL backup service..." | tee -a "$LOG_FILE"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
echo "[BACKUPBOT_INFO] $(date) - Starting backup cycle ($TIMESTAMP)" | tee -a "$LOG_FILE"
echo "[BACKUPBOT_INFO] Checking for running Postgres containers..." | tee -a "$LOG_FILE"

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
  echo "[BACKUPBOT_WARN] No Postgres containers found." | tee -a "$LOG_FILE"
else
  for container in $MATCHING_CONTAINERS; do
    NAME=$(docker inspect --format '{{.Name}}' "$container" | sed 's#^/##')
    CONTAINER_BACKUP_DIR="$BACKUP_DIR/$NAME"
    FILE="$CONTAINER_BACKUP_DIR/${TIMESTAMP}.sql"

    mkdir -p "$CONTAINER_BACKUP_DIR"

    echo "[BACKUPBOT_INFO] Backing up container: $NAME ($container)" | tee -a "$LOG_FILE"
    PG_USER=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container" | grep POSTGRES_USER | cut -d= -f2)
    PG_PASS=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container" | grep POSTGRES_PASSWORD | cut -d= -f2)
    if docker exec -e PGPASSWORD="$PG_PASS" "$container" pg_dumpall -U "$PG_USER" -h 127.0.0.1 >"$FILE" 2>/tmp/pg_backup_error.log; then
      echo "[BACKUPBOT_SUCCESS] Backup complete for $NAME -> $FILE" | tee -a "$LOG_FILE"
    else
      echo "[BACKUPBOT_ERROR] Backup failed for $NAME (check /tmp/pg_backup_error.log)" | tee -a "$LOG_FILE"
    fi
    # Retention cleanup
    find "$CONTAINER_BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -name '*.sql' -delete
  done
fi

echo "[BACKUPBOT_INFO] Creating a snapshot of /srv/appdata" | tee -a "$LOG_FILE"
btrfs subvolume snapshot -r /source/appdata /backups/snapshots/$(hostname)-$(date +%F)

echo "[BACKUPBOT_INFO] Backup cycle complete." | tee -a "$LOG_FILE"
