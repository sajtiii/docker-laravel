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
    echo "Caching config, routes and views ..."
    php /srv/http/artisan config:cache
    php /srv/http/artisan route:cache
    php /srv/http/artisan view:cache
fi

echo "Executing start command [$@] ..."
exec "$@"

