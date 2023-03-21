#!/bin/sh

mkdir -p /var/www/html/magento
# Create a Composer project using the Magento Open Source with given authentication keys (MAGENTO_PUBLIC_KEY, MAGENTO_PRIVATE_KEY)
composer create-project --repository=https://${MAGENTO_PUBLIC_KEY}:${MAGENTO_PRIVATE_KEY}@repo.magento.com/ \
    magento/project-community-edition /var/www/html/magento --no-interaction

# Install Magento Open Source
bin/magento setup:install \
	--base-url=${MAGENTO_BASE_URL} \
	--db-host=${MAGAENTO_DB_HOST} \
	--db-name=${MYSQL_DATABASE} \
	--db-user=${MYSQL_USER} \
	--db-password=${MYSQL_PASSWORD} \
	--admin-firstname=${MAGENTO_ADMIN_FIRSTNAME} \
	--admin-lastname=${MAGENTO_ADMIN_LASTNAME} \
	--admin-email=${MAGENTO_ADMIN_EMAIL} \
	--admin-user=${MAGENTO_ADMIN_USER} \
	--admin-password=${MAGENTO_ADMIN_PASSWORD} \
	--language=${MAGENTO_LANGUAGE} \
	--currency=${MAGENTO_CURRENCY} \
	--timezone=${MAGENTO_TIMEZONE} \
	--use-rewrites=1 \
	--search-engine=elasticsearch7 \
	--elasticsearch-host=${MAGENTO_ELASTICSEARCH_HOST} \
	--elasticsearch-port=${MAGENTO_ELASTICSEARCH_PORT} \
	--elasticsearch-index-prefix=${MAGNETO_INDEX_PREFIX} \
	--backend-frontname=${MAGENTO_BACKEND_FRONTNAME} \
	--elasticsearch-timeout=15

# Disable Magento TwoFactorAuth
bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth
bin/magento module:disable Magento_TwoFactorAuth

# Enable varnish cache
bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2

# Create the Commerce crontab
bin/magento cron:install

# Run cron
bin/magento cron:run

# Set read-write permissions for the web server group before you install the application
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && \
	find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + && \
	chown -R :www-data . && \
	chmod u+x bin/magento

# Run php-fpm
php-fpm
