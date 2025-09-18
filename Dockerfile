FROM php:8.1-fpm

# Install additional dependencies for the script and SQLite support
RUN apt-get update && apt-get install -y \
    bash \
    sqlite3 \
    libsqlite3-dev \
    tzdata \
    wget \
    tar \
    gzip \
    && docker-php-ext-install pdo pdo_sqlite \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Configure timezone (will be set at runtime)
ENV TZ=UTC

# Copy upgrade script, restore script, and PHP configuration
COPY upgrade.sh /usr/local/bin/upgrade.sh
COPY restore.sh /usr/local/bin/restore.sh
COPY php-dokuwiki.ini /usr/local/etc/php/conf.d/dokuwiki.ini
RUN chmod +x /usr/local/bin/upgrade.sh /usr/local/bin/restore.sh

# Ensure www-data user exists with correct UID/GID
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# PHP configuration is handled by the dedicated config file

# Create cache and backup directories
RUN mkdir -p /app/cache /app/backups

# Ensure permissions are correct
RUN chown -R www-data:www-data /app

# Run upgrade script on container start
CMD ["/usr/local/bin/upgrade.sh"]
