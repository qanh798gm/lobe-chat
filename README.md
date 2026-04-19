# LobeChat Self-Hosted Deployment

Personal self-hosted LobeChat instance using Docker Compose with Caddy reverse proxy.

## Access

- **App**: http://lobe.local (add `127.0.0.1 lobe.local` to `C:\Windows\System32\drivers\etc\hosts`)
- **RustFS Admin**: http://localhost:9001

## Setup

```bash
# 1. Copy and fill in environment variables
cp .env.example .env

# 2. Start all services
docker compose up -d

# 3. Add lobe.local to Windows hosts file (as Administrator)
# C:\Windows\System32\drivers\etc\hosts
# 127.0.0.1 lobe.local
```

## Services

| Service | Purpose | Port |
|---------|---------|------|
| LobeChat | Main app | (internal, via Caddy) |
| Caddy | Reverse proxy | 80, 443 |
| PostgreSQL | Database | 5432 |
| Redis | Cache/Sessions | 6379 |
| RustFS | S3 file storage | 9000, 9001 |
| SearXNG | Web search | (internal) |

## Data Storage

| Data | Location | Notes |
|------|---------|-------|
| PostgreSQL (chats, users) | `./data/` | **Critical — bind mount on host** |
| Uploaded files | Docker volume `rustfs-data` | Inside Docker |
| Redis cache | Docker volume `redis_data` | Ephemeral, can be lost |
| Caddy certs | Docker volumes | Auto-regenerated |

## Backups

### Manual Backup
```cmd
scripts\backup.bat
```

### Automated Daily Backup (Windows Task Scheduler)
Run once as Administrator:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup-scheduler.ps1
```
This registers a daily backup at 2:00 AM. Backups are stored in `backups/` (excluded from git).

### Backup Contents
- `backups/db/lobechat_YYYYMMDD_HHMM.sql` — PostgreSQL dump (restore with `psql`)
- `backups/s3/rustfs_YYYYMMDD_HHMM.tar` — All uploaded files
- `backups/config/.env_YYYYMMDD_HHMM.bak` — Environment variables
- Retains last **7 daily** backups

### Restore PostgreSQL
```bash
docker exec -i lobe-postgres psql -U postgres lobechat < backups/db/lobechat_YYYYMMDD_HHMM.sql
```

### Restore RustFS
```bash
docker run --rm -v lobehub_rustfs-data:/data -v ./backups/s3:/backup alpine tar xf /backup/rustfs_YYYYMMDD_HHMM.tar -C /data
```

## Git Workflow

Config files are tracked in git. Secrets (`.env`) and data (`data/`) are excluded.

```bash
# After config changes
git add .
git commit -m "feat(phase-X): description"
git push
```
