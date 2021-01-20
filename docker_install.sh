#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-01-18 23:30:08  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-01-18 23:30:08

A=$(uname -r | cut -d "." -f1)
SCRIPT="docker_install.sh"

#检验内核版本
CheckVersion(){
    if [ $A -ge 3 ]
    then
        DockerInstall
    else
        echo "内核版本低于3.10,请升级内核版本"
    fi
}

#安装docker
DockerInstall(){
    #卸载旧版本
    yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate  docker-engine > /dev/null
    #设置仓库
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    #安装docker引擎
    yum -y install docker-ce docker-ce-cli containerd.io
    #设置开机自启和运行docker
    systemctl enable docker > /dev/null
    systemctl start docker
    echo "docker 安装成功"
    echo "....."
    echo ".........."
    echo "..............."
    echo "....................."
}

#启动docker
STARTDocker(){
    systemctl start docker
}

#停止docker
STOPDocker(){
    systemctl stop docker
}

#重启docker
RELOADDocker(){
    systemctl reload docker
}

#测试doucker
TESTDocker(){
    docker run hello-world
    echo
    echo
    echo
}

#卸载docker
REMOVEDocker(){
    yum remove -y docker-ce-cli.x86_64 docker-ce.x86_64 docker-ce-rootless-extras.x86_64
    find / -name docker -exec rm -rf {} \;
    echo "----------------------------------卸载docker完成"
    find / -name $SCRIPT -exec rm -f {} \;
}

#脚本菜单
STARTMenu(){
    clear
    echo "========================================================================="
    echo "#                                                                       #"
    echo "#                  @Name: docker_oneclick_install_script                #"
    echo "#                  @Author: Aliao                                       #"
    echo "#                  @Repository: https://github.com/vod-ka               #"
    echo "#                                                                       #"
    echo "========================================================================="
    echo 
    echo 
    echo 
    echo "1，安装docker"
    echo "--------------------------"
    echo "2，启动docker"
    echo "--------------------------"
    echo "3，停止docker"
    echo "--------------------------"
    echo "4，重启docker"
    echo "--------------------------"
    echo "5，检测docker"
    echo "--------------------------"
    echo "6，卸载docker"
    echo "--------------------------"
    echo "0，exit"
    echo "--------------------------"
    read -p "输入数字执行: " MUN
    case "$MUN" in
        1)
        CheckVersion
        STARTMenu
        ;;
        2)
        STARTDocker
        STARTMenu
        ;;
        3)
        STOPDocker
        STARTMenu
        ;;
        4)
        RELOADDocker
        STARTMenu
        ;;
        5)
        TESTDocker
        STARTMenu
        ;;
        6)
        REMOVEDocker
        ;;
        0)
        exit 1
        ;;
    esac
}

STARTMenu
