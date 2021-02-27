#!/usr/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-02-21 18:54:22  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-02-21 18:54:22  
#升级kali系统和清楚旧包

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
export PATH
timer1=$(date  +'%Y%m%d%H%M')
#timer2=$(date "+%F %T")
udlog="system_update_$timer1.log"
logdst="$HOME/update_log"
kcmd="aptitude"

#颜色
Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

#检查路径是否存在
check_dst(){
    if [ -d $logdst ]
    then
        Blue "-------------------------\n系统更新任务进行中...\n-------------------------$(date "+%F %T")"
    else
        Blue "-------------------------\n日志路径不存在，现在创建...\n-------------------------$(date "+%F %T")"
        mkdir $logdst
    fi
}

#检查网络是否连接
check_network(){
    ping -c 1 mirrors.aliyun.www > /dev/null 2>&1
    local a=$?
    ping -c 1 mirrors.tuna.tsinghua.edu.cn > /dev/null 2>&1
    local b=$?
    if [ $a -eq 0 ] || [ $b -eq 0 ] 
    then
        Blue "-------------------------\n网络连接正常，开始更新系统\n-------------------------$(date "+%F %T")"
    else
        Red "-------------------------\n设备离线，请检查网络连接是否正常!\n系统更新任务失败！\n-------------------------$(date "+%F %T")"
        exit 1
    fi
}

#指令动作
Action (){
     echo "hjkl;'" | sudo -S $kcmd $1 -y
}

Main (){
    check_network
    check_dst
    Action update
    Action safe-upgrade
    Blue "-------------------------\n系统升级完成\n-------------------------$(date "+%F %T")"
    Action clean

    local kcmd="apt-get"
    Action autoremove
    Blue "-------------------------\n所以任务完成\n-------------------------$(date "+%F %T")"
}

Main > $logdst/$udlog