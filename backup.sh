#!/bin/bash

WORLD_DIR="${WORLD_DIR:-/data/world}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"
PASSWORD_FILE="${PASSWORD_FILE:-/run/secrets/backup-password}"
WEBHOOK_FILE="${WEBHOOK_FILE:-/run/secrets/discord-webhook}"
PUBLIC_IPV4="${PUBLIC_IPV4:-}"
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-}"

START_TIME=$(date +%s)
BACKUP_NAME="minecraft-$(date +%Y-%m-%d_%H-%M-%S).7z"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
TEMP_FILE="$BACKUP_DIR/${BACKUP_NAME%.7z}.tmp.7z"

echo "Starting Minecraft backup..."

for file in "$WORLD_DIR" "$PASSWORD_FILE" "$WEBHOOK_FILE"; do
    if [ ! -e "$file" ]; then
        echo "Required path does not exist: $file" >&2
        exit 1
    fi
done

mkdir -p "$BACKUP_DIR"

PASSWORD=$(cat "$PASSWORD_FILE")
DISCORD_WEBHOOK=$(cat "$WEBHOOK_FILE")

if [ -z "$DOWNLOAD_BASE_URL" ]; then
    if [ -z "$PUBLIC_IPV4" ]; then
        PUBLIC_IPV4=$(curl -4 -fsS --max-time 10 https://ipinfo.io/ip || true)
    fi

    if [ -n "$PUBLIC_IPV4" ]; then
        DOWNLOAD_BASE_URL="http://${PUBLIC_IPV4}"
    fi
fi

rm -f "$TEMP_FILE"
trap 'rm -f "$TEMP_FILE"' EXIT

echo "Creating encrypted archive: $BACKUP_NAME"

cd /data

7z a \
    -t7z \
    -mhe=on \
    -p"$PASSWORD" \
    "$TEMP_FILE" \
    world

# Verify the archive before publishing it.
7z t -p"$PASSWORD" "$TEMP_FILE"

# Publish only after the archive has been created and verified.
mv "$TEMP_FILE" "$BACKUP_FILE"
trap - EXIT

# Keep only the three newest completed archives.
mapfile -t OLD_BACKUPS < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'minecraft-*.7z' \
        ! -name '*.tmp.7z' \
        -printf '%T@\t%p\n' |
    sort -rn |
    tail -n +4 |
    cut -f2-
)

for old_backup in "${OLD_BACKUPS[@]}"; do
    echo "Removing old backup: $old_backup"
    rm -f -- "$old_backup"
done

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Backup completed: $BACKUP_NAME ($SIZE)"

if [ -n "$DOWNLOAD_BASE_URL" ]; then
    DOWNLOAD_URL="${DOWNLOAD_BASE_URL%/}/backup/${BACKUP_NAME}"
    DOWNLOAD_TEXT="[Download backup]($DOWNLOAD_URL)"
else
    DOWNLOAD_TEXT="Download URL unavailable."
fi

CONTENT=$(printf \
    '✅ **Minecraft backup completed**\n\n**File:** %s\n**Size:** %s\n**Duration:** %ss\n\n%s' \
    "$BACKUP_NAME" "$SIZE" "$DURATION" "$DOWNLOAD_TEXT")

MESSAGE=$(jq -n --arg content "$CONTENT" '{content: $content}')

curl -fsS \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$MESSAGE" \
    "$DISCORD_WEBHOOK"

echo "Discord notification sent."
