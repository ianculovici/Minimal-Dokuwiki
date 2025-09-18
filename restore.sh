#!/bin/bash

# Minimal-Dokuwiki Restore Script
# Manually restore from backup

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

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --backup BACKUP_DIR    Restore from specific backup directory"
    echo "  -l, --list                 List available backups"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --list                                    # List available backups"
    echo "  $0 --backup /app/backups/20240101_120000    # Restore from specific backup"
    echo ""
    echo "Available backups:"
    list_backups
}

# List available backups
list_backups() {
    local backup_dir="/app/backups"
    
    if [ ! -d "$backup_dir" ]; then
        log "No backup directory found at $backup_dir"
        return
    fi
    
    local backups=($(ls -t "$backup_dir" 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        log "No backups found"
        return
    fi
    
    log "Available backups:"
    for backup in "${backups[@]}"; do
        local backup_path="$backup_dir/$backup"
        local backup_date=$(stat -c %y "$backup_path" 2>/dev/null || echo "Unknown")
        local backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1 || echo "Unknown")
        echo "  $backup ($backup_size) - $backup_date"
    done
}

# Validate backup directory
validate_backup() {
    local backup_dir="$1"
    
    if [ -z "$backup_dir" ]; then
        error_exit "Backup directory not specified"
    fi
    
    if [ ! -d "$backup_dir" ]; then
        error_exit "Backup directory does not exist: $backup_dir"
    fi
    
    # Check if backup contains DokuWiki files
    if [ ! -f "$backup_dir/VERSION" ] && [ ! -d "$backup_dir/data" ]; then
        error_exit "Invalid backup directory: $backup_dir (missing VERSION file or data directory)"
    fi
    
    log "Backup validation passed: $backup_dir"
}

# Create current backup before restore
create_pre_restore_backup() {
    local pre_restore_dir="/app/backups/pre_restore_$(date +%Y%m%d_%H%M%S)"
    log "Creating pre-restore backup in $pre_restore_dir"
    
    mkdir -p "$pre_restore_dir"
    
    if [ -d "/app/app-data" ] && [ "$(ls -A /app/app-data 2>/dev/null)" ]; then
        cp -r /app/app-data/* "$pre_restore_dir/"
        log "Pre-restore backup created: $pre_restore_dir"
    else
        log "No current app-data to backup"
    fi
    
    echo "$pre_restore_dir"
}

# Restore from backup
restore_from_backup() {
    local backup_dir="$1"
    
    log "Starting restore from $backup_dir"
    
    # Validate backup
    validate_backup "$backup_dir"
    
    # Create pre-restore backup
    local pre_restore_backup
    pre_restore_backup=$(create_pre_restore_backup)
    
    # Stop PHP-FPM if running (optional)
    log "Stopping PHP-FPM for restore"
    pkill -f php-fpm 2>/dev/null || true
    sleep 2
    
    # Remove current app-data
    if [ -d "/app/app-data" ]; then
        log "Removing current app-data"
        rm -rf /app/app-data
    fi
    
    # Create new app-data directory
    mkdir -p /app/app-data
    
    # Copy files from backup
    log "Copying files from backup"
    cp -r "$backup_dir"/* /app/app-data/
    
    # Set proper permissions
    log "Setting proper file permissions"
    chown -R www-data:www-data /app/app-data
    find /app/app-data -type d -exec chmod 755 {} \;
    find /app/app-data -type f -exec chmod 644 {} \;
    
    log "Restore completed successfully"
    log "Pre-restore backup available at: $pre_restore_backup"
    
    # Show restored version
    if [ -f "/app/app-data/VERSION" ]; then
        local restored_version=$(head -n1 /app/app-data/VERSION)
        log "Restored DokuWiki version: $restored_version"
    fi
}

# Main execution
main() {
    local backup_dir=""
    local list_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--backup)
                backup_dir="$2"
                shift 2
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
    
    if [ "$list_only" = true ]; then
        list_backups
        exit 0
    fi
    
    if [ -z "$backup_dir" ]; then
        log "No backup directory specified"
        show_usage
        exit 1
    fi
    
    # Confirm restore operation
    log "WARNING: This will replace the current app-data with backup: $backup_dir"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        exit 0
    fi
    
    # Perform restore
    restore_from_backup "$backup_dir"
    
    log "Restore process completed"
    log "You may need to restart the container to apply changes"
}

# Run main function
main "$@"

