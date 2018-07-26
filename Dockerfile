FROM ubuntu:17.10

ENV DEBIAN_FRONTEND noninteractive

## Install php nginx mysql supervisor
RUN apt update && \
    apt install -y php7.1-fpm php7.1-mysql php7.1-gd php7.1-mcrypt php7.1-mysql php7.1-curl php7.1-dom php7.1-mbstring php7.1-zip php-mongodb \
                       nginx \
                       curl \
                       git \
		       supervisor && \
    echo "mysql-server mysql-server/root_password password" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password" | debconf-set-selections && \
    apt install -y mysql-server && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash && \
    rm -rf /var/lib/apt/lists/*

RUN export NVM_DIR="$HOME/.nvm" && \
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
nvm install v8.11.3

## Configuration
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php\/cgi.log/' /etc/php/7.1/fpm/php.ini && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php\/cli.log/' /etc/php/7.1/cli/php.ini && \
    sed -i 's/^key_buffer\s*=/key_buffer_size =/' /etc/mysql/my.cnf

RUN apt-get update
RUN apt-get install htop && apt-get install nano
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"  && \
php composer-setup.php  && \
php -r "unlink('composer-setup.php');" && \
mv composer.phar /usr/local/bin/composer

ADD ./files/root /
RUN sed -i 's/\r//' /entrypoint.sh

WORKDIR /var/www/

VOLUME ["/var/www/", "/etc/nginx/sites-enabled/", "/var/lib/mysql/"]

EXPOSE 80
EXPOSE 4040
ENTRYPOINT ["/entrypoint.sh"]
