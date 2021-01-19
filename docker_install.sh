#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-01-18 23:30:08  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-01-18 23:30:08

A=$(uname -r | cut -d "." -f1-2)

#检验内核版本
CheckVersion(){
    if [ $A -ge 3.10 ]
    then
        DockerInstall
    else
        echo "内核版本低于3.10,请升级内核版本"
    fi
}

#安装docker
DockerInstall(){
    #卸载旧版本
    yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate  docker-engine
    #设置仓库
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    #安装docker引擎
    yum -y install docker-ce docker-ce-cli containerd.io
    #设置开机自启和运行docker
    
}


