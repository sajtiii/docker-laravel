ARG PHP_VERSION="8.5"

FROM shinsenter/frankenphp:php${PHP_VERSION}-alpine

ENV TZ=UTC
ENV PHP_VERSION=${PHP_VERSION}


# The base image already provides every PHP extension Laravel (and Octane) needs,
# including pcntl, redis, pdo_*, zip, intl, exif and gd. Composer and
# install-php-extensions come with it as well, so projects built on this image can use them.
# They are not downloaded here.
RUN apk add --no-cache \
    supervisor \
    curl \
    su-exec

# The default port is above 1024, so the file capability that allows binding
# privileged ports is not needed. Dropping it lets the container run without NET_BIND_SERVICE.
RUN apk add --no-cache --virtual .setcap libcap-setcap && \
    setcap -r /usr/local/bin/frankenphp && \
    apk del .setcap

# Caddy keeps its state here, and it runs as the application user
RUN chown -R ${APP_USER:-www-data}:${APP_GROUP:-www-data} /config /data

ENV APP_PATH=/srv/http
WORKDIR /srv/http

ADD overlay/ /

RUN chmod +x /entrypoint.sh && \
    chmod +x /healthcheck.sh && \
    chmod -R +x /scripts/*


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "" ]

EXPOSE 8080

HEALTHCHECK --start-period=30s --start-interval=5s --interval=10s --timeout=2s --retries=5 CMD /healthcheck.sh
