#!/bin/sh -e

trigger() {
    if [ -f "/srv/http/$1.sh" ] ; then
        echo "Running $1 script [/srv/http/$1.sh] ..."
        chmod +x /srv/http/$1.sh
        source /srv/http/$1.sh
    fi
}

trigger preconfig

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_ENV=${APP_ENV:-production}

export AUTO_MIGRATE=${AUTO_MIGRATE:-false}

export QUEUES=${QUEUES:-high,medium,notification,default,low}
export QUEUE_TRIES=${QUEUE_TRIES:-3}
export QUEUE_TIMEOUT=${QUEUE_TIMEOUT:-7200}

export OPTIMIZE_BY_DEFAULT=false
if [ "${APP_ENV}" = "production" ] ; then
    export OPTIMIZE_BY_DEFAULT=true
fi
export OPTIMIZE_CONFIG=${OPTIMIZE_CONFIG:-${OPTIMIZE_BY_DEFAULT}}
export OPTIMIZE_EVENTS=${OPTIMIZE_EVENTS:-${OPTIMIZE_BY_DEFAULT}}
export OPTIMIZE_ROUTES=${OPTIMIZE_ROUTES:-${OPTIMIZE_BY_DEFAULT}}
export OPTIMIZE_VIEWS=${OPTIMIZE_VIEWS:-${OPTIMIZE_BY_DEFAULT}}

trigger postconfig

echo ""
echo "Dumping defaulted env vars ..."
echo "Container role is: ${CONTAINER_ROLE}"
echo "App environment is: ${APP_ENV}"
echo "Auto migrate enabled: ${AUTO_MIGRATE}"
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
    php /srv/http/artisan migrate --force
    trigger postmigrate
fi

trigger prestart

# Optimize app if enabled
if [ "${OPTIMIZE_CONFIG}" = true ] ; then
    echo "Optimizing configuration ..."
    php /srv/http/artisan config:cache
fi
if [ "${OPTIMIZE_EVENTS}" = true ] ; then
    echo "Optimizing events ..."
    php /srv/http/artisan event:cache
fi
if [ "${OPTIMIZE_ROUTES}" = true ] ; then
    echo "Optimizing routes ..."
    php /srv/http/artisan route:cache
fi
if [ "${OPTIMIZE_VIEWS}" = true ] ; then
    echo "Optimizing views ..."
    php /srv/http/artisan view:cache
fi

QUEUE_COMMAND="php /srv/http/artisan queue:work --verbose --queue=${QUEUES} --sleep=${QUEUE_SLEEP:-3} --tries=${QUEUE_TRIES} --max-time=${QUEUE_TIMEOUT} --no-interaction"
SCHEDULER_COMMAND="php /srv/http/artisan schedule:work --verbose --no-interaction"

if [ "${CONTAINER_ROLE}" = "queue" ]; then
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
        echo "[program:nginx]" >> /etc/supervisord.conf
        echo "command=/usr/sbin/nginx -g 'daemon off;'" >> /etc/supervisord.conf
        echo "stdout_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stdout_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "stderr_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stderr_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "" >> /etc/supervisord.conf
        echo "[program:octane]" >> /etc/supervisord.conf
        echo "command=php /srv/http/artisan octane:start --server=swoole --workers=4 --task-workers=6 --port=8000" >> /etc/supervisord.conf
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

trigger poststart