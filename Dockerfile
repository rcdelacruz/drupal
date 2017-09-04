FROM debian:stretch
MAINTAINER Rolando Payán Mosqueda <rpayanm@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

# Repositories
COPY ./files/sources.list /etc/apt/

# Install packages
RUN apt-get update \
&& apt-get install -y \
	nano \
	locate \
	git \
	nginx \
	php7.0-dev \
	php7.0-fpm \
	php7.0-cli \
	php7.0-mysql \
	php7.0-gd \
	php7.0-curl \
	curl \
	supervisor \
	bash-completion \
&& apt-get clean

# PHP custom configuration
# php-fpm7.0
RUN mkdir -p /var/run/php \
&& sed -i "s#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#" /etc/php/7.0/fpm/php.ini \
&& sed -i "s#display_errors = Off#display_errors = On#" /etc/php/7.0/fpm/php.ini \
&& sed -i "s#memory_limit = 128M#memory_limit = 512M#" /etc/php/7.0/fpm/php.ini \
&& sed -i "s#memory_limit = 128M#memory_limit = 512M#" /etc/php/7.0/fpm/php.ini \
&& sed -i "s#;always_populate_raw_post_data = -1#always_populate_raw_post_data = -1#" /etc/php/7.0/fpm/php.ini \
&& sed -i "s#post_max_size = 8M#post_max_size = 100M#" /etc/php/7.0/fpm/php.ini \
# CLI
&& sed -i "s#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#" /etc/php/7.0/cli/php.ini \
&& sed -i "s#display_errors = Off#display_errors = On#" /etc/php/7.0/cli/php.ini \
&& sed -i "s#upload_max_filesize = 2M#upload_max_filesize = 100M#" /etc/php/7.0/cli/php.ini \
&& sed -i "s#post_max_size = 8M#post_max_size = 100M#" /etc/php/7.0/cli/php.ini

# XDebug
RUN cd /tmp \
 && git clone https://github.com/derickr/xdebug \
 && cd xdebug \
 && phpize \
 && ./configure --enable-xdebug \
 && make \
 && make install

# Xdebug settings for php5-fpm
COPY ./files/xdebug.ini /tmp/
RUN cat /tmp/xdebug.ini >> /etc/php/7.0/fpm/php.ini \
&& export XDEBUG_SOURCE=`find /usr/lib -name "xdebug.so"` \
&& sed -i "s#xdebug_so_path#$XDEBUG_SOURCE#" /etc/php/7.0/fpm/php.ini

# Xdebug setting for the command line
RUN cat /tmp/xdebug.ini >> /etc/php/7.0/cli/php.ini \
&& export XDEBUG_SOURCE=`find /usr/lib -name "xdebug.so"` \
&& sed -i "s#xdebug_so_path#$XDEBUG_SOURCE#" /etc/php/7.0/cli/php.ini

# nginx
COPY ./files/drupal* /etc/nginx/snippets/

# autocomplete in root
COPY ./files/autocomplete /tmp/
RUN cat /tmp/autocomplete >> /root/.bashrc && /bin/bash -c "source /root/.bashrc"

# Setup Supervisor
COPY ./files/supervisord.conf /etc/supervisor/conf.d/

# Drupal private folder
RUN mkdir /mnt/private/

COPY ./files/start.sh /start.sh
RUN chmod 755 /start.sh

RUN rm -R /tmp/*

EXPOSE 80
CMD ["/bin/bash", "/start.sh"]
