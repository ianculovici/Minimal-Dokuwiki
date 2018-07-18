# Minimal-Dokuwiki

## Summary
Simple dokuwiki with alpine, nginx, and php-fpm7.
## Description
You can create a very simple personal or organization knowledge base with a minimal footprint with docker.

This is an image I created that user Alpine Linux (a very small footprint OS), Nginx, and PHP 7 (php-fpm). Services are managed by supervisord.

Once you have docker setup (on Linux or Windows), get the image by running
```
docker pull ianculovici/minimal-dokuwiki
```
You can use `docker-compose` to run the container. Here is a sample `docker-compose.yml` file:

```json
version: '2' 
services: 
  dokuwiki: 
    image: ianculovici/minimal-dokuwiki:latest 
    container_name: "mywiki" 
   volumes: 
     - ./dokuwiki-data:/dokuwiki 
   restart: always 
    ports:
      - "7080:80"
```
All files to manually build the image are available on GitHub.

