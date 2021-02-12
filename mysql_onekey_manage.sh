#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-02-04 10:05:04  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-02-04 10:05:04 

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
export PATH
mb=$(rpm -qa | grep mariadb)

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

#升级系统
system_update(){
    yum update -y
    Green "升级系统完成！"
}

#安装编译环境
tools_install(){
    yum -y install gcc gcc-c++ ncurses ncurses-devel wget bison openssl-devel unzip
    Green "依赖关系安装完成！"
}

#git连接加速
higher_speed(){
    echo "185.199.109.154  github-releases.githubusercontent.com" >> /etc/hosts
}

compile_cmake() {
    cd $HOME
    wget https://github.com/Kitware/CMake/releases/download/v3.19.4/cmake-3.19.4.tar.gz
    tar -zxvf $HOME/cmake-3.19.4.tar.gz
    cd $HOME/cmake-3.19.4
    Green "开始编译 cmake "
    ./bootstrap
    make && make install
    cmake -version
    Green "编译安装 cmake 完成！"
}

#卸载 mariadb
remove_mdb() {
    if rpm -qa | grep mariadb
    then
        rpm -e --nodeps $mb
        Green "卸载 Mariadb 成功！" 
    fi
}

compile_mysql() {
    groupadd mysql
    useradd mysql -g mysql -s /sbin/nologin
    mkdir $HOME/my_boost
    cd $HOME
    wget -O $HOME/mysql-5.7.30.tar.gz https://downloads.mysql.com/archives/get/p/23/file/mysql-boost-5.7.30.tar.gz
    tar -zxvf $HOME/mysql-5.7.30.tar.gz
    mkdir $HOME/mysql-5.7.30/bld
    cd $HOME/mysql-5.7.30/bld
    Green "开始编译 mysql-5.7.30 "
    cmake .. -DBUILD_CONFIG=mysql_release \
    -DCPACK_MONOLITHIC_INSTALL=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DFORCE_UNSUPPORTED_COMPILER=1 \
    -DIGNORE_AIO_CHECK=1 \
    -DMYSQL_MAINTAINER_MODE=0 \
    -DWITH_BOOST=/root/mysql-5.7.30/boost \
    -DWITH_CURL=system \
    -DWITH_SSL=system \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql/ \
    -DCMAKE_USER=mysql \
    -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
    -DSYSCONFDIR=/etc \
    -DSYSTEMD_PID_DIR=/usr/local/mysql/ \
    -DDEFAULT_CHARSET=utf8  \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
    -DWITH_READLINE=1 \
    -DMYSQL_DATADIR=/usr/local/mysql/data/ \
    -DWITH_SYSTEMD=1 \
    -DWITH_DEBUG=0 \
    -DENABLE_PROFILING=1
    Green "开始安装 mysql"
    make && make install
    chown -R mysql:mysql /usr/local/mysql/
    /usr/local/mysql/bin/mysql --version
    cat > /etc/my.cnf<<-EOF

[client]
port = 3306
default-character-set=utf8
socket = /usr/local/mysql/mysql.sock

[mysqld]
user = mysql
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
port = 3306
default-character-set=utf8
socket = /usr/local/mysql/mysql.sock
pid-file = /usr/local/mysql/mysqld.pid
log-error=/var/log/mysqld.log
server-id = 1
EOF
    chown mysql:mysql /etc/my.cnf
    echo -e "PATH=/usr/local/mysql/bin:/usr/local/mysql/lib:$PATH\nexport PATH" >> /etc/profile
    source /etc/profile
    Green "编译安装 mysql 完成！"
    mysqld \
    --initialize-insecure \
    --user=mysql \
    --basedir=/usr/local/mysql \
    --datadir=/usr/local/mysql/data
}

#main
system_update
tools_install
#higher_speed
compile_cmake
remove_mdb
compile_mysql