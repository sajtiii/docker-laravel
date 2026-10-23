ARG PHP_VERSION="8.5"

FROM shinsenter/frankenphp:php${PHP_VERSION}-alpine

ENV TZ=UTC
ENV PHP_VERSION=${PHP_VERSION}


# The base image already provides every PHP extension Laravel (and Octane) needs,
# including pcntl, redis, pdo_*, zip, intl, exif and gd. Composer and
# install-php-extensions come with it as well, so projects built on this image can use them.
# They are not downloaded here.
RUN apk add --no-cache \
    s6 \
    curl \
    su-exec

# The default port is above 1024, so the file capability that allows binding
# privileged ports is not needed. Dropping it lets the container run without NET_BIND_SERVICE.
RUN apk add --no-cache --virtual .setcap libcap-setcap && \
    setcap -r /usr/local/bin/frankenphp && \
    apk del .setcap

# The application runs as this user by default, see the PUID and PGID options
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app -h /home/app -s /sbin/nologin app

# Octane starts `frankenphp` from the PATH. The base image wrapper tries to switch user again,
# which fails when already running as the application user, so use the binary directly.
RUN printf '#!/bin/sh\nexec /usr/local/bin/frankenphp "$@"\n' > /usr/local/utils/frankenphp && \
    chmod +x /usr/local/utils/frankenphp

# Caddy keeps its state here, and it has to be writable for any PUID/PGID
RUN find /config /data -type d -exec chmod 1777 {} +

# Caches generated at runtime (config, routes, events, compiled views) live outside the
# application, so bootstrap/cache and storage never contain stale caches of an older image.
# bootstrap/cache only keeps the package manifests created by `composer install` at build time.
ENV APP_CONFIG_CACHE=/tmp/laravel/config.php \
    APP_ROUTES_CACHE=/tmp/laravel/routes-v7.php \
    APP_EVENTS_CACHE=/tmp/laravel/events.php \
    VIEW_COMPILED_PATH=/tmp/laravel/views
RUN mkdir -m 1777 /tmp/laravel /tmp/laravel/views

ENV APP_PATH=/srv/http
WORKDIR /srv/http

ADD overlay/ /

RUN chmod +x /entrypoint.sh && \
    chmod +x /healthcheck.sh && \
    chmod -R +x /scripts/*

# Nothing in the image needs setuid or setgid binaries (processes are started by root and
# switch user with su-exec), so remove the bits to rule out privilege escalation through them
RUN find / -xdev -type f -perm /6000 -exec chmod a-s {} +


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "" ]

EXPOSE 8080

HEALTHCHECK --start-period=30s --start-interval=5s --interval=10s --timeout=2s --retries=5 CMD /healthcheck.sh
