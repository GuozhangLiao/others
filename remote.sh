#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-04-19 00:37:52  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-04-19 00:37:52  

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME
export PATH

Green(){
    echo -e "\033[32;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

title(){
    clear
    Green "#===============================================================================#"
    Green "#                                                                               #"
    Green "#          @Name: rdesktop远程工具                                              #"
    Green "#          @Author: Aliao                                                       #"
    Green "#          @Repository: https://github.com/vod-ka                               #"
    Green "#                                                                               #"
    Green "#===============================================================================#"
    echo 
    echo 
    Green "1,连接远程服务器\n-----------------"
    Green "2,退出\n---------------"
    read -rp "输入数字执行: " Num
    case $Num in 
        1)
        Ation
        ;;
        2)
        exit 0
        ;;
    esac
}

Ation(){
    clear
    read -rp "请输入远程服务器的IP地址： " -t 60 a
    clear
    ping -c 1 "$a" > /dev/null 2>&1
    local p=$?
    if [ $p -eq 0 ]
    then
        clear
        Green "1,用户名默认为administrator\n------------"
        Green "2,手动输入\n----------"
        read -rp "请输入数字执行： " shuzi
        case $shuzi in
            1)
            b="administrator"
            ;;
            2)
            read -rp "请输入用户名： " -t 60 b
            ;;
        esac
        clear
        read -rp "请输入密码 " -t 60 c
        clear
        Green "rdesktop远程链接中，如需断开链接请按Ctrl+C!"
        rdesktop -u "$b" -p "$c" "$a" > /dev/null 2>&1
    else
        Red "指定地址无法连接，请检查地址！"
        exit 0
    fi
}

#main
title