FROM centos:centos7

MAINTAINER Patrick Kaiser "docker@pk.banovo.de"

RUN PKGS_main="php-cli php-fpm php-gd php-intl php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pecl-apcu php-pecl-http php-pecl-memcached php-pecl-memcached php-pecl-redis php-pecl-xdebug php-pecl-zip php-process php-soap php-xml" \

    # Install Packages
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y install yum-utils \
    && yum-config-manager --enable remi-php70 \
    && yum update -y \
    && yum -y install ${PKGS_main} \
    && yum -y clean all \

    # Add User (really needed?)
    && adduser -u 1000 -s /sbin/nologin -r nginx \
    && usermod -u 1000 nginx \

    # Redirect logfile output to stderr/out
    && touch /var/log/php-fpm/{access,error}.log \
    && ln -sf /dev/stderr /var/log/php-fpm/error.log \
    && ln -sf /dev/stdout /var/log/php-fpm/access.log \

    # Fix permissions
    && chown -R nginx.nginx /var/lib/php /var/log/php-fpm

    # Configure PHP
RUN { \
        echo; \
        echo '; CUSTOM CONFIG ;'; \
        echo 'short_open_tag = On'; \
        echo 'cgi.fix_pathinfo = 0'; \
        echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT'; \
        echo 'error_log = /var/log/php-fpm/error.log'; \
        echo 'display_errors = On'; \
        echo 'post_max_size = 200M'; \
        echo 'upload_max_filesize = 200M'; \
        echo 'memory_limit = 256M'; \
        echo 'max_execution_time = 60'; \
        echo 'max_input_time = 90'; \
        echo; \
        echo '[Date]'; \
        echo 'date.timezone = Europe/Berlin'; \
        echo; \
    } | tee -a /etc/php.ini \
    && sed -i -e 's/listen.allowed_clients = 127.0.0.1/;listen.allowed_clients = 127.0.0.1/g' /etc/php-fpm.d/www.conf \
    && { \
        echo; \
        echo '; CUSTOM CONFIG ;'; \
        echo '[global]'; \
        echo 'error_log = /var/log/php-fpm/error.log'; \
        echo 'daemonize = no'; \
        echo; \
        echo '[www]'; \
        echo 'user = nginx'; \
        echo 'group = nginx'; \
        echo 'access.log = /var/log/php-fpm/access.log'; \
        echo 'slowlog = /var/log/php-fpm/access.log'; \
        echo 'listen = 9000'; \
        echo; \
        echo 'clear_env = no'; \
        echo; \
        echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
        echo 'catch_workers_output = yes'; \
    } | tee /etc/php-fpm.d/zz-docker.conf \
    && echo 'xdebug.default_enable=0' >> /etc/php.d/xdebug.ini \

VOLUME ["/data/app"]
WORKDIR /data/app
EXPOSE 9000

CMD ["/usr/sbin/php-fpm", "--force-stderr",  "--nodaemonize", "--fpm-config", "/etc/php-fpm.conf", "-c", "/etc/php.ini"]
