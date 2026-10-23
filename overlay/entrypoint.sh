#!/bin/sh -e

source /scripts/functions.sh
load_config common

trigger preconfig

load_config application
load_service_configs
load_config optimization


# Database migration flag
export AUTO_MIGRATE=${AUTO_MIGRATE:-false}

if [[ ! "${APP_PATH}" =~ ^/ ]] || [[ "${APP_PATH}" =~ /$ ]] ; then
    message "Error! Application path [APP_PATH] must start with a \`/\` and end without it."
    exit 1
fi

if [ ! -f "${APP_PATH}/artisan" ] ; then
    message "Error! No Laravel application found in [${APP_PATH}]."
    exit 1
fi

if is_web && [ "${PORT}" = "${CADDY_ADMIN_PORT}" ] ; then
    message "Error! App port [${PORT}] cannot be the same as caddy admin port."
    exit 1
fi

if is_scheduler && [ "${SCHEDULER_MODE}" != "once" ] && [ "${SCHEDULER_MODE}" != "continuous" ] ; then
    message "Error! Invalid scheduler mode [${SCHEDULER_MODE}]. Can be either \`once\` or \`continuous\`."
    exit 1
fi

if [ ! -z "${MESSAGE_FROM_CONFIG}" ] ; then
    message "${MESSAGE_FROM_CONFIG}"
fi

export CADDY_INDEX_FILE="index.php"
if [ "${OCTANE_ENABLED}" = true ] ; then
    export OCTANE_WORKER_COUNT=${OCTANE_WORKER_COUNT:-4}
    export CADDY_INDEX_FILE="frankenphp-worker.php"
    export CADDY_FRANKENPHP_CONFIG="worker \"${APP_PATH}/public/frankenphp-worker.php\" ${OCTANE_WORKER_COUNT}"
fi


trigger postconfig

echo ""
echo "Dumping configuration ..."
echo "Container role is:                ${CONTAINER_ROLE}"
echo "Application path is:              ${APP_PATH}"
echo "Application environment is:       ${APP_ENV}"
echo "Auto migration enabled:           ${AUTO_MIGRATE}"
if [ is_web ]; then
    echo "Running with octane:              ${OCTANE_ENABLED}"
    echo "Web running on port:              ${PORT}"
    echo "Caddy administration port:        ${CADDY_ADMIN_PORT}"
fi
if [ is_queue ]; then
    echo "Queues:                           ${QUEUES}"
    echo "Queue tries:                      ${QUEUE_TRIES}"
    echo "Queue timeout [s]:                ${QUEUE_TIMEOUT}"
fi
if [ is_scheduler ]; then
    echo "Scheduler mode:                   ${SCHEDULER_MODE}"
fi
echo "Optimize config enabled:          ${OPTIMIZE_CONFIG}"
echo "Optimize events enabled:          ${OPTIMIZE_EVENTS}"
echo "Optimize routes enable:           ${OPTIMIZE_ROUTES}"
echo "Optimize views enabled:           ${OPTIMIZE_VIEWS}"
echo ""
echo ""
echo ""

source /scripts/configure-php.sh

# Migrate DB if something changed and auto migrate is enabled
if [ "${AUTO_MIGRATE}" = true ] ; then
    trigger premigrate
    echo "Running migrations ..."
    ${RUN_AS} php ${APP_PATH}/artisan migrate --force
    trigger postmigrate
fi

trigger prestart

# Optimize app if enabled
if [ "${OPTIMIZE_CONFIG}" = true ] ; then
    echo "Optimizing configuration ..."
    ${RUN_AS} php ${APP_PATH}/artisan config:cache
fi
if [ "${OPTIMIZE_EVENTS}" = true ] ; then
    echo "Optimizing events ..."
    ${RUN_AS} php ${APP_PATH}/artisan event:cache
fi
if [ "${OPTIMIZE_ROUTES}" = true ] ; then
    echo "Optimizing routes ..."
    ${RUN_AS} php ${APP_PATH}/artisan route:cache
fi
if [ "${OPTIMIZE_VIEWS}" = true ] ; then
    echo "Optimizing views ..."
    ${RUN_AS} php ${APP_PATH}/artisan view:cache
fi

# Define commands (every long running process runs as the application user)
WEB_COMMAND="${RUN_AS} /usr/local/bin/frankenphp run --config /etc/caddy/Caddyfile --adapter caddyfile"
if [ "${OCTANE_ENABLED}" = true ] ; then
    WEB_COMMAND="${RUN_AS} php ${APP_PATH}/artisan octane:frankenphp --port=${PORT} --admin-port=${CADDY_ADMIN_PORT} --caddyfile=/etc/caddy/Caddyfile"
fi
QUEUE_COMMAND="${RUN_AS} php ${APP_PATH}/artisan queue:work --verbose --queue=${QUEUES} --sleep=${QUEUE_SLEEP:-3} --tries=${QUEUE_TRIES} --max-time=${QUEUE_TIMEOUT} --no-interaction"
SCHEDULER_COMMAND="${RUN_AS} php ${APP_PATH}/artisan schedule:run --verbose --no-interaction"
SCHEDULER_LOOP_COMMAND="${RUN_AS} /scripts/scheduler-loop.sh"

# Start necessary services
if [ "${CONTAINER_ROLE}" = "web" ]; then
    echo "Starting web service ..."
    eval "exec ${WEB_COMMAND}"

elif [ "${CONTAINER_ROLE}" = "queue" ]; then
    echo "Starting queue service ..."
    eval "exec ${QUEUE_COMMAND}"
 
elif [ "${CONTAINER_ROLE}" = "scheduler" ]; then
    echo "Starting scheduler service ..."
    if [ "${SCHEDULER_MODE}" = "once" ] ; then
        eval "exec ${SCHEDULER_COMMAND}"
    fi
    if [ "${SCHEDULER_MODE}" = "continuous" ] ; then
        eval "exec ${SCHEDULER_LOOP_COMMAND}"
    fi

elif [ "${CONTAINER_ROLE}" = "cmd" ]; then
    echo "Executing custom command [$@] ..."
    exec ${RUN_AS} "$@"

else
    # Every service is supervised by s6. The image filesystem can be read-only, so the
    # service directories live in /tmp, in a directory only root can access. /tmp is often
    # mounted noexec, so the run scripts are links to scripts in the image, which read their
    # command from the environment.
    SERVICES_DIR=/tmp/services
    rm -rf ${SERVICES_DIR}
    mkdir -m 700 ${SERVICES_DIR}
    export WEB_COMMAND QUEUE_COMMAND SCHEDULER_LOOP_COMMAND

    install_service() {
        echo "Installing $1 service ..."
        mkdir ${SERVICES_DIR}/$1
        ln -s /scripts/services/$1 ${SERVICES_DIR}/$1/run
    }

    if is_web; then
        install_service web
    fi

    if is_queue; then
        install_service queue
    fi

    if is_scheduler; then
        install_service scheduler
    fi

    echo "Starting installed services ..."
    echo ""
    exec s6-svscan ${SERVICES_DIR}
fi
