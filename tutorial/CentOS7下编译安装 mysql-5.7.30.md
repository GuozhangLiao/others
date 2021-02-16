# CentOS7下编译安装 mysql-5.7.30

## 更新系统

```
# yum update
```


## 安装依赖

mysql-5.7需要依赖的软件：`gcc gcc-c++ ncurses ncurses-devel wget bison openssl-devel unzip cmake`

可以直接通过 `yum` 命令安装

```
# yum installl gcc gcc-c++ ncurses ncurses-devel wget bison openssl-devel unzip cmake
```

## 卸载旧版本的 MYSQL 或者系统 自带的 Mariadb

检查系统是否已经安装了 mysql 或者 mariadb

```
# rpm -qa | grep mysql
# rpm -qa | grep mariadb
```

 如果系统已经自带 mariadb 可以通过下面命令将其卸载

```
# rpm -e --nodeps mariadb
```

注意版本号

## 获取 mysql 源码

mysql的官方源码地址：<https://downloads.mysql.com/archives/community/>

可根据需要下载指定版本的源码。官方提供两个版本的源码包，一个是带 `Boost` 的，另一个不带的。`Boost`在编译时需要用到

这里以 `mysql-5.7.30` 为例

```
# wgethttps://downloads.mysql.com/archives/get/p/23/file/mysql-boost-5.7.30.tar.gz
```

## 解包源码包

下载回来的源码包是以 `.tar.gz` 格式的文件，可以直接使用 `tar` 命令接包

```
# tar -zxvf mysql-boost-5.7.30.tar.gz
```

## 创建安装路径和用户和用户组

```
# groupadd mysql
# useradd mysql -g mysql -s /sbin/nologin
# mkdir /usr/local/mysql
# mkdir /usr/local/mysql/data
```

## 配置 cmake 编译参数

通过 `tar` 命令解包源码包后，在当前路径生成一个源码文件夹，在源码文件中创建 `bld` 文件夹，在 `bld` 中执行 `cmake` 预编译

```
# mkdir /mysql-5.7.30/bld
# cd /mysql-5.7.30/bld
# cmake .. -DCPACK_MONOLITHIC_INSTALL=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DFORCE_UNSUPPORTED_COMPILER=1 \
    -DMYSQL_MAINTAINER_MODE=0 \
    -DWITH_BOOST=/root/mysql-5.7.30/boost \
    -DWITH_CURL=system \
    -DWITH_SSL=system \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
    -DCMAKE_USER=mysql \
    -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
    -DSYSCONFDIR=/etc \
    -DSYSTEMD_PID_DIR=/usr/local/mysql/ \
    -DDEFAULT_CHARSET=utf8  \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_READLINE=1 \
    -DMYSQL_DATADIR=/usr/local/mysql/data \
    -DWITH_SYSTEMD=1 \
    -DWITH_DEBUG=0 \
    -DENABLE_PROFILING=1
```

 ## 编译和安装

如何预编译过程没有报错，就可以执行编译和安装

```
# make && make install
```

安装玩检验 `mysql` 的版本

```
# /usr/local/mysql/bin/mysql --version
```

## 创建 mysql 的配置文件

编译是指定了 `mysql` 的主配置路径在 `/etc` 下

```
# cat > /etc/my.cnf<<-EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
pid-file=/usr/local/mysql/data/mysqld.pid
log-error=/usr/local/mysql/data/mysql.err
socket=/usr/local/mysql/mysql.sock
user=mysql
port=3306
character-set-server=utf8
server-id=1
EOF
```

## 创建 mysql.service 单元文件

在 `/etc/systemd/system` 下创建 `mysql.service` 单元文件，让 `systemd` 控制 `mysql` 

```
# cat > /etc/systemd/system/mysql.service<<-EOF
[Unit]
Description=MySQL Server
After=network.target
After=syslog.target

[Service]
Type=forking

User=mysql
Group=mysql

PIDFile=/usr/local/mysql/data/mysqld.pid

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root
PermissionsStartOnly=true

# Needed to create system tables
#ExecStartPre=/usr/bin/mysqld_pre_systemd

# Start main service
ExecStart=/usr/local/mysql/bin/mysqld --daemonize --pid-file=/usr/local/mysql/data/mysqld.pid
 
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
```

```
# chmod 644 /etc/systemd/system/mysql.service
```

## 更改文件所有者和所有组

将 `mysql` 的所以文件的所有者和所有组该为用户 `mysql` 

```
# chown -R mysql:mysql /usr/local/mysql/
# chown mysql:mysql /etc/my.cnf
```

## 初始化 mysql 

第一次运行 `mysql` 必须进行初始化，`--initialize` 会给 `root` 用户随机生成一组密码，密码出行在日子中

```
# /usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf --initialize --user=mysql
```

## 管理 mysql 服务

通过 `systemd` 管理 `mysql` 服务器

运行 `mysql`

```
# systemctl start mysql.service
```

停止 `mysql`

```
# systemctl stop mysql.service
```

## 连接 mysql 

初始后，系统会给 `root` 用户生成随机密码，可以通过随机密码链接数据库，再修改 `root` 用户密码

```
# mysql -u root -p
```

登陆数据库后，可以使用 ` alter user`  命令修改 `root` 用户的密码

```
# ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';
```

