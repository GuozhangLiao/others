#!/usr/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-02-21 18:54:22  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-02-21 18:54:22  
#升级kali系统和清楚旧包

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
export PATH
timer=$(date  +'%Y%m%d%H%M')
udlog="system_update_$timer.log"
logdst="/home/aliao/update_log"
kcmd="aptitude"

#颜色
Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

#检查路径是否存在
check_dst(){
    if [ -d $logdst ]
    then
        Blue "---------------\n系统更新任务进行中...\n---------------"
    else
        Blue "---------------\n日志路径不存在，现在创建...\n---------------"
        mkdir $logdst
    fi
}

#指令动作
Action (){
     echo "hjkl;'" | sudo -S $kcmd $1 -y
}

Main (){
    check_dst
    Action update
    Action safe-upgrade
    Blue "---------------\n系统升级完成\n---------------"
    Action clean

    local kcmd="apt-get"
    Action autoremove
    Blue "---------------\n所以任务完成\n---------------"
}

Main > $logdst/$udlog

