#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-03-16 23:43:00  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-03-16 23:43:00  

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME
export PATH
Green(){
    echo -e "\033[32;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

check_user(){
    if [ $(id -u) != 0 ]
    then
        Red "请使用root用户执行脚本"
        exit 1
    fi
}

select_interface(){
    clear
    ip addr
    read -p "请输入需要修改的网卡名称(回车键继续): " IFNAME
    IFCONFIG=$(find /etc -name ifcfg-"$IFNAME")
}

from_file(){
    echo
    Red "文件的请按这格式，从上往下,第一行为ip地址，以此类推分别是：子网掩码，网关，DNS"
    echo
    read -p "请输入文件所在路径: " ipinfo
    IPADDRESS=$(sed -n '1p' "$ipinfo")
    MARK=$(sed -n '2p' "$ipinfo")
    GATE=$(sed -n '3p' "$ipinfo")
    DNSADDRESS=$(sed -n '4P' "$ipinfo")
}

from_keyboard(){
    Green "----------根据提示执行操作----------"
    read -p "请输入IP地址(回车键继续): " IPADDRESS
    read -p "请输入子网掩码(回车键继续): " MARK
    read -p "请输入网关地址(回车键继续): " GATE
    read -p "请输入DNS地址(回车键继续): " DNSADDRESS
}

set_ipaddr(){
    sed -i '/IPADDR/d' "$IFCONFIG"
    sed -i '/NETMASK/d' "$IFCONFIG"
    sed -i '/GATEWAY/d' "$IFCONFIG"
    sed -i '/DNS1/d' "$IFCONFIG"
    sed -i '/BOOTPROTO/s/dhcp/static/g' "$IFCONFIG"
    echo -e "IPADDR=$IPADDRESS\nNETMASK=$MARK\nGATEWAY=$GATE\nDNS1=$DNSADDRESS" >> "$IFCONFIG"
    clear
    cat "$IFCONFIG"
    echo
    echo
    Green "网卡已经重启，请重新连接..."
    systemctl restart network
}

start_menu(){
    clear
    check_user
    Green "#===============================================================================#"
    Green "#                                                                               #"
    Green "#          @Name: 网卡IP地址管理工具                                               #"
    Green "#          @Author: Aliao                                                       #"
    Green "#          @Repository: https://github.com/vod-ka                               #"
    Green "#                                                                               #"
    Green "#===============================================================================#"
    echo 
    echo 
    Green "1，手动输入\n----------------"
    Green "2，从文件读取\n---------------"
    Green "0，退出\n---------------"
    read -p "输入数字执行: " Number
    case $Number in
        1)
        select_interface
        from_keyboard
        set_ipaddr
        ;;
        2)
        select_interface
        from_file
        set_ipaddr
        ;;
        0)
        exit 0
        ;;
    esac
}

#Main
start_menu