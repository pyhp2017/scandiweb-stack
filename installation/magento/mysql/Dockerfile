FROM mysql:8.0.32

LABEL author=pyhp2017@gmail.com

# create a database instance named magento with username magento and given env password
ENV MYSQL_DATABASE=${MYSQL_DATABASE} \
    MYSQL_USER=${MYSQL_USER} \
    MYSQL_PASSWORD=${MYSQL_PASSWORD} \
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
    MYSQL_ROOT_HOST=${MYSQL_ROOT_HOST}

# For optimal performance, make sure all MySQL and Adobe Commerce or Magento Open Source index tables can be kept 
# in memory (for example, configure innodb_buffer_pool_size).
# see https://devdocs.magento.com/guides/v2.4/install-gde/prereq/mysql.html
ENV MYSQL_INITDB_ARGS="--innodb_buffer_pool_size=2G"

# Set bind-address to give access to the database from the host machine
# see https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/prerequisites/database-server/mysql-remote.html?lang=en
# ENV MYSQL_INITDB_ARGS="--bind-address="