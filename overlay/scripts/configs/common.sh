#!/bin/sh -e

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export UPLOAD_LIMIT=${UPLOAD_LIMIT:-20M}

# Long running processes and artisan commands run as the application user
# The numeric IDs of the user and group to run as, www-data by default
export PUID=${PUID:-$(id -u www-data)}
export PGID=${PGID:-$(id -g www-data)}
if [ "$(id -u)" = "0" ]; then
    export RUN_AS="su-exec ${PUID}:${PGID}"
else
    export RUN_AS=""
fi
