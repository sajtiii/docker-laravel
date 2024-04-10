FROM php:8.3-cli-alpine

ENV TZ=UTC

LABEL org.opencontainers.image.source=https://github.com/sajtiii/docker-laravel
LABEL org.opencontainers.image.description="A simple Laravel Octane package with Queue and Scheduler"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
    supervisor \
    nginx \
    nginx-mod-http-headers-more \
    nginx-mod-http-brotli \
    autoconf \
    curl \
    tzdata \
    sqlite-dev \
    gcc \
    make \
    g++ \
    zlib-dev

RUN docker-php-ext-install pcntl && \
    pecl install swoole redis && \
    docker-php-ext-enable swoole redis

RUN apk add --no-cache \
    # php-session \
    php-tokenizer \
    php-xml \
    php-ctype \
    php-curl \
    php-dom \
    php-fileinfo \
    php-mbstring \
    php-openssl \
    php-pdo \
    php-pdo_mysql \
    php-pdo_sqlite \
    php-sqlite3 \
    php-session \
    php-tokenizer \
    php-ctype \
    php-xmlwriter \
    php-xmlreader \
    php-simplexml \
    php-intl \
    php-exif

RUN docker-php-ext-install mysqli pdo_mysql pdo_sqlite

WORKDIR /srv/http

ADD overlay/ /

RUN mkdir -p /var/log/supervisor && \
    chmod +x /entrypoint.sh && \
    chmod +x /healthcheck.sh


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "" ]

HEALTHCHECK --start-period=5s --interval=10s --timeout=2s --retries=5 CMD /healthcheck.sh

EXPOSE 80