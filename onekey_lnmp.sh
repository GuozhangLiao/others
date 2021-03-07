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

#检测系统
check_os(){
    osver=$(sed -n '/^ID=/p' /etc/os-release | sed 's/ID=//;s/"//;s/"//')
    if [ "$osver" = centos ]
    then
        Blue "当前系统发行版本为：$osver"
    else
        Red "当前脚本只支持 centos 发行版"
        exit 1
    fi
}

#检查用户
check_user(){
    cur=$(id -u)
    if [ "$cur" -eq 0 ]
    then
        Blue "当前用户为root用户！"
    else
        Red "当前用户权限不足，请使用root用户执行脚本！"
        exit 1
    fi
    grep ^www /etc/passwd
    if ! grep ^www /etc/passwd;
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
    yum clean all
    yum makecache
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
    find / -name "nginx*" -exec rm -rf {} \;
}

#卸载 mariadb
remove_mdb(){
    if rpm -qa | grep mariadb
    then
        mb=$(rpm -qa | grep mariadb)
        rpm -e --nodeps "$mb"
        Green "卸载 Mariadb 成功！" 
    fi
}

#编译nginx
nginx_compile(){
    cd "$HOME" || return 0
    wget -O "$HOME"/nginx-1.18.0.tar.gz http://mirrors.sohu.com/nginx/nginx-1.18.0.tar.gz
    tar -zxvf "$HOME"/nginx-1.18.0.tar.gz
    cd "$HOME"/nginx-1.18.0 || return 0
    ./configure \
    --user=www \
    --group=www \
    --prefix=/www/nginx \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-threads \
    --with-pcre
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
PIDFile=/var/run/nginx.pid 
ExecStartPre=/www/nginx/sbin/nginx -t
ExecStart=/www/nginx/sbin/nginx -c /www/nginx/conf/nginx.conf
ExecReload=/www/nginx/sbin/nginx -s reload
ExecStop=/usr/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 /etc/systemd/system/nginx.service
    chown -R www:www /www
    systemctl start nginx
    Green "nginx 编译安装完成！"
}

#编译安装mysql
compile_mysql(){
    cd "$HOME" || return 0
    wget -O "$HOME"/mysql-5.7.30.tar.gz http://mirrors.sohu.com/mysql/MySQL-5.7/mysql-boost-5.7.30.tar.gz
    tar -zxvf "$HOME"/mysql-5.7.30.tar.gz
    mkdir "$HOME"/mysql-5.7.30/bld
    cd "$HOME"/mysql-5.7.30/bld || return 0
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
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=www
Group=www

Type=forking

PIDFile=/www/mysql/data/mysqld.pid

TimeoutSec=0

PermissionsStartOnly=true

#ExecStartPre=@bindir@/mysqld_pre_systemd

ExecStart=/www/mysql/bin/mysqld --daemonize --pid-file=/www/mysql/data/mysqld.pid

#EnvironmentFile=-/etc/sysconfig/mysql

LimitNOFILE = 5000

Restart=on-failure

RestartPreventExitStatus=1

PrivateTmp=false
EOF
    chmod 644 /etc/systemd/system/mysql.service
    chown -R www:www /www
    chown www:www /etc/my.cnf
    systemctl start mysqld
    /www/mysql/bin/mysqld --defaults-file=/etc/my.cnf --initialize --user=www
    Green "编译安装 mysql 完成！"
}

#编译安装php
compile_php(){
    cd "$HOME" || return 0
    wget https://mirrors.sohu.com/php/php-7.4.15.tar.gz
    tar -zxf "$HOME"/php-7.4.15.tar.gz
    cd "$HOME"/php-7.4.15 || return 0
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
    /www/php/bin/php -v
    cat > /etc/php.ini<<-EOF
[PHP]
engine = On
short_open_tag = On
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions = passthru,exec,system,putenv,chroot,chgrp,chown,shell_exec,popen,proc_open,pcntl_exec,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,imap_open,apache_setenv
disable_classes =
zend.enable_gc = On
zend.exception_ignore_args = On
expose_php = Off
max_execution_time = 300
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_NOTICE
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 50M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
cgi.fix_pathinfo = 1
file_uploads = On
upload_max_filesize = 50M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
date.timezone = PRC
[Pdo_mysql]
pdo_mysql.default_socket=
[mail function]
SMTP = localhost
smtp_port = 25
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[bcmath]
bcmath.scale = 0
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.cookie_samesite =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.sid_length = 26
session.trans_sid_tags = "a=href,area=href,frame=src,form="
session.sid_bits_per_character = 5
[Assertion]
zend.assertions = -1
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[ldap]
ldap.max_links = -1
[curl]
curl.cainfo = /etc/pki/tls/certs/ca-bundle.crt
[openssl]
openssl.cafile=/etc/pki/tls/certs/ca-bundle.crt
[ffi]
extension = zip.so
[Zend Opcache]
zend_extension=/www/php/lib/php/extensions/no-debug-non-zts-20190902/opcache.so
opcache.enable = 1
opcache.memory_consumption=128
opcache.interned_strings_buffer=32
opcache.max_accelerated_files=80000
opcache.revalidate_freq=3
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF
    chown www:www /etc/php.ini
    cat > /www/php/etc/php-fpm.conf<<-EOF
[global]
pid = /var/run/php-fpm.pid
error_log = /www/php/var/log/php-fpm.log
log_level = notice
[www]
listen = /tmp/php-cgi-74.sock
listen.backlog = 8192
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_status
pm.max_children = 30
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 10
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.lo
include=/www/php/etc/php-fpm.d/*.conf
EOF
    cat > /etc/systemd/system/php-fpm.service<<-EOF
[Unit]
Description=The PHP FastCGI Process Manager
After=network.target

[Service]
Type=simple
PIDFile=/var/run/php-fpm.pid
ExecStart=/www/php/sbin/php-fpm --nodaemonize --fpm-config /www/php/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 $MAINPID

PrivateTmp=true

ProtectSystem=full

PrivateDevices=true

ProtectKernelModules=true

ProtectKernelTunables=true

ProtectControlGroups=true

RestrictRealtime=true

RestrictAddressFamilies=AF_INET AF_INET6 AF_NETLINK AF_UNIX

RestrictNamespaces=true

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 /etc/systemd/system/php-fpm.service
    sed -i '/^user = nobody/s/nobody/www/g;/^group = nobody/s/nobody/www/g' /www/php/etc/php-fpm.d/www.conf
    chown -R www:www /www
    echo -e "PATH=/www/mysql/bin:/www/mysql/lib:/www/php/sbin:$PATH\nexport PATH"  >> /etc/profile
    Blue "php编译完成"
}

#mian
clear
check_os
check_user
remove_old_version
remove_mdb
system_update
install_depends
nginx_compile
compile_mysql
compile_php
Blue "lnmp编译完成"