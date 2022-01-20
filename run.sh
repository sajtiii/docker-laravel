#!/bin/sh

chown -R www:www-data /var/www
chmod -R ug+w /var/www/storage

if [ -x "/var/www/pre-start.sh" ] 
then
    /var/www/pre-start.sh
fi

if [ "${APP_ENV:-local}" == "production" ]
then
    if [ -x "/var/www/deployment.sh" ] 
    then
        /var/www/deployment.sh
    fi

    php /var/www/artisan cache:clear
    php /var/www/artisan config:cache
    php /var/www/artisan route:cache
    php /var/www/artisan view:cache
fi

/usr/bin/supervisord -c /etc/supervisord.conf
