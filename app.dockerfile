FROM php:7.2-apache-stretch
WORKDIR /var/www/html/laravel
COPY . .
# INSTALL COMPOSER.
RUN apt-get update && \
    apt-get install -y --no-install-recommends git zip
# INSTALL COMPOSER.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install

RUN chgrp -R www-data .
RUN chmod -R 775 ./storage
COPY laravel.conf /etc/apache2/sites-available
RUN a2dissite 000-default.conf
RUN a2ensite laravel.conf
RUN a2enmod rewrite