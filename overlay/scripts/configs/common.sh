#!/bin/sh -e

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export UPLOAD_LIMIT=${UPLOAD_LIMIT:-20M}

# The same limit in bytes, so Caddy rejects larger request bodies before they reach PHP
case "${UPLOAD_LIMIT}" in
    *[gG]) export CADDY_MAX_BODY_SIZE=$(( ${UPLOAD_LIMIT%?} * 1024 * 1024 * 1024 )) ;;
    *[mM]) export CADDY_MAX_BODY_SIZE=$(( ${UPLOAD_LIMIT%?} * 1024 * 1024 )) ;;
    *[kK]) export CADDY_MAX_BODY_SIZE=$(( ${UPLOAD_LIMIT%?} * 1024 )) ;;
    *) export CADDY_MAX_BODY_SIZE=${UPLOAD_LIMIT} ;;
esac

# Long running processes and artisan commands run as the application user
# The numeric IDs of the user and group to run as, the app user (1000:1000) by default
export PUID=${PUID:-1000}
export PGID=${PGID:-1000}
if [ "$(id -u)" = "0" ]; then
    export RUN_AS="su-exec ${PUID}:${PGID}"
else
    export RUN_AS=""
fi
