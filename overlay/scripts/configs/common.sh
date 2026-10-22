#!/bin/sh -e

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export UPLOAD_LIMIT=${UPLOAD_LIMIT:-20M}

# Long running processes and artisan commands run as the application user
# The numeric IDs of the user and group to run as, the app user (1000:1000) by default
export PUID=${PUID:-1000}
export PGID=${PGID:-1000}
if [ "$(id -u)" = "0" ]; then
    export RUN_AS="su-exec ${PUID}:${PGID}"
else
    export RUN_AS=""
fi
