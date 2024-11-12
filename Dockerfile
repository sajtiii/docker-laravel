FROM dunglas/frankenphp:php8.3-alpine

ENV TZ=UTC

LABEL org.opencontainers.image.source=https://github.com/sajtiii/docker-laravel
LABEL org.opencontainers.image.description="A simple Laravel Octane container with Queue and Scheduler"
LABEL org.opencontainers.image.licenses="MIT"

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apk add --no-cache \
    supervisor \
    curl

# Packages required to run Octane (& Redis)
RUN install-php-extensions \
    pcntl \
    redis

# Packages required to run Laravel
RUN install-php-extensions \   
    ctype \
    curl \
    dom \
    fileinfo \
    mbstring \
    openssl \
    pdo \
    pdo_mysql \
    pdo_sqlite \
    pdo_pgsql \
    session \
    tokenizer \
    xml

# Commonly used extensions
RUN install-php-extensions \
    zip \
    intl \
    exif \
    gd

    
WORKDIR /srv/http

ADD overlay/ /

RUN mkdir -p /var/log/supervisor && \
    chmod +x /configuration.sh && \
    chmod +x /entrypoint.sh && \
    chmod +x /healthcheck.sh


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "" ]

EXPOSE 80

HEALTHCHECK --start-period=30s --interval=10s --timeout=2s --retries=5 CMD /healthcheck.sh
