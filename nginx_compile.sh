#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-02-08 19:31:05  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-02-08 19:31:05



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

#卸载旧版本
remove_old_version(){
    yum remove -y "nginx*"
    find / -name nginx* -exec rm -rf {} \;
}

#安装编译工具和依赖
install_depends(){
    yum update -y
    Green "升级系统完成！"
    yum install -y gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel wget
    Green "安装依赖完成！"
}

#编译安装nginx
nginx_compile(){
    install_depends
    cd $HOME
    wget http://nginx.org/download/nginx-1.18.0.tar.gz
    tar -zxvf $HOME/nginx-1.18.0.tar.gz
    cd $HOME/nginx-1.18.0
    groupadd nginx
    useradd -g nginx nginx -s /sbin/nologin
    ./configure \
    --user=nginx \
    --group=nginx \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-threads
    make && make install
    /usr/local/nginx/sbin/nginx -V
    ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
    cat > /etc/systemd/system/nginx.service<<-EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
Documentation=http://nginx.org/en/docs/
After=syslog.target network.target remote-fs.target nss-lookup.target
 
[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid  
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 /etc/systemd/system/nginx.service
    Green "nginx 编译安装完成！"
}

#检测是否已经安装安装nginx
check_nginx() {
    if ! nginx -v > /dev/null 2>&1
    then
        nginx_compile
    else
        Red "系统已经安装nginx,先卸载旧版本！"
        remove_old_version
    fi
}

#main
check_nginx