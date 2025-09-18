# DokuWiki Upgrade System

This document explains the automated upgrade system for Minimal-Dokuwiki.

## Overview

The upgrade system automatically downloads, installs, and manages DokuWiki versions with:
- **Semantic Versioning**: Consistent version tracking
- **Automatic Backups**: Creates backups before upgrades
- **Safe Upgrades**: Error handling and rollback capabilities
- **Version Management**: Easy version switching

## Configuration

Create a `.env` file (copy from `config.env.example`):

```bash
# DokuWiki version (semantic versioning: YYYY.M.D.b)
VENDOR_VERSION=2024.2.6.b

# Number of backups to keep
BACKUP_RETENTION=3

# Timezone
TZ=UTC
```

## Usage

### New Installation

1. Set the desired version in `.env`:
   ```bash
   echo "VENDOR_VERSION=2024.2.6.b" > .env
   ```

2. Start the container:
   ```bash
   docker compose up --build
   ```

### Upgrade Existing Installation

1. Update the version in `.env`:
   ```bash
   echo "VENDOR_VERSION=2024.2.7.b" >> .env
   ```

2. Rebuild and restart:
   ```bash
   docker compose down
   docker compose up --build
   ```

## Version Format

- **DokuWiki format**: `2024-02-06b "Kaos"`
- **Semantic versioning**: `2024.2.6.b`
- **Conversion**: `2024-02-06b` → `2024.2.6.b`

## Backup System

### Automatic Backups

- Created before every upgrade
- Stored in `./app/backups/YYYYMMDD_HHMMSS/`
- Contains complete `app-data` directory
- Retention configurable (default: 3 backups)

### Manual Restore

List available backups:
```bash
docker exec <container_name> /usr/local/bin/restore.sh --list
```

Restore from specific backup:
```bash
docker exec <container_name> /usr/local/bin/restore.sh --backup /app/backups/20240101_120000
```

## Troubleshooting

### Common Issues

1. **Upgrade fails**: Check container logs with `docker compose logs dokuwiki-php`
2. **Files not found**: Verify volume mounts in `compose.yaml`
3. **Permission errors**: Check file ownership with `docker compose exec dokuwiki-php ls -la /app/app-data`

### Debug Commands

```bash
# Check current version
docker compose exec dokuwiki-php cat /app/app-data/VERSION

# Check environment variables
docker compose exec dokuwiki-php env | grep VENDOR_VERSION

# View upgrade logs
docker compose logs dokuwiki-php | grep -i upgrade
```

## File Structure

```
./app/
├── app-data/          # DokuWiki installation
├── cache/            # Downloaded archives
└── backups/          # Automatic backups
    └── YYYYMMDD_HHMMSS/
        └── app-data/
```