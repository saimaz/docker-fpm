FROM php:7.0-fpm

# Install selected extensions and other stuff
RUN apt-get update && apt-get install -y \
        git-core zlib1g-dev \
        libicu-dev libmcrypt-dev libbz2-dev libxslt-dev curl unzip wget \
    && docker-php-ext-install -j$(nproc) mysqli intl bcmath mcrypt zip bz2 mbstring pcntl xsl pdo pdo_mysql

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Install Composer
RUN php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot && rm -rf /tmp/composer-setup.php

# Install Blackfire probe
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

# Install Xdebug
RUN pecl install xdebug \
 && printf "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so;xdebug.default_enable=0\nxdebug.remote_enable=1\nxdebug.remote_autostart=0\nxdebug.remote_port=9000\nxdebug.idekey=PHPSTORM\nxdebug.remote_host=10.254.254.254\nxdebug.remote_connect_back=0\nxdebug.profiler_enable=0" > $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
 && docker-php-ext-enable xdebug

WORKDIR "/var/www"
