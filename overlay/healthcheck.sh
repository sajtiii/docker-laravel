if [[ $CONTAINER_ROLE == *"web"*  ]]; then
    (php artisan octane:status || exit 1) && (curl --fail "${HEALTHCHECK_URL:-localhost/up}" || exit 1)
fi

exit 0;
