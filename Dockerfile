FROM alpine:3.16

ENV PHP_VERSION=php81
ENV LARAVEL_VERSION=10

RUN apk add --no-cache \
    nginx \
    nginx-mod-http-headers-more \
    nginx-http-mod-brotli \
    $PHP_VERSION \
    $PHP_VERSION-bcmath \
    $PHP_VERSION-ctype \
    $PHP_VERSION-curl \
    $PHP_VERSION-dom \
    $PHP_VERSION-fileinfo \
    $PHP_VERSION-fpm \
    $PHP_VERSION-gd \
    $PHP_VERSION-iconv \
    $PHP_VERSION-json \
    $PHP_VERSION-mbstring \
    $PHP_VERSION-mysqli \
    $PHP_VERSION-pdo \
    $PHP_VERSION-pdo_mysql \
    $PHP_VERSION-pdo_sqlite \
    $PHP_VERSION-pecl-redis \
    $PHP_VERSION-phar \
    $PHP_VERSION-session \
    $PHP_VERSION-sodium \
    $PHP_VERSION-simplexml \
    $PHP_VERSION-sqlite3 \
    $PHP_VERSION-tokenizer \
    $PHP_VERSION-xml \
    $PHP_VERSION-xmlreader \
    $PHP_VERSION-xmlwriter \
    npm \
    supervisor

RUN install -d -o nginx -g nginx \
    /run/php \
    /var/log/nginx \
    /var/log/php \
    /var/log/supervisor 

RUN ln -s /usr/bin/$PHP_VERSION /usr/bin/php

RUN wget -O - https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/bin

RUN chown nginx:nignx /srv/http -R

COPY overlay /

WORKDIR /srv/http

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervirod.conf"]
