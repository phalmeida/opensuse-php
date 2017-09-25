FROM opensuse

MAINTAINER Philipe Allan Almeida <philipeph3@gmail.com>

RUN zypper --non-interactive --no-gpg-checks ref; \
    zypper clean

# instalando o Apache2
RUN zypper ref && zypper --non-interactive in apache2

RUN zypper --non-interactive in vim

RUN zypper --non-interactive in wget

# instalando o PHP 7 e os módulos necessários
RUN zypper --non-interactive in php7 \
    php7-pear \
    php7-phar \
    php7-bcmath \
    php7-bz2 \
    php7-calendar \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-enchant \
    php7-exif \
    php7-fileinfo \
    php7-fpm \
    php7-ftp \
    php7-gd \
    php7-gettext \
    php7-gmp \
    php7-iconv \
    php7-imap \
    php7-intl \
    php7-json \
    php7-ldap \
    php7-mbstring \
    php7-mcrypt \
    php7-mysql \
    php7-pgsql \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-posix \
    php7-pspell \
    php7-readline \
    php7-soap \
    php7-tidy \
    php7-tokenizer \
    php7-wddx \
    php7-xmlreader \
    php7-xmlrpc \ 
    php7-xmlwriter \ 
    php7-xsl \ 
    php7-zip \ 
    php7-zlib \ 
    apache2-mod_php7 
    
# instalando o módulo php7-devel para realizar a compilação das extensões
RUN zypper --non-interactive in php7-devel gcc make

# execute separadamente as configurações abaixo habilitando os módulos php7 e rewrite no apache2
RUN a2enmod php7
RUN a2enmod rewrite

# configurando a inicialização automática do apache
RUN chkconfig -a apache2

# Copia os arquivos para instalação e configuração do Instant Client
RUN cd /root
RUN mkdir src
RUN cd src

ADD ./InstantClientOracle/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm /root/src/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm

ADD ./InstantClientOracle/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm /root/src/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

# Realiza a instalação do Instant Client
RUN rpm -Uvh  /root/src/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
RUN rpm -Uvh  /root/src/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

# Criação das variáveis de ambiente do apache
RUN echo export ORACLE_HOME="/usr/lib/oracle/12.1/client64" >> /etc/sysconfig/apache2
RUN echo export LD_LIBRARY_PATH="/usr/lib/oracle/12.1/client64/lib" >> /etc/sysconfig/apache2

# Obtendo o source do PHP (7.0.7)
RUN cd /root/src
RUN wget -P /root/src/ http://be.php.net/distributions/php-7.0.7.tar.gz
RUN tar xfvz /root/src/php-7.0.7.tar.gz -C /root/src

# Compilando a extensão: PDO_OCI
RUN cd /root/src/php-7.0.7/ext/pdo_oci && phpize && ./configure --with-pdo-oci=instantclient,/usr,12.1 && make && make install
RUN echo extension=pdo_oci.so > /etc/php7/conf.d/pdo_oci.ini

# Compilando a extensão: OCI8
RUN cd /root/src/php-7.0.7/ext/oci8 && phpize && ./configure --with-oci8=shared,instantclient,/usr/lib/oracle/12.1/client64/lib && make && make install
RUN echo extension=oci8.so > /etc/php7/conf.d/oci8.ini

COPY ./web/* /srv/www/htdocs

RUN /usr/sbin/a2enmod php7

CMD /usr/sbin/apache2ctl -D FOREGROUND
VOLUME "/srv/www/htdocs"
EXPOSE 80