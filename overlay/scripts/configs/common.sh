#!/bin/sh -e

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export UPLOAD_LIMIT=${UPLOAD_LIMIT:-20M}

# Long running processes and artisan commands run as the application user
export APP_USER=${APP_USER:-www-data}
export APP_GROUP=${APP_GROUP:-www-data}
if [ "$(id -u)" = "0" ]; then
    export RUN_AS="su-exec ${APP_USER}:${APP_GROUP}"
else
    export RUN_AS=""
fi
