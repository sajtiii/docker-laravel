#!/bin/sh

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export APP_ENV=${APP_ENV:-production}

export AUTO_MIGRATE=${AUTO_MIGRATE:-false}

export PORT=${PORT:-80}
export CADDY_ADMIN_PORT=${CADDY_ADMIN_PORT:-8080}


# QUEUE config
export QUEUES=${QUEUES:-high,medium,notification,default,low}
export QUEUE_TRIES=${QUEUE_TRIES:-3}
export QUEUE_TIMEOUT=${QUEUE_TIMEOUT:-7200}


# Check if octane is installed & enabled
if [[ -z "${OCTANE_ENABLED}" ]] ; then
    if grep -q "laravel/octane" "${APP_PATH}/composer.lock" ; then
        export OCTANE_ENABLED=true
    else
        export OCTANE_ENABLED=false
    fi
fi