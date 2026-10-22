ARG PHP_VERSION="8.5"

# Base images are pinned by digest, Dependabot keeps the tags and digests up to date.
FROM shinsenter/frankenphp:php8.2-alpine@sha256:317da619a36fd02c16a00242a8a6dbda993235c9cf95ca41f54343c42d990363 AS base-8.2
FROM shinsenter/frankenphp:php8.3-alpine@sha256:dd30da6ebb42005201b8d93912f3744ae4b4f9d8db46b545c35b70a7be9bd204 AS base-8.3
FROM shinsenter/frankenphp:php8.4-alpine@sha256:16d45584fc1390b21ffd99713a8402b0c0c790a25e20d05262a0eb3c919b250f AS base-8.4
FROM shinsenter/frankenphp:php8.5-alpine@sha256:17f980586f9c3649e9c5b4e0e803a49bcf899bb69b6b39eea7065c4d686365a0 AS base-8.5

FROM base-${PHP_VERSION}

ENV TZ=UTC
ENV PHP_VERSION=${PHP_VERSION}

LABEL org.opencontainers.image.source=https://github.com/sajtiii/docker-laravel
LABEL org.opencontainers.image.description="A simple Laravel container with Octane, Queue and Scheduler"
LABEL org.opencontainers.image.licenses="MIT"

# The base image already provides every PHP extension Laravel (and Octane) needs,
# including pcntl, redis, pdo_*, zip, intl, exif and gd. Composer and
# install-php-extensions come with it as well, so projects built on this image can use them.
# They are covered by the digest pinning of the base image, so they are not downloaded here.
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
