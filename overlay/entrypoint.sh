#!/bin/sh -e

# Run startup script if found
if [ -f /srv/http/startup.sh ] ; then
    echo "Running startup script [/srv/http/startup.sh] ..."
    chmod +x /srv/http/startup.sh
    sh /srv/http/startup.sh
fi

# Migrate DB if something changed
if [ "${AUTO_MIGRATE:-false}" = "true" ] ; then
    echo "Running migrations ..."
    php /srv/http/artisan migrate --force
fi

# Optimize app if running in production
if [ "${APP_ENV:-production}" = "production" ] ; then
    echo "Optimizing application ..."
    php /srv/http/artisan optimize
fi

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

QUEUE_COMMAND="php /srv/http/artisan queue:work --verbose --queue=${QUEUES:-high,medium,notification,default,low} --sleep=3 --tries=3 --max-time=3600"
SCHEDULER_COMMAND="while [ true ]; do php /srv/http/artisan schedule:run --verbose --no-interaction & sleep 60; done"

if [ "${CONTAINER_ROLE}" = "queue" ]; then
    exit $(QUEUE_COMMAND)
 
elif [ "${CONTAINER_ROLE}" = "scheduler" ]; then
    exit $(SCHEDULER_COMMAND)
 
elif [ "${CONTAINER_ROLE}" = "cmd" ]; then
    echo "Executing custom command [$@] ..."
    exec "$@"
    exit 0

else
    if [[ $CONTAINER_ROLE == *"web"* ]]; then
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
        echo "[program:queue]" >> /etc/supervisord.conf
        echo "command=$QUEUE_COMMAND" >> /etc/supervisord.conf
        echo "stdout_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stdout_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "stderr_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stderr_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "" >> /etc/supervisord.conf
    fi

    if [[ $CONTAINER_ROLE == *"scheduler"* ]]; then
        echo "[program:scheduler]" >> /etc/supervisord.conf
        echo "command=sh -c \"$SCHEDULER_COMMAND\"" >> /etc/supervisord.conf
        echo "stdout_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stdout_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "stderr_logfile=/dev/fd/1" >> /etc/supervisord.conf
        echo "stderr_logfile_maxbytes=0" >> /etc/supervisord.conf
        echo "" >> /etc/supervisord.conf
    fi

    exec supervisord -n -c /etc/supervisord.conf
fi
