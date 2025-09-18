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

## Version Format

DokuWiki uses a specific version format. To find the correct version string:

1. Visit [DokuWiki Downloads](https://download.dokuwiki.org/)
2. Look for the version string in the format: `YYYY-MM-DD "Release Name"`
3. Convert to our format: `YYYY.M.D.b`

**Example:**
- DokuWiki shows: `2024-02-06b`
- Use in config: `VENDOR_VERSION=2024.2.6.b`

## Configuration

Edit `.env` to customize:

```bash
# DokuWiki version (semantic versioning: YYYY.M.D.b)
# Format: YYYY = Year, M = Month, D = Day, b = Build/Release
# Example: 2024.2.6.b = February 6, 2024 release
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