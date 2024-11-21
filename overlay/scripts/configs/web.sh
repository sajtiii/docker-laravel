#!/bin/sh -e

export PORT=${PORT:-80}
export CADDY_ADMIN_PORT=${CADDY_ADMIN_PORT:-8080}

# Check if octane is installed & enabled
if [[ -z "${OCTANE_ENABLED}" ]] ; then
    if grep -q "laravel/octane" "${APP_PATH}/composer.lock" ; then
        export OCTANE_ENABLED=true
    else
        export OCTANE_ENABLED=false
    fi
fi

if [ "${OCTANE_ENABLED}" = true ] && [ ! -f "${APP_PATH}/public/frankenphp-worker.php" ] ; then
    export MESSAGE_FROM_CONFIG="Octane is enabled, but no worker file found. Disabling Octane."
    export OCTANE_ENABLED=false
fi
