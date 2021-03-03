#!/usr/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-03-02 15:37:46  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-03-02 15:37:46  

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
export PATH

#颜色
Green(){
    echo -e "\033[32;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

#检查用户
check_user() {
    if [ $(id -u) -eq 0 ]
    then
        Blue "当前用户为root用户！"
    else
        Red "当前用户权限不足，请使用root用户执行脚本！"
        exit 1
    fi
    
    if ！ grep ^www /etc/passwd
    then
        groupadd www
        useradd -g www www -s /sbin/nologin
    else
        Red "用户www已经存在，无需创建"
    fi
    
    for nmp in nginx mysql php
    do
        mkdir -p /www/$nmp
    done
}



#更新系统
system_update(){
    yum update -y
    yum install -y epel-release
    Green "升级系统完成！"
}

#安装所有依赖
install_depends(){
    yum -y install gcc \
    gcc-c++ \
    sqlite \
    sqlite-devel \
    oniguruma \
    oniguruma-devel \
    libxml2 \
    libxml2-devel \
    openssl \
    openssl-devel \
    bzip2 \
    bzip2-devel \
    libcurl \
    libcurl-devel \
    libjpeg \
    libjpeg-devel \
    libpng \
    libpng-devel \
    freetype \
    freetype-devel \
    gmp \
    gmp-devel \
    libmcrypt \
    libmcrypt-devel \
    readline \
    readline-devel \
    libxslt \
    libxslt-devel \
    zlib \
    zlib-devel \
    glibc \
    glibc-devel \
    glib2 \
    glib2-devel \
    curl \
    gdbm-devel \
    db4-devel \
    libXpm-devel \
    libX11-devel \
    gd-devel \
    expat-devel \
    xmlrpc-c \
    xmlrpc-c-devel \
    libicu-devel \
    libmcrypt-devel \
    libmemcached-devel \
    pcre \
    pcre-devel \
    wget \
    ncurses \
    ncurses-devel \
    bison \
    unzip \
    cmake
}

#卸载nginx旧版本
remove_old_version(){
    yum remove -y "nginx*"
    find / -name nginx* -exec rm -rf {} \;
}

#卸载 mariadb
remove_mdb() {
    if rpm -qa | grep mariadb
    then
        local mb=$(rpm -qa | grep mariadb)
        rpm -e --nodeps $mb
        Green "卸载 Mariadb 成功！" 
    fi
}

#编译nginx
nginx_compile(){
    cd $HOME
    wget http://nginx.org/download/nginx-1.18.0.tar.gz
    tar -zxvf $HOME/nginx-1.18.0.tar.gz
    cd $HOME/nginx-1.18.0
    ./configure \
    --user=www \
    --group=www \
    --prefix=/www/nginx \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-threads
    make && make install
    /www/nginx/sbin/nginx -V
    ln -s /www/nginx/sbin/nginx /usr/bin/nginx
    cat > /etc/systemd/system/nginx.service<<-EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
Documentation=http://nginx.org/en/docs/
After=syslog.target network.target remote-fs.target nss-lookup.target
 
[Service]
Type=forking
PIDFile=/www/nginx/logs/nginx.pid  
ExecStartPre=/www/nginx/sbin/nginx -t
ExecStart=/www/nginx/sbin/nginx -c /www/nginx/conf/nginx.conf
ExecReload=/www/nginx/sbin/nginx -s reload
ExecStop=/usr/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 /etc/systemd/system/nginx.service
    Green "nginx 编译安装完成！"
}

#编译安装mysql
compile_mysql(){
    cd $HOME
    wget -O $HOME/mysql-5.7.30.tar.gz https://downloads.mysql.com/archives/get/p/23/file/mysql-boost-5.7.30.tar.gz
    tar -zxvf $HOME/mysql-5.7.30.tar.gz
    mkdir $HOME/mysql-5.7.30/bld
    cd $HOME/mysql-5.7.30/bld
    Green "开始编译 mysql-5.7.30 "
    cmake .. -DCPACK_MONOLITHIC_INSTALL=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DFORCE_UNSUPPORTED_COMPILER=1 \
    -DMYSQL_MAINTAINER_MODE=0 \
    -DWITH_BOOST=/root/mysql-5.7.30/boost \
    -DWITH_CURL=system \
    -DWITH_SSL=system \
    -DCMAKE_INSTALL_PREFIX=/www/mysql \
    -DCMAKE_USER=mysql \
    -DMYSQL_UNIX_ADDR=/www/mysql/mysql.sock \
    -DSYSCONFDIR=/etc \
    -DSYSTEMD_PID_DIR=/www/mysql/ \
    -DDEFAULT_CHARSET=utf8  \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_READLINE=1 \
    -DMYSQL_DATADIR=/www/mysql/data \
    -DWITH_SYSTEMD=1 \
    -DWITH_DEBUG=0 \
    -DENABLE_PROFILING=1
    make && make install
    chmod -R www:www /www/mysql/
    /www/mysql/bin/mysql --version
    cat > /etc/my.cnf<<-EOF
[mysqld]
basedir=/www/mysql
datadir=/www/mysql/data
pid-file=/www/mysql/data/mysqld.pid
log-error=/www/mysql/data/mysql.err
socket=/www/mysql/mysql.sock
user=www
port=3306
character-set-server=utf8
server-id=1
EOF
    cat > /etc/systemd/system/mysql.service<<-EOF
[Unit]
Description=MySQL Server
After=network.target
After=syslog.target

[Service]
Type=forking

User=www
Group=www

PIDFile=/www/mysql/data/mysqld.pid

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root
PermissionsStartOnly=true

# Needed to create system tables
#ExecStartPre=/usr/bin/mysqld_pre_systemd

# Start main service
ExecStart=/www/mysql/bin/mysqld --daemonize --pid-file=/www/mysql/data/mysqld.pid
 
# Use this to switch malloc implementation
#EnvironmentFile=-/etc/sysconfig/mysql

# Sets open_files_limit
LimitNOFILE = 5000

Restart=on-failure

RestartPreventExitStatus=1

PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 /etc/systemd/system/mysql.service
    chown www:www /etc/my.cnf
    /www/mysql/bin/mysqld --defaults-file=/etc/my.cnf --initialize --user=www
    Green "编译安装 mysql 完成！"
}

#编译安装php
compile_php(){
    cd $HOME
    wget https://mirrors.sohu.com/php/php-7.4.15.tar.gz
    tar -zxf $HOME/php-7.4.15.tar.gz
    cd $HOME/php-7.4.15
    ./configure \
    --prefix=/www/php \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-config-file-path=/etc \
    --enable-fpm \
    --enable-inline-optimization \
    --disable-debug \
    --disable-rpath \
    --enable-shared  \
    --enable-soap \
    --with-libxml-dir \
    --with-xmlrpc \
    --with-openssl \
    --with-mcrypt \
    --with-mhash \
    --with-pcre-regex \
    --with-sqlite3 \
    --with-zlib \
    --enable-bcmath \
    --with-iconv \
    --with-bz2 \
    --enable-calendar \
    --with-curl \
    --with-cdb \
    --enable-dom \
    --enable-exif \
    --enable-fileinfo \
    --enable-filter \
    --with-pcre-dir \
    --enable-ftp \
    --with-gd \
    --with-openssl-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --with-zlib-dir  \
    --with-freetype-dir \
    --enable-gd-native-ttf \
    --enable-gd-jis-conv \
    --with-gettext \
    --with-gmp \
    --with-mhash \
    --enable-json \
    --enable-mbstring \
    --enable-mbregex \
    --enable-mbregex-backtrack \
    --with-libmbfl \
    --with-onig \
    --enable-pdo \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-zlib-dir \
    --with-pdo-sqlite \
    --with-readline \
    --enable-session \
    --enable-shmop \
    --enable-simplexml \
    --enable-sockets  \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-wddx \
    --with-libxml-dir \
    --with-xsl \
    --enable-zip \
    --enable-mysqlnd-compression-support \
    --with-pear \
    --enable-opcache
    make && make install
    cp php.ini-production /etc/php.ini
    cp /www/php/etc/php-fpm.conf.default /www/php/etc/php-fpm.conf
    cp /www/php/etc/php-fpm.d/www.conf.default /www/php/etc/php-fpm.d/www.conf
    /www/php/bin/php -v
    
}