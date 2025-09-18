#!/bin/bash

# Minimal-Dokuwiki Upgrade Script
# Handles timezone configuration, version checking, and DokuWiki upgrades

set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Set timezone from environment or use UTC as fallback
configure_timezone() {
    if [ -n "$TZ" ] && [ "$TZ" != "UTC" ]; then
        log "Setting timezone to $TZ"
        # Check if timezone file exists
        if [ -f "/usr/share/zoneinfo/$TZ" ]; then
            ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
            echo $TZ > /etc/timezone
            log "Timezone set to $TZ"
        else
            log "Warning: Timezone $TZ not found, using UTC"
            ln -snf /usr/share/zoneinfo/UTC /etc/localtime
            echo "UTC" > /etc/timezone
        fi
    else
        log "Using UTC timezone"
        ln -snf /usr/share/zoneinfo/UTC /etc/localtime
        echo "UTC" > /etc/timezone
    fi
}

# Convert DokuWiki version format to semantic versioning
# Input: 2024-02-06b -> Output: 2024.2.6.b
convert_version() {
    local dokuwiki_version="$1"
    # Remove quotes and extract version part
    local clean_version=$(echo "$dokuwiki_version" | sed 's/"//g' | awk '{print $1}')
    # Convert 2024-02-06b to 2024.2.6.b (remove leading zeros)
    echo "$clean_version" | sed 's/-/./g' | sed 's/\([0-9]\)b$/\1.b/' | sed 's/\.0\([0-9]\)/.\1/g'
}

# Get current version from VERSION file
get_current_version() {
    local version_file="/app/app-data/VERSION"
    if [ -f "$version_file" ]; then
        local first_line=$(head -n1 "$version_file")
        convert_version "$first_line"
    else
        echo "0.0.0.0"
    fi
}

# Check if upgrade is needed
is_upgrade_needed() {
    local current_version="$1"
    local target_version="$2"
    
    if [ "$current_version" = "0.0.0.0" ]; then
        log "No VERSION file found, upgrade needed for new installation"
        return 0
    fi
    
    if [ "$(printf '%s\n%s' "$target_version" "$current_version" | sort -V | tail -n1)" = "$target_version" ] && [ "$target_version" != "$current_version" ]; then
        return 0
    else
        return 1
    fi
}

