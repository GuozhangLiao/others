#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-04-21 20:14:36  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-04-21 20:14:36

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

#动作
Action(){
    clear
    read -rp "输入歌曲文件的路径，（例如：/mnt/DISKB/PARTITION1/）： " -t 60 st
    if [ -d "$st" ]
    then
        Green "路径 $st 可用！"
    else
        Red "路径 $st 不存在，请检查路径..."
        exit 1
    fi
    clear
    read -rp "输入你需要将歌曲拷贝到的路径，（例如：/mnt/DISKB/PARTITION1/123/）： " -t 60 dt
    clear
    if [ -d "$dt" ]
    then
        Green "路径 $dt 可用！"
    else
        Red "路径 $dt 不存在，现在尝试创建..."
        mkdir -p "$dt"
    fi
    if [ $? -eq 0 ]
    then
        Red "任务进行中请耐心等待........"
	    for line in $(cat a.txt)
	    do
	    	find "$st"/* -name "$line.*" -exec cp {} "$dt" \;
	    done
    else
        Red "创建路径 $dt 失败，请检查路径是否有误！"
        exit 1
    fi
}

#标题
Menu(){
	clear
	Green "#========================================="
    Green "#                                         "
    Green "#  @Name: 找歌脚本                         "
    Green "#  @Author: Aliao                         "
    Green "#  @Repository: https://github.com/vod-ka "
    Green "#                                         "
    Green "#========================================="
	echo
	echo
	Green "1,开始拷贝歌曲\n-----------------"
    Green "2,退出\n-----------------"
    read -rp "输入数字执行: " Num
    case $Num in 
        1)
        Ation
        clear
        Blue "任务已完成！！！！！！！！！！！！！！！！！！！！"
        ;;
        2)
        exit 0
        ;;
    esac
}

#Main
Menu