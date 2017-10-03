FROM opensuse:leap

MAINTAINER Philipe Allan Almeida <philipeph3@gmail.com>

RUN zypper --non-interactive --no-gpg-checks ref; \
    zypper clean

# instalando o Apache2
RUN zypper ref && zypper --non-interactive in apache2

# Instalação do Gzip
RUN zypper --non-interactive in gzip

# Instalação do Unzip
RUN zypper --non-interactive in unzip

# Instalação do Ksh
RUN zypper --non-interactive in ksh

# Instalação do Vim
RUN zypper --non-interactive in vim

# Instalação do Git
RUN zypper --non-interactive in git

# Instalação do Wget
RUN zypper --non-interactive in wget

# Instalação do unixODBC
RUN zypper --non-interactive in unixODBC

# Instalação do unixODBC-devel
RUN zypper --non-interactive in unixODBC-devel

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

# Instalação do Composer
RUN zypper --non-interactive in php-composer

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
ENV ORACLE_HOME "/usr/lib/oracle/12.1/client64"
ENV LD_LIBRARY_PATH "/usr/lib/oracle/12.1/client64/lib"

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

# Crie uma nova pasta para armazenar o Driver IBM no servidor.
RUN mkdir /opt/ibm

# Copia os arquivos para instalação e configuração do Driver DB2
COPY ./InstantClientOracle/ibm_data_server_driver_package_linuxx64_v11.1.tar.gz /opt/ibm/ibm_data_server_driver_package_linuxx64_v11.1.tar.gz

# Descompacta o arquivo IBM Data Server Driver Package.
RUN tar xfvz /opt/ibm/ibm_data_server_driver_package_linuxx64_v11.1.tar.gz -C /opt/ibm/

# Acesse a pasta dsdriver e iniciar a instalação do IBM Data Server Driver Package
RUN cd /opt/ibm/dsdriver && ksh installDSDriver

#Criar as variáveis de ambiente.
RUN echo export IBM_DB_HOME="/opt/ibm/dsdriver" >> /etc/profile.local
ENV IBM_DB_HOME "/opt/ibm/dsdriver"
ENV LD_LIBRARY_PATH "/opt/ibm/dsdriver/lib;/usr/lib/oracle/12.1/client64/lib"
RUN ln -s /opt/ibm/dsdriver/include /include

# Copia os arquivos para instalação e configuração da extensão ibm_db2
COPY ./InstantClientOracle/ibm_db2-2.0.0.tgz /opt/ibm/ibm_db2-2.0.0.tgz

# Descompacta o arquivo
RUN tar xfvz /opt/ibm/ibm_db2-2.0.0.tgz -C /opt/ibm/

# Instalação e configuração da extensão ibm_db2
RUN cd /opt/ibm/ibm_db2-2.0.0 && phpize --clean && phpize && ./configure && make && make install
RUN echo extension=ibm_db2.so > /etc/php7/conf.d/ibm_db2.ini

#Instalação e configuração da extensão PDO_IBM
RUN cd /opt/ibm && git clone https://github.com/dreamfactorysoftware/PDO_IBM-1.3.4-patched.git && cd PDO_IBM-1.3.4-patched/ && phpize 
RUN cd /opt/ibm/PDO_IBM-1.3.4-patched/ && ./configure --with-pdo-ibm=/opt/ibm/dsdriver/lib && make && make install
RUN cd /opt/ibm/PDO_IBM-1.3.4-patched/ && make && make install
RUN echo extension=pdo_ibm.so > /etc/php7/conf.d/pdo_ibm.ini

# Compilando a extensão: PDO_ODBC
RUN cd /root/src/php-7.0.7/ext/pdo_odbc && phpize && ./configure --with-pdo-odbc=unixODBC,/usr/ && make && make install
RUN echo extension=pdo_odbc.so > /etc/php7/conf.d/pdo_odbc.ini


# Configuração do Xdebug
RUN pecl install xdebug
RUN echo zend_extension=/usr/lib64/php7/extensions/xdebug.so >> etc/php7/apache2/php.ini
RUN echo [XDebug] >> etc/php7/apache2/php.ini
RUN echo xdebug.remote_enable = 1 >> etc/php7/apache2/php.ini
RUN echo xdebug.remote_autostart = 1 >> etc/php7/apache2/php.ini

# Apaga os arquivos utilizados
RUN rm -Rf /root/src/*
RUN rm -f /opt/ibm/ibm_data_server_driver_package_linuxx64_v11.1.tar.gz

COPY ./web/* /srv/www/htdocs

RUN /usr/sbin/a2enmod php7

VOLUME "/srv/www/htdocs"
EXPOSE 80

CMD /usr/sbin/apache2ctl -D FOREGROUND
