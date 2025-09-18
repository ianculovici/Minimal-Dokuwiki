# Minimal-Dokuwiki

A simple, lightweight DokuWiki setup with Docker, featuring automatic upgrades and SQLite support.

## Quick Start

### Option 1: Use Pre-built Image (Recommended)

1. **Clone and configure:**
   ```bash
   git clone <repository>
   cd Minimal-Dokuwiki
   cp config.env.example .env
   ```

2. **Set your desired DokuWiki version:**
   ```bash
   echo "VENDOR_VERSION=2024.2.6.b" >> .env
   ```

3. **Start the containers:**
   ```bash
   docker compose up
   ```

### Option 2: Build from Source

1. **Follow Option 1 steps 1-2**
2. **Build and start:**
   ```bash
   docker compose up --build
   ```

### Access DokuWiki
- URL: `http://localhost:11180`
- Default login: `admin` / `admin`

## Features

- **Automatic Upgrades**: Safe upgrade system with automatic backups
- **SQLite Support**: Built-in database for user authentication
- **Timezone Support**: Configurable via environment variables
- **Lightweight**: Minimal resource footprint
- **Production Ready**: Proper file permissions and error handling

## Configuration

Edit `.env` to customize:

```bash
# DokuWiki version (semantic versioning: YYYY.M.D.b)
VENDOR_VERSION=2024.2.6.b

# Number of backups to keep
BACKUP_RETENTION=3

# Timezone
TZ=UTC
```

## Upgrading

To upgrade to a new DokuWiki version:

1. Update `VENDOR_VERSION` in `.env`
2. Run `docker compose up --build`

The system will automatically download, backup, and install the new version.

## Documentation

- [Upgrade System Guide](UPGRADE_SYSTEM.md) - Detailed upgrade documentation
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions