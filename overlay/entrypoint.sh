#!/bin/sh -e

role=${CONTAINER_ROLE:-app}

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
    echo "Caching config, routes and views ..."
    php /srv/http/artisan config:cache
    php /srv/http/artisan route:cache
    php /srv/http/artisan view:cache
fi


if [ "$role" = "app" ]; then
    exec supervisord -n -c /etc/supervisord.conf
 
elif [ "$role" = "queue" ]; then
    php /srv/http/artisan queue:work --verbose --queue=${QUEUES:-high,medium,notification,default,low} --sleep=3 --tries=3 --max-time=3600
    exit 1
 
elif [ "$role" = "scheduler" ]; then
    while [ true ]
    do
      php /srv/http/artisan schedule:run --verbose --no-interaction &
      sleep 60
    done
 
else
    echo "Executing custom command [$@] ..."
    exec "$@"
    exit 0
fi