# Create backup of app-data
create_backup() {
    local backup_dir="/app/backups/$(date +%Y%m%d_%H%M%S)"
    log "Creating backup in $backup_dir"
    
    mkdir -p "$backup_dir"
    
    if [ -d "/app/app-data" ] && [ "$(ls -A /app/app-data 2>/dev/null)" ]; then
        cp -r /app/app-data/* "$backup_dir/"
        log "Backup created successfully"
        echo "$backup_dir"
    else
        log "No app-data to backup (new installation)"
        echo ""
    fi
}

# Clean old backups
clean_old_backups() {
    local retention=${BACKUP_RETENTION:-3}
    log "Cleaning old backups (keeping last $retention)"
    
    if [ -d "/app/backups" ]; then
        cd /app/backups
        # Keep only the most recent backups
        ls -t | tail -n +$((retention + 1)) | xargs -r rm -rf
        log "Old backups cleaned"
    fi
}

# Download DokuWiki if not cached
download_dokuwiki() {
    local version="$1"
    # Convert semantic version back to DokuWiki format for URL
    # 2024.2.6.b -> 2024-02-06b
    local year=$(echo "$version" | cut -d. -f1)
    local month=$(echo "$version" | cut -d. -f2)
    local day=$(echo "$version" | cut -d. -f3)
    local suffix=$(echo "$version" | cut -d. -f4)
    
    # Pad month and day with leading zeros
    month=$(printf "%02d" "$month")
    day=$(printf "%02d" "$day")
    
    local dokuwiki_version="${year}-${month}-${day}${suffix}"
    local cache_file="/app/cache/dokuwiki-${dokuwiki_version}.tgz"
    local download_url="https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${dokuwiki_version}.tgz"
    
    # Check if already cached
    if [ -f "$cache_file" ]; then
        log "Using cached DokuWiki version $dokuwiki_version" >&2
        echo "$cache_file"
        return 0
    fi
    
    log "Downloading DokuWiki version $dokuwiki_version" >&2
    
    # Create cache directory
    mkdir -p /app/cache
    
    # Test URL first
    if ! wget --spider "$download_url" 2>/dev/null; then
        error_exit "URL not accessible: $download_url"
    fi
    
    # Download with error handling and timeout
    if ! wget --timeout=300 --tries=1 -O "$cache_file" "$download_url"; then
        error_exit "Failed to download DokuWiki from $download_url"
    fi
    
    log "Download completed successfully" >&2
    echo "$cache_file"
}

# Extract and copy DokuWiki files
extract_and_copy() {
    local archive_file="$1"
    local temp_dir="/tmp/dokuwiki-extract"
    
    log "Extracting DokuWiki archive"
    
    # Clean and create temp directory
    rm -rf "$temp_dir" 2>/dev/null || true
    mkdir -p "$temp_dir"
    
    # Verify archive file exists
    if [ ! -f "$archive_file" ]; then
        log "ERROR: Archive file not found: $archive_file"
        error_exit "Archive file does not exist"
    fi
    
    # Extract archive
    log "Extracting archive to $temp_dir"
    if ! tar -xzf "$archive_file" -C "$temp_dir"; then
        log "ERROR: tar extraction failed"
        log "Archive file: $archive_file"
        log "Target directory: $temp_dir"
        log "Archive file exists: $([ -f "$archive_file" ] && echo "yes" || echo "no")"
        log "Target directory exists: $([ -d "$temp_dir" ] && echo "yes" || echo "no")"
        error_exit "Failed to extract DokuWiki archive"
    fi
    
    # Find the extracted directory (should be dokuwiki-{version})
    # Look for directories that are direct children of temp_dir and match dokuwiki-* pattern
    local extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -name "dokuwiki-*" | head -n1)
    
    if [ -z "$extracted_dir" ] || [ ! -d "$extracted_dir" ]; then
        error_exit "Could not find extracted DokuWiki directory"
    fi
    
    # Verify this is actually the DokuWiki directory (should contain index.php)
    if [ ! -f "$extracted_dir/index.php" ]; then
        error_exit "Extracted directory does not contain index.php: $extracted_dir"
    fi
    
    log "Copying files to app-data"
    
    # Create app-data directory if it doesn't exist
    mkdir -p /app/app-data
    
    # Copy all files (preserve permissions and copy hidden files)
    if ! cp -rp "$extracted_dir"/. /app/app-data/; then
        error_exit "Failed to copy files from $extracted_dir to /app/app-data"
    fi
    
    # Verify the copy worked
    if [ ! -f "/app/app-data/VERSION" ]; then
        error_exit "VERSION file not found after copy - upgrade may have failed"
    fi
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    log "Files copied successfully"
}

# Perform upgrade
perform_upgrade() {
    local current_version="$1"
    local target_version="$2"
    
    log "Starting upgrade from $current_version to $target_version"
    
    # Create backup
    local backup_dir
    backup_dir=$(create_backup)
    
    # Download DokuWiki
    local archive_file
    archive_file=$(download_dokuwiki "$target_version")
    
    # Extract and copy files
    extract_and_copy "$archive_file"
    
    # Clean up old backups
    clean_old_backups
    
    log "Upgrade completed successfully"
}

# Check if app-data exists and has content
is_new_installation() {
    if [ ! -d "/app/app-data" ] || [ ! "$(ls -A /app/app-data 2>/dev/null)" ]; then
        return 0
    else
        return 1
    fi
}

# Main execution
main() {
    log "Starting Minimal-Dokuwiki upgrade process"
    
    # Configure timezone
    configure_timezone
    
    # Get versions
    local current_version
    current_version=$(get_current_version)
    local target_version=${VENDOR_VERSION:-"2024.2.6.b"}
    
    log "Current version: $current_version"
    log "Target version: $target_version"
    
    # Check if upgrade is needed
    if is_upgrade_needed "$current_version" "$target_version"; then
        if is_new_installation; then
            log "New installation detected"
        else
            log "Upgrade needed from $current_version to $target_version"
        fi
        
        # Perform upgrade
        log "Starting upgrade process"
        perform_upgrade "$current_version" "$target_version"
        log "Upgrade completed successfully"
    else
        log "No upgrade needed - versions are the same or target is older"
    fi
    
    # Ensure app-data directory exists
    if [ ! -d "/app/app-data" ]; then
        log "ERROR: No app-data directory found after upgrade process"
        log "This indicates a critical failure. Please check logs and retry."
        exit 1
    fi
    
    # Ensure proper permissions
    log "Setting proper file permissions"
    chown -R www-data:www-data /app/app-data 2>/dev/null || true
    find /app/app-data -type d -exec chmod 755 {} \; 2>/dev/null || true
    find /app/app-data -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # Verify DokuWiki files exist
    if [ ! -f "/app/app-data/index.php" ]; then
        log "ERROR: DokuWiki index.php not found. Installation may be incomplete."
        exit 1
    fi
    
    log "Upgrade process completed. Starting PHP-FPM..."
    
    # Start PHP-FPM
    exec php-fpm
}

# Run main function
main "$@"

