# Troubleshooting Guide

## Common Issues

### Container Won't Start

**Symptoms:**
- Container exits immediately
- No logs or error messages

**Solutions:**
1. Check Docker Compose configuration:
   ```bash
   docker compose config
   ```

2. Check container logs:
   ```bash
   docker compose logs dokuwiki-php
   ```

3. Verify file permissions:
   ```bash
   ls -la ./app/app-data/
   ```

### 404 Errors for Static Files

**Symptoms:**
- Images, CSS, JavaScript files return 404
- DokuWiki loads but looks broken

**Solutions:**
1. Check nginx configuration:
   ```bash
   docker compose exec nginx nginx -t
   ```

2. Verify volume mounts:
   ```bash
   docker compose exec nginx ls -la /app/app-data/
   ```

3. Restart nginx:
   ```bash
   docker compose exec nginx nginx -s reload
   ```

### Upgrade Fails

**Symptoms:**
- Upgrade process starts but fails
- VERSION file not updated

**Solutions:**
1. Check upgrade logs:
   ```bash
   docker compose logs dokuwiki-php | grep -i upgrade
   ```

2. Verify internet connectivity:
   ```bash
   docker compose exec dokuwiki-php ping -c 3 google.com
   ```

3. Check disk space:
   ```bash
   docker compose exec dokuwiki-php df -h
   ```

### Permission Errors

**Symptoms:**
- Files not writable
- Permission denied errors

**Solutions:**
1. Fix file permissions:
   ```bash
   docker compose exec dokuwiki-php chown -R www-data:www-data /app/app-data
   docker compose exec dokuwiki-php find /app/app-data -type d -exec chmod 755 {} \;
   docker compose exec dokuwiki-php find /app/app-data -type f -exec chmod 644 {} \;
   ```

2. Check volume ownership:
   ```bash
   ls -la ./app/app-data/
   ```

## Debug Commands

### Check Container Status
```bash
docker compose ps
```

### View Logs
```bash
# All services
docker compose logs

# Specific service
docker compose logs dokuwiki-php
docker compose logs nginx
```

### Enter Container
```bash
# PHP container
docker compose exec dokuwiki-php bash

# Nginx container
docker compose exec nginx sh
```

### Check File System
```bash
# Check if DokuWiki files exist
docker compose exec dokuwiki-php ls -la /app/app-data/

# Check if VERSION file is updated
docker compose exec dokuwiki-php cat /app/app-data/VERSION

# Check file permissions
docker compose exec dokuwiki-php ls -la /app/app-data/index.php
```

### Test Network
```bash
# Test internet connectivity
docker compose exec dokuwiki-php ping -c 3 google.com

# Test DokuWiki download URL
docker compose exec dokuwiki-php wget --spider https://download.dokuwiki.org/src/dokuwiki/dokuwiki-2024-02-06b.tgz
```

## Reset Everything

If all else fails, reset the entire setup:

```bash
# Stop containers
docker compose down

# Remove volumes (WARNING: This deletes all data)
docker compose down -v

# Remove app-data directory
rm -rf ./app/app-data

# Rebuild from scratch
docker compose up --build
```

## Getting Help

### Collect Debug Information
```bash
# Container logs
docker compose logs > dokuwiki.log

# Container info
docker inspect $(docker compose ps -q dokuwiki-php) > container-info.json

# File system check
docker compose exec dokuwiki-php ls -la /app/ > filesystem.txt
```

### Common Commands
```bash
# Restart services
docker compose restart

# Rebuild containers
docker compose up --build

# Force recreate
docker compose up --build --force-recreate
```