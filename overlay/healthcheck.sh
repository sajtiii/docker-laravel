role=${CONTAINER_ROLE:-app}


if [ "$role" = "app" ]; then
    php artisan octane:status || exit 1
 

else
    echo "No healthcheck configured for role [$role] ..."
    exit 0
fi