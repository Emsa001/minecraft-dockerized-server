# Minecraft Dockerized Server

Docker-based Minecraft server with Fabric modloader, automated encrypted backups, and Discord notifications.

## Architecture

| Service  | Description                                          | Ports   |
|----------|------------------------------------------------------|---------|
| minecraft| Fabric server (Java 25, JRE Alpine)                 | 25565/tcp, 24454/udp |
| backup   | Daily encrypted backup via cron (7z)                | —       |
| nginx    | Serves backup files for download                    | 80      |

## Features

- Fabric modded server (loader 0.19.5, game 26.3)
- Non-root user, minimal Alpine base image
- 8 GB max heap (512 MB min)
- Encrypted 7z backups (password from secrets file)
- Retains 3 most recent backups
- Discord webhook notification on each backup
- Download link served via nginx
- Backup schedule: daily at 06:00 (Europe/Warsaw)

## Prerequisites

- Docker + Docker Compose
- A Fabric `server.properties` in `data/` (generated on first run)
- Minecraft mods placed in `data/mods/`
- Two secret files:
  - `secrets/backup-password` — 7z archive password
  - `secrets/discord-webhook` — Discord webhook URL

## Usage

```bash
# Start the server (minecraft + backup + nginx)
docker compose up -d

# View Minecraft logs
docker compose logs -f minecraft

# Run a backup manually
docker compose run --rm backup /usr/local/bin/backup.sh

# Stop everything
docker compose down
```

## Configuration

| Setting | Location | Default |
|---------|----------|---------|
| Max RAM | `entrypoint.sh` → `-Xmx` | 8G |
| Min RAM | `entrypoint.sh` → `-Xms` | 512M |
| Backup time | `backup-cron` | `0 6 * * *` |
| Timezone (backup) | `Dockerfile.backup` → `TZ` | Europe/Warsaw |
| Backup retention | `backup.sh` | 3 files |
| Download base URL | `compose.yml` → `DOWNLOAD_BASE_URL` | auto-detect public IP |

## Directory Layout

```
├── compose.yml          # Docker Compose config
├── Dockerfile           # Minecraft server image
├── Dockerfile.backup    # Backup cron image
├── entrypoint.sh        # Java launch script
├── backup.sh            # Backup logic (7z + Discord + retention)
├── backup-cron          # Cron schedule
├── data/                # Server data (world, mods, configs)
│   ├── world/
│   ├── mods/
│   ├── libraries/
│   └── .fabric/
├── backups/             # Encrypted .7z archives (served by nginx)
└── secrets/
    ├── backup-password  # 7z encryption password
    └── discord-webhook  # Webhook URL
```

## Notes

- The `backups/` directory must be writable by the backup container but readable by nginx.
- Set `DOWNLOAD_BASE_URL` in `compose.yml` to a stable address if you don't want auto-detection via `ipinfo.io`.
- To add mods, drop `.jar` files into `data/mods/` and restart the minecraft service.
