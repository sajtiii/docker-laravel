#!/bin/sh -e

source /configuration.sh

trigger() {
    if [ -f "/${APP_PATH}/${1}.sh" ] ; then
        echo "Running $1 script [/${APP_PATH}/${1}.sh] ..."
        chmod +x /${APP_PATH}/${1}.sh
        source /${APP_PATH}/${1}.sh
    fi
}

# Optimization flags
export OPTIMIZE_BY_DEFAULT=false
if [ "${APP_ENV}" = "production" ] ; then
    export OPTIMIZE_BY_DEFAULT=true
fi
export OPTIMIZE_CONFIG=${OPTIMIZE_CONFIG:-${OPTIMIZE_BY_DEFAULT}}
export OPTIMIZE_EVENTS=${OPTIMIZE_EVENTS:-${OPTIMIZE_BY_DEFAULT}}
export OPTIMIZE_ROUTES=${OPTIMIZE_ROUTES:-${OPTIMIZE_BY_DEFAULT}}
export OPTIMIZE_VIEWS=${OPTIMIZE_VIEWS:-${OPTIMIZE_BY_DEFAULT}}


export CADDY_INDEX_FILE="index.php"
if [ "${OCTANE_ENABLED}" = true ] && [ ! -f "${APP_PATH}/public/frankenphp-worker.php" ] ; then
    echo "####################################################################"
    echo "#                                                                  #"
    echo "#  Octane is enabled, but no worker file found. Disabling Octane.  #"
    echo "#                                                                  #"
    echo "####################################################################"
    export OCTANE_ENABLED=false
fi

if [ "${OCTANE_ENABLED}" = true ] ; then
    export OCTANE_WORKER_COUNT=${OCTANE_WORKER_COUNT:-4}
    export CADDY_INDEX_FILE="frankenphp-worker.php"
    export CADDY_FRANKENPHP_CONFIG="worker \"${APP_PATH}/public/frankenphp-worker.php\" ${OCTANE_WORKER_COUNT}"
fi

if [ "${PORT}" = "${CADDY_ADMIN_PORT}" ] ; then
    echo "####################################################################"
    echo "#                                                                  #"
    echo "#  Panic! App port [${PORT}] cannot be the same as admin port [${CADDY_ADMIN_PORT}]!  #"
    echo "#                                                                  #"
    echo "####################################################################"
    exit 1
fi


trigger postconfig

echo ""
echo "Dumping defaulted env vars ..."
echo "Container role is: ${CONTAINER_ROLE}"
echo "Running with octane: ${OCTANE_ENABLED}"
echo "App environment is: ${APP_ENV}"
echo "Auto migrate enabled: ${AUTO_MIGRATE}"
echo "Web running on port: ${PORT}"
echo "Caddy administration port: ${CADDY_ADMIN_PORT}"
echo "Queues: ${QUEUES}"
echo "Queue tries: ${QUEUE_TRIES}"
echo "Queue timeout [s]: ${QUEUE_TIMEOUT}"
echo "Optimize config enabled: ${OPTIMIZE_CONFIG}"
echo "Optimize events enabled: ${OPTIMIZE_EVENTS}"
echo "Optimize routes enable: ${OPTIMIZE_ROUTES}"
echo "Optimize views enabled: ${OPTIMIZE_VIEWS}"
echo ""
echo ""
echo ""

# Migrate DB if something changed
if [ "${AUTO_MIGRATE}" = true ] ; then
    trigger premigrate
    echo "Running migrations ..."
    php ${APP_PATH}/artisan migrate --force
    trigger postmigrate
fi

trigger prestart

# Optimize app if enabled
if [ "${OPTIMIZE_CONFIG}" = true ] ; then
    echo "Optimizing configuration ..."
    php ${APP_PATH}/artisan config:cache
fi
if [ "${OPTIMIZE_EVENTS}" = true ] ; then
    echo "Optimizing events ..."
    php ${APP_PATH}/artisan event:cache
fi
if [ "${OPTIMIZE_ROUTES}" = true ] ; then
    echo "Optimizing routes ..."
    php ${APP_PATH}/artisan route:cache
fi
if [ "${OPTIMIZE_VIEWS}" = true ] ; then
    echo "Optimizing views ..."
    php ${APP_PATH}/artisan view:cache
fi

WEB_COMMAND="docker-php-entrypoint --config /etc/caddy/Caddyfile --adapter caddyfile"
if [ "${OCTANE_ENABLED}" = true ] ; then
    WEB_COMMAND="php ${APP_PATH}/artisan octane:frankenphp --port=${PORT} --admin-port=${CADDY_ADMIN_PORT} --caddyfile=/etc/caddy/Caddyfile"
fi
QUEUE_COMMAND="php ${APP_PATH}/artisan queue:work --verbose --queue=${QUEUES} --sleep=${QUEUE_SLEEP:-3} --tries=${QUEUE_TRIES} --max-time=${QUEUE_TIMEOUT} --no-interaction"
SCHEDULER_COMMAND="php ${APP_PATH}/artisan schedule:work --verbose --no-interaction"

if [ "${CONTAINER_ROLE}" = "web" ]; then
    echo "Starting web service ..."
    eval "${WEB_COMMAND}"

elif [ "${CONTAINER_ROLE}" = "queue" ]; then
    echo "Starting queue service ..."
    eval "${QUEUE_COMMAND}"
 
elif [ "${CONTAINER_ROLE}" = "scheduler" ]; then
    echo "Starting scheduler service ..."
    eval "${SCHEDULER_COMMAND}"
 
elif [ "${CONTAINER_ROLE}" = "cmd" ]; then
    echo "Executing custom command [$@] ..."
    exec "$@"
    exit 0

else
    if [[ $CONTAINER_ROLE == *"web"* ]]; then
        echo "Installing web service ..."
        echo "[program:web]" >> /etc/supervisord.conf
        echo "command=$WEB_COMMAND" >> /etc/supervisord.conf
        echo "stdout_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stdout_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "stderr_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stderr_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "" >> /etc/supervisord.conf
    fi

    if [[ $CONTAINER_ROLE == *"queue"* ]]; then
        echo "Installing queue service ..."
        echo "[program:queue]" >> /etc/supervisord.conf
        echo "command=$QUEUE_COMMAND" >> /etc/supervisord.conf
        echo "stdout_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stdout_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "stderr_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stderr_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "" >> /etc/supervisord.conf
    fi

    if [[ $CONTAINER_ROLE == *"scheduler"* ]]; then
        echo "Installing scheduler service ..."
        echo "[program:scheduler]" >> /etc/supervisord.conf
        echo "command=sh -c \"$SCHEDULER_COMMAND\"" >> /etc/supervisord.conf
        echo "stdout_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stdout_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "stderr_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stderr_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "" >> /etc/supervisord.conf
    fi

    echo "Starting installed services ..."
    echo ""
    exec supervisord -n -c /etc/supervisord.conf
fi