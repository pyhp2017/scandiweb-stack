FROM php:8.1.0-fpm

LABEL author=pyhp2017@gmail.com

# Install dependencies
RUN apt-get update \
&& apt-get install -y \
procps \
libcurl4-openssl-dev \
libfreetype6-dev \
libldap2-dev \
libicu-dev \
libjpeg62-turbo-dev \
libmcrypt-dev \
libpng-dev \
libxslt1-dev \
libzip-dev \
libsodium-dev \
libonig-dev \
libpq-dev \
npm \
webp \
optipng \
jpegoptim \
jq \
gifsicle \
sudo

# Configure the gd library
RUN docker-php-ext-configure \
gd --with-freetype --with-jpeg

#Install xdebug
RUN apt-get update && apt-get install -y wget git unzip \
	&& pecl install xdebug-3.2.0 \
	&& docker-php-ext-enable xdebug


#Install php ext (Magento Open Source requires: 
# https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/prerequisites/php-settings.html?lang=en)
RUN docker-php-ext-install \
pdo_mysql \
soap \
bcmath \
gd \
xsl \
zip \
sockets \
intl

# Set the system time zone for PHP
# see https://www.php.net/manual/en/datetime.configuration.php#ini.date.timezone
RUN echo "date.timezone = UTC" > /usr/local/etc/php/conf.d/date_timezone.ini

# Set the PHP memory limit.
# see https://www.php.net/manual/en/ini.core.php#ini.memory-limit
RUN echo "memory_limit = 2G" > /usr/local/etc/php/conf.d/memory_limit.ini

# Increase the values for the PHP realpath_cache_size and realpath_cache_ttl to recommended settings:
# see https://www.php.net/manual/en/ini.core.php#ini.realpath-cache-size
# see https://www.php.net/manual/en/ini.core.php#ini.realpath-cache-ttl
RUN echo "realpath_cache_size = 10M" > /usr/local/etc/php/conf.d/realpath_cache.ini
RUN echo "realpath_cache_ttl = 7200" >> /usr/local/etc/php/conf.d/realpath_cache.ini

# Enable opcache.save_comments
# see https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.save-comments
RUN echo "opcache.save_comments = 1" > /usr/local/etc/php/conf.d/opcache_save_comments.ini

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy bootstrap script
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Set permissions
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set working directory
WORKDIR /var/www/html/magento

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Expose port 9000 and start php-fpm server
EXPOSE 9000
