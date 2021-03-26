FROM php:7.4.12-fpm-alpine

COPY ./php/crontab /etc/crontabs/root

ADD ./php/localtime /etc/localtime

RUN docker-php-ext-install pdo pdo_mysql

CMD ["crond", "-f"]